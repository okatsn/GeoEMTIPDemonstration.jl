using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Gadfly: Scale.default_discrete_colors as gadfly_colors
using Revise
using GeoEMTIPDemonstration
using Dates
df = CSV.read(dir_cwb2023mid("summary_test.csv"), DataFrame);
transform!(df, :HitRatesForecasting => ByRow(x->1-x) => :MissingRateForecasting)
dfg = groupby(df, "prp")
uniqprp = string.(unique(df.prp))
uniqcolors = gadfly_colors(length(uniqprp))
prp2index(str) = only(findall(occursin.(str, uniqprp)))
transform!(df, :prp => ByRow(prp2index) => :group1)
transform!(df, :group1 =>  ByRow(ind -> uniqcolors[ind]) => :group1_colors)


# ## group of figure (since dimension `frc` may be too large)
transform!(df,:frc => ByRow(x -> (Date(split(x, "-")[1], DateFormat("yyyymmdd"))))=> :frc_start) # the first day of forecasting phases

edges = [
    Date(0000, 1, 1),
    Date(2017, 10, 1), 
    Date(2020, 10, 1),
    Date(9999,12,31)
]

DI = DateInterval(edges)
which_interval = x -> only(findall(map(f -> f(x), [(dt -> t0 <= dt < t1) for (t0, t1) in DI])))
transform!(df,:frc_start => ByRow(which_interval) => :figure) # the first day of forecasting phases



df.frc_start |> unique


# # AlgebraOfGraphic
# ## All in one single plot

xymap = mapping(
    :AlarmedRateForecasting => identity => "alarmed rate",
    :MissingRateForecasting => identity => "missing rate",
)
molplane_scatter = data(df) * xymap

# ### colored by group *prp*:
# scatter plot 
set_aog_theme!()
axis = (width = 225, height = 225)
layer_basic = visual()
molplane_scatter * layer_basic * mapping(color = :prp) |> draw  # Noted that layer_basic can be ignored

# contour plot 
layer_contour = AlgebraOfGraphics.density() * visual(Contour)
molplane_scatter * layer_contour * mapping(color = :prp) |> draw

# contour with scatter
molp_all = molplane_scatter * (layer_contour + layer_basic) * mapping(color = :prp)
molp_all |> draw

# additional abline:
randguess = data((x = [0, 1], y = [1, 0] )) * visual(Lines; color = "red", linestyle = :dashdot) * mapping(:x, :y)
molp_all + randguess |> draw


# density 3D plot
layer_wireframe = AlgebraOfGraphics.density() * visual(Wireframe, linewidth = 0.05)
ax3d = (type = Axis3, width = 300, height = 300)
molplane_scatter * layer_wireframe * mapping(color = :prp) |> p -> draw(p; axis = ax3d)


# ## In subplots
molp_all = molplane_scatter * (layer_contour + layer_basic) * mapping(color = :prp, layout = :frc => "forecasting phase") + randguess
molp_all |> draw

set_aog_theme!()
axis_long = (width = 225, height = 225)
molp_all = molplane_scatter * (layer_contour + layer_basic) * mapping(col = :prp, row = :frc => "forecasting phase") + randguess
molp_all |> p -> draw(p; axis =axis_long)

