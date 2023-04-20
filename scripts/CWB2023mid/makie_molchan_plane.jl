using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Gadfly: Scale.default_discrete_colors as gadfly_colors
using Statistics
using Revise
import NaNMath: mean as nanmean
using Revise
using OkDataFrameTools
using GeoEMTIPDemonstration
using Dates
df_mx3 = CSV.read(dir_cwb2023mid("summary_test_mx_3yr_180d.csv"), DataFrame)|> df -> insertcols!(df, :trial => "mix",  :train_yr => 3)
df_ge3 = CSV.read(dir_cwb2023mid("summary_test_ge_3yr_180d.csv"), DataFrame) |> df -> insertcols!(df, :trial => "GE" , :train_yr => 3)
df_gm3 = CSV.read(dir_cwb2023mid("summary_test_gm_3yr_180d.csv"), DataFrame) |> df -> insertcols!(df, :trial => "GM" , :train_yr => 3)
df_mx7 = CSV.read(dir_cwb2023mid("summary_test_mx_7yr_180d.csv"), DataFrame)|> df -> insertcols!(df, :trial => "mix",  :train_yr => 7)
df_ge7 = CSV.read(dir_cwb2023mid("summary_test_ge_7yr_180d.csv"), DataFrame) |> df -> insertcols!(df, :trial => "GE" , :train_yr => 7)
df_gm7 = CSV.read(dir_cwb2023mid("summary_test_gm_7yr_180d.csv"), DataFrame) |> df -> insertcols!(df, :trial => "GM" , :train_yr => 7)
df = vcat(
    df_mx3, df_ge3, df_gm3, 
    df_mx7, df_ge7, df_gm7)

P = prep202304!(df)
@assert isequal(P.table, df)


# # Fitting Degree

# Colors:
# uniqcolors_prp = gadfly_colors(length(P.uniqprp))
uniqcolors_frc = cgrad(:Spectral, length(P.uniqfrc), categorical = true)
# uniqcolors_frc = gadfly_colors(length(P.uniqfrc))

stryear(x) = "$x years"
repus(x) = replace(x, "_" => "-")

dfcb = combine(groupby(df, [:prp, :frc_ind, :trial, :train_yr]), :FittingDegree => nanmean => :FittingDegreeMOM, nrow)
dropnanmissing!(dfcb)

f1 = Figure(; resolution = (800, 800))
pl_plots =  f1[1, 1] = GridLayout()
pl_legend = f1[1, 2] = GridLayout()
colsize!(f1.layout, 1, Relative(3/4))
plt = data(dfcb) * # data
    mapping(col = :trial, row = :train_yr => stryear) * # WARN: it is not allowed to have integer grouping keys.
    (
        visual(BarPlot, colormap = uniqcolors_frc) * 
        mapping(:prp => repus => "Filter", :FittingDegreeMOM => "Fitting degree (avg. over models)", 
                stack = :frc_ind, 
                color = :frc_ind => "Forecasting phase")
    )
draw!(pl_plots[:, :], plt; axis = (xticklabelrotation = 0.2π, ))
Legend(pl_legend[:, :], 
    [PolyElement(polycolor = color) for color in uniqcolors_frc], 
    P.uniqfrc,
    "Forecasting phase",
    labelsize = 14,
    tellheight = false, tellwidth = false)
f1



f2 = Figure()
dfcb2 = combine(groupby(df, [:prp, :trial, :train_yr]), :FittingDegree => nanmean => :FittingDegreeMOT)
dropnanmissing!(dfcb2)
content2 = data(dfcb2) * 
    (
        visual(BarPlot, colormap = uniqcolors_frc) * 
        mapping(:prp => repus => "Filter", :FittingDegreeMOT => "Fitting degree (avg. over trials)")
    ) *
    mapping(col = :trial, row = :train_yr => stryear)
draw!(f2, content2; axis = (xticklabelrotation = 0.2π, ))
f2



# ## Distribution of fitting degree
dfn = deepcopy(df);
dropnanmissing!(dfn)
f3 = Figure()
histogram_all = data(dfn) * visual(Hist, bins = 15) * mapping(:FittingDegree) * mapping(row = :train_yr => stryear, col = :trial)
draw!(f3, histogram_all)


data(viewgroup(dfn; trial = "GE", train_yr = 3)) * mapping(:FittingDegree)* visual(Hist, bins = 15) |> draw


# # Molchan diagram
# Keys for AOG:
# - [How to combine AlgebraOfGraphics with plain Makie plots?](https://aog.makie.org/stable/FAQs/#How-to-combine-AlgebraOfGraphics-with-plain-Makie-plots?)

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

df = groupby(df, :trial)[(trial = "mix", )]# FIXME

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


# plot_elements = visual(Scatter, color = uniqcolors_prp[1]) +  AlgebraOfGraphics.density() * visual(Contour, levels = 5, colormap = :dense)
plot_elements = [
    AlgebraOfGraphics.density(npoints = 50) * visual(colormap = :grayC),
    visual(Scatter, color = (uniqcolors_prp[3], 1), markersize = 3), 
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