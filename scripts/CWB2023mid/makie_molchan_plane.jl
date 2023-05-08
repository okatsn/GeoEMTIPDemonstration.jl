using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
import NaNMath: mean as nanmean
using Revise
using CWBProjectSummaryDatasets
using OkMakieToolkits
using OkDataFrameTools
using GeoEMTIPDemonstration
using Dates
df_mx3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation_23a", "MIX_3yr_180d_500md") |> df -> insertcols!(df, :trial => "mix",  :train_yr => 3)
df_ge3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation_23a", "GE_3yr_180d_500md")  |> df -> insertcols!(df, :trial => "GE" , :train_yr => 3)
df_gm3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation_23a", "GM_3yr_180d_500md")  |> df -> insertcols!(df, :trial => "GM" , :train_yr => 3)

df = vcat(
    # df_mx7, df_ge7, df_gm7,
    df_mx3, df_ge3, df_gm3)

P = prep202304!(df)
# Colors:

CF23 = ColorsFigure23(P; frccolor = :jet, prpcolor = Makie.wong_colors()) 
# , prpcolor = :Set1_4

@assert isequal(P.table, df)



tablegpbytrainyr = groupby(P.table, :train_yr)
uniqfrc_3yr = tablegpbytrainyr[(train_yr = 3, )].frc |> unique 

TTP3yr = TrainTestPartition23a(uniqfrc_3yr, 3)
(ax0a, f0a) = figureplot(TTP3yr; resolution = (800, 600))
Makie.save("Train_Test_Partitions_3years.png", f0a)



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
        visual(BarPlot, colormap = CF23.frc.colormap) * 
        mapping(:prp => repus => xlabel2, :FittingDegreeMOM => ylabel2, 
                stack = :frc_ind, 
                color = :frc_ind => "Trial (Forecasting phase)") * 
    mapping(col = :trial, row = :train_yr => stryear) # WARN: it is not allowed to have integer grouping keys.
    )
draw!(pl_plots, plt; axis = (xticklabelrotation = 0.2π, ))
label_DcPrp!(pl_plots)
Legend(pl_legend[:, :], 
    [PolyElement(polycolor = color) for color in  CF23.frc.colormap], 
    P.uniqfrc,
    "Forecasting phase",
    labelsize = 14,
    tellheight = false, tellwidth = true, halign = :left, valign = :center)
f1

Makie.save("FittingDegree_by=frcphase_layout=2x2.png", f1)

f2 = Figure(; resolution = (800, 550))
dfcb2 = combine(groupby(df, [:prp, :trial, :train_yr]), :FittingDegree => nanmean => :FittingDegreeMOT)
dropnanmissing!(dfcb2)
content2 = data(dfcb2) * 
    (
        visual(BarPlot, colormap =  CF23.frc.colormap) * 
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
f3 = Figure(; resolution = (800, 550))
histogram_all = data(dfn) * visual(Hist, bins = 15) * mapping(:FittingDegree) * mapping(row = :train_yr => stryear, col = :trial)
draw!(f3, histogram_all)
label_DcHist!(f3)
f3
Makie.save("FittingDegree_hist_overall.png", f3)



f4 = Figure(;resolution= (800, 550))
histogram_4 = data(dfn) * 
    histogram(bins = 10) * 
    mapping(:FittingDegree, color=:prp => "Filter" , stack=:prp) * 
    mapping(row = :train_yr => stryear, col = :trial)
hehe = draw!(f4, histogram_4) 
label_DcHist!(f4)
legend!(f4[0, end], hehe; valign = :top) # ;orientation = :horizontal, tellwidth = false
f4 
Makie.save("FittingDegree_hist_by_frc.png", f4)
# KEYNOTE:
# - AlgebraOfGraphics.histogram() * mapping results in `Combined{barplot}`
# - `mapping(:FittingDegree, color=:frc_color , stack=:frc_ind) *` causes error
# - `mapping(:FittingDegree, color=:frc_ind , stack=:frc_ind) *` causes error
# - `visual(Hist) *` with `stack = ` argument failed since Hist of Makie cannot be stacked
# - I cannot assign colormap, that I have to make CF23.prp.color the default Makie color
# - The default Makie color is Makie.wong_colors(), which has a length of 7; if the number of categories is larger than 7, you will see duplicated color patches.





# # Molchan Diagram
# ## All in one single plot
MolchanComposite23a(P, "mix", 3, CF23) |> figureplot |> f -> Makie.save("MolchanDiagram_all_3yr_mix.png", f)
MolchanComposite23a(P, "GE" , 3, CF23) |> figureplot |> f -> Makie.save("MolchanDiagram_all_3yr_GE.png", f)
MolchanComposite23a(P, "GM" , 3, CF23) |> figureplot |> f -> Makie.save("MolchanDiagram_all_3yr_GM.png", f)

# KEYNOTE:
# - it is not necessary to have pdf <= 1; it requires only integral over the entire area to be 1.
# `AlgebraOfGraphic.density` use `KernelDensity.kde((df.AlarmedRateForecasting, df.MissingRateForecasting))`


# dfa = groupby(P.table, :trial)[(trial = "GM", )]
    
# dfan = dropnanmissing!(DataFrame(deepcopy(dfa)))

# be = KernelDensity.kde((dfan.AlarmedRateForecasting, dfan.MissingRateForecasting))
# # Molchan diagram
# Keys for AOG:
# - [How to combine AlgebraOfGraphics with plain Makie plots?](https://aog.makie.org/stable/FAQs/#How-to-combine-AlgebraOfGraphics-with-plain-Makie-plots?)
