using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
import NaNMath: mean as nanmean
using Revise
using OkMakieToolkits
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
# Colors:
uniqcolors_frc = CairoMakie.cgrad(:tab20, length(P.uniqfrc), categorical = true)
to_frccolor(i) = uniqcolors_frc[i]

transform!(df, :frc_ind => ByRow(to_frccolor) => :frc_color) # :frc_color is intended to solve the problem in stacking histogram (not stacking barplots; they are fine). However, mapping :frc_color to AlgebraOfGraphics.histogram (which somehow allows stacked histogram) failed.

@assert isequal(P.table, df)



tablegpbytrainyr = groupby(P.table, :train_yr)
uniqfrc_7yr = tablegpbytrainyr[(train_yr = 7, )].frc |> unique 
uniqfrc_3yr = tablegpbytrainyr[(train_yr = 3, )].frc |> unique 

TTP7yr = TrainTestPartition23a(uniqfrc_7yr, 7)
TTP3yr = TrainTestPartition23a(uniqfrc_3yr, 3)
(ax0a, f0a) = figureplot(TTP3yr; resolution = (800, 600))
(ax0b, f0b) = figureplot(TTP7yr; resolution = (800, 400))
Makie.save("Train_Test_Partitions_3years.png", f0a)
Makie.save("Train_Test_Partitions_7years.png", f0b)



# # Fitting Degree
stryear(x) = "$x years"
repus(x) = replace(x, "_" => "-")
xlabel2 = L"\text{Filter}"
ylabel2 = L"D_c  \text{(averaged over trials)}"

dfcb = combine(groupby(df, [:prp, :frc_ind, :trial, :train_yr]), :FittingDegree => nanmean => :FittingDegreeMOM, nrow)
dropnanmissing!(dfcb)


function label_DcPrp!(f2)
    common_setting = (fontsize = 20, font = "Arial bold")
    Label(f2[:, end+1], "training window length"; rotation = -π/2, tellwidth = true, tellheight = false, common_setting...)
    Label(f2[:, 0],     "fitting degree"        ; rotation = +π/2, tellwidth = true, tellheight = false, common_setting...)
    Label(f2[0, :],     "with stations"         ; rotation =    0, tellwidth = false, tellheight = true, common_setting...)
end

f1 = Figure(; resolution = (800, 800))
pl_plots =  f1[1, 1] = GridLayout()
pl_legend = f1[1, 2] = GridLayout()
colsize!(f1.layout, 1, Relative(3/4))
plt = data(dfcb) * # data
    (
        visual(BarPlot, colormap = uniqcolors_frc) * 
        mapping(:prp => repus => xlabel2, :FittingDegreeMOM => ylabel2, 
                stack = :frc_ind, 
                color = :frc_ind => "Trial (Forecasting phase)") * 
    mapping(col = :trial, row = :train_yr => stryear) # WARN: it is not allowed to have integer grouping keys.
    )
draw!(pl_plots, plt; axis = (xticklabelrotation = 0.2π, ))
label_DcPrp!(pl_plots)
Legend(pl_legend[:, :], 
    [PolyElement(polycolor = color) for color in uniqcolors_frc], 
    P.uniqfrc,
    "Forecasting phase",
    labelsize = 14,
    tellheight = false, tellwidth = true, halign = :left, valign = :center)
f1

Makie.save("FittingDegree_by=frcphase_layout=2x2.png", f1)

f2 = Figure()
dfcb2 = combine(groupby(df, [:prp, :trial, :train_yr]), :FittingDegree => nanmean => :FittingDegreeMOT)
dropnanmissing!(dfcb2)
content2 = data(dfcb2) * 
    (
        visual(BarPlot, colormap = uniqcolors_frc) * 
        mapping(:prp => repus => xlabel2, :FittingDegreeMOT => ylabel2)
    ) *
    mapping(col = :trial, row = :train_yr => stryear)
draw!(f2, content2; axis = (xticklabelrotation = 0.2π, ))
label_DcPrp!(f2)
f2
Makie.save("FittingDegree_with=nanmean_layout=2x2.png", f2)

# CHECKPOINT: 
# - Write docstring in OkMakieToolkits
# - Have a train-test phase plot
# https://juliadatascience.io/recipe_df
# ## Distribution of fitting degree
function label_DcHist!(f2)
    common_setting = (fontsize = 20, font = "Arial bold")
    Label(f2[:, end+1], "training window length"; rotation = -π/2, tellwidth = true, tellheight = false, common_setting...)
    Label(f2[:, 0],     "number of models"      ; rotation = +π/2, tellwidth = true, tellheight = false, common_setting...)
    Label(f2[0, :],     "with stations"         ; rotation =    0, tellwidth = false, tellheight = true, common_setting...)
end


dfn = deepcopy(df);
dropnanmissing!(dfn)
f3 = Figure()
histogram_all = data(dfn) * visual(Hist, bins = 15) * mapping(:FittingDegree) * mapping(row = :train_yr => stryear, col = :trial)
draw!(f3, histogram_all)
label_DcHist!(f3)
f3
Makie.save("FittingDegree_hist_overall.png", f3)


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