using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Gadfly: Scale.default_discrete_colors as gadfly_colors
using Statistics
using Revise
using GeoEMTIPDemonstration
using Dates
df = CSV.read(dir_cwb2023mid("summary_test.csv"), DataFrame);
transform!(df, :HitRatesForecasting => ByRow(x->1-x) => :MissingRateForecasting)
transform!(df, [:MissingRateForecasting, :AlarmedRateForecasting] => ByRow((x, y) -> 1-x-y) => :FittingDegree)
dfg = groupby(df, "prp")
uniqprp = string.(unique(df.prp))
uniqfrc = string.(unique(df.frc))
uniqcolors = gadfly_colors(length(uniqprp))
uniqcolors2 = gadfly_colors(length(uniqfrc))
toindex(str, uniqlabels) = only(findall(occursin.(str, uniqlabels)))
transform!(df, :prp => ByRow(x -> toindex(x, uniqprp)) => :prp_ind)
transform!(df, :frc => ByRow(x -> toindex(x, uniqfrc)) => :frc_ind)
transform!(df, :prp_ind =>  ByRow(ind -> uniqcolors[ind]) => :group1_colors)


# # Fitting Degree
dfcb = combine(groupby(df, [:prp_ind, :frc_ind]), :FittingDegree => sum, nrow; renamecols = false)
fd_norm_str = "Fitting Degree (normalized over jointstation models)"
transform!(dfcb, [:FittingDegree, :nrow] => ByRow((x, y) -> x / y) => fd_norm_str)
fbar = Figure(; resolution=(600, 500))

ticklabel_prp(i) = uniqprp[i]
axbar = Axis(fbar[1, 2])
axbar2 = Axis(fbar[2, 2])
barplot!(axbar, dfcb.prp_ind, dfcb[!, fd_norm_str]; 
    stack = dfcb.frc_ind, 
    color = uniqcolors2[dfcb.frc_ind], 
    )
dfcb2 = combine(groupby(dfcb, :prp_ind), fd_norm_str => sum; renamecols = false)
barplot!(axbar2, dfcb2.prp_ind, dfcb2[!, fd_norm_str]; 
    color = :black, 
    )
axbar2.xticks[] = (collect(eachindex(uniqprp)), uniqprp)
Label(fbar[:, 1], fd_norm_str, tellheight = false, rotation = π/2, fontsize =15)
Legend(fbar[:, 3], 
    [PolyElement(polycolor = uniqcolors2[i]) for i in eachindex(uniqcolors2)], 
    uniqfrc,
    "Forecasting phase",
    tellheight = false, tellwidth = false
)
fbar

# # Molchan diagram
# ## group of figure (since dimension `frc` may be too large)
insertcols!(df, :figure => missing)
maxrowperfig = 6 # max rows per figure

nr = 1
figid = 1
for dfg in groupby(df, :frc)
    if nr > maxrowperfig
        figid = figid + 1
        nr = 1
    end
    dfg.figure .= figid
    nr = nr + 1
end

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
randguess = data((x = [0, 1], y = [1, 0] )) * visual(Lines; color = "red", linestyle = :dashdot) * mapping(:x => "alarmed rate", :y => "missing rate")
molp_all + randguess |> draw


# density 3D plot
layer_wireframe = AlgebraOfGraphics.density() * visual(Wireframe, linewidth = 0.05)
ax3d = (type = Axis3, width = 300, height = 300)
molplane_scatter * layer_wireframe * mapping(color = :prp) |> p -> draw(p; axis = ax3d)


# ## In subplots
molp_all = molplane_scatter * layer_basic * mapping(color = :prp, layout = :frc => "forecasting phase") + randguess
molp_all |> draw

molp_all = molplane_scatter * (layer_contour + layer_basic) * mapping(col = :prp, row = :frc => "forecasting phase") + randguess
molp_all |> p -> draw(p; axis = (width = 225, height = 225))


# plot_elements = visual(Scatter, color = uniqcolors[1]) +  AlgebraOfGraphics.density() * visual(Contour, levels = 5, colormap = :dense)
plot_elements = [
    AlgebraOfGraphics.density(npoints = 50) * visual(colormap = :grayC),
    visual(Scatter, color = (uniqcolors[3], 1), markersize = 3), 
]
figs_data = [data(dfg) for dfg in groupby(df, :figure)]
figs = figs_data .* 
        Ref(xymap) .*
        Ref(reduce(+, plot_elements)) .* 
        Ref(mapping(col = :prp, row = :frc => "forecasting phase")) .+ 
        Ref(randguess) .|> 
        Ref(x -> draw(x; axis = (width = 150, height = 140, limits = (0, 1 ,0 ,1)))) 

figs[1]
figs[2]
figs[3]




tbl = (x = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )

barplot(tbl.x, tbl.height,
        stack = tbl.grp[1:8],
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        )