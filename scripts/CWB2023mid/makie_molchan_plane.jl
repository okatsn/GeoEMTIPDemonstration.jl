using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Gadfly: Scale.default_discrete_colors as gadfly_colors
using Revise
using GeoEMTIPDemonstration
df = CSV.read(dir_cwb2023mid("summary_test.csv"), DataFrame);
transform!(df, :HitRatesForecasting => ByRow(x->1-x) => :MissingRateForecasting)
dfg = groupby(df, "prp")
uniqprp = string.(unique(df.prp))
uniqcolors = gadfly_colors(length(uniqprp))
prp2index(str) = only(findall(occursin.(str, uniqprp)))
transform!(df, :prp => ByRow(prp2index) => :group1)
transform!(df, :group1 =>  ByRow(ind -> uniqcolors[ind]) => :group1_colors)


# # AlgebraOfGraphic
# ## All in one

xymap = mapping(
    :AlarmedRateForecasting => identity => "alarmed rate",
    :MissingRateForecasting => identity => "missing rate",
)
molplane_scatter = data(df) * xymap

# ### colored by group *prp*:
# scatter plot 
set_aog_theme!()
axis = (width = 225, height = 225)
molplane_scatter * mapping(color = :prp) |> draw

# contour plot 
layer_contour = AlgebraOfGraphics.density() * visual(Contour)
molplane_scatter * layer_contour * mapping(color = :prp) |> draw

# density 3D plot
layer_wireframe = AlgebraOfGraphics.density() * visual(Wireframe, linewidth = 0.05)
ax3d = (type = Axis3, width = 300, height = 300)
molplane_scatter * layer_wireframe * mapping(color = :prp) |> p -> draw(p; axis = ax3d)

