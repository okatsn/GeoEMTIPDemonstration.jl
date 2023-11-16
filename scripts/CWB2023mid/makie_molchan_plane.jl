using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
using Printf
import NaNMath: mean as nanmean
# using Revise # using Revise through VSCode settings
using CWBProjectSummaryDatasets
using OkMakieToolkits
using OkDataFrameTools
using CWBProjectSummaryDatasets
using GeoEMTIPDemonstration
using MolchanCB
using Dates
df_mx3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTest_MIX_3yr_180d_500md_2023A10") |> df -> insertcols!(df, :trial => "mix", :train_yr => 3)
df_ge3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTest_GE_3yr_180d_500md_2023A10") |> df -> insertcols!(df, :trial => "GE", :train_yr => 3)
df_gm3 = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTest_GM_3yr_180d_500md_2023A10") |> df -> insertcols!(df, :trial => "GM", :train_yr => 3)

df = vcat(
    df_mx3, df_ge3, df_gm3)
# `dropnanmissing!` is required to avoid contour plot error
# TODO: consider deprecate `dropnanmissing!` in `figureplot`


uniqNEQ = df[!, r"NEQ"] |> Matrix |> vec |> unique

# # A dictionary function for efficiently obtain Molchan confidence boundary.

DCB = Dict([α => Dict([neq => molchancb(big(neq), α) for neq in uniqNEQ]) for α in [0.05, 0.1, 0.33]])

getalms(α, neq) = DCB[α][neq]




# TODO: consider move these functions out
uniqueonly(x) = x |> unique |> only

function getdcb(α, neq)
    (alarmed, missed) = getalms(α, neq) # fitting degree
    fdcb = 1 .- alarmed .- missed
end

transform!(df,
    :NEQ_min => ByRow(n -> maximum(getdcb(0.1, n); init=-Inf)) => :DCB_high,
    :NEQ_max => ByRow(n -> maximum(getdcb(0.1, n); init=-Inf)) => :DCB_low,
    # init = -Inf is required since the result of getdcb (from molchancb) might be an empty vector.
) # KEYNOTE: It will be super slow (due to large N involved in factorial calculations) if directly uses NEQ_max => ByRow(molchancb).

# # Convert -Inf to NaN
# Is literal infinite
islinf(x::AbstractFloat) = isinf(x)
islinf(x) = false

df = ifelse.(islinf.(df), NaN, df)

dropnanmissing!(df)


P = prep202304!(df)
transform!(P.table, [:frc, :frc_ind] => ByRow((x, y) -> @sprintf("(%.2d) %s", y, x)) => :frc_ind_frc)
# Colors:

CF23 = ColorsFigure23(P)
@assert isequal(P.table, df)



tablegpbytrainyr = groupby(P.table, :train_yr)
uniqfrc_3yr = tablegpbytrainyr[(train_yr=3,)].frc |> unique

# KEYNOTE: This is no longer working after updating CairoMakie
# TTP3yr = TrainTestPartition23a(uniqfrc_3yr, 3)
# (ax0a, f0a) = figureplot(TTP3yr; resolution=(800, 600))
# Makie.save("Train_Test_Partitions_3years.png", f0a)



# # Fitting Degree
stryear(x) = "$x years"
repus(x) = replace(x, "_" => "-")
xlabel2 = L"\text{Filter}"
ylabel2 = L"D_c  \text{(averaged over trials)}"

dfcb = combine(groupby(df, [:frc_ind, :prp, :trial]), :FittingDegree => nanmean => :FittingDegreeMOM, :DCB_low => uniqueonly, :DCB_high => uniqueonly, nrow; renamecols=false)
dropnanmissing!(dfcb)

insertcols!(dfcb, :DCB_top => 1.0)
insertcols!(dfcb, :DCB_bottom => -1.0)

function label_DcHist!(f2;
    left_label="number of models",
    right_label="variable",
    top_label="joint-station set",
    bottom_label="variable value"
)
    common_setting = (fontsize=20, font="Arial bold")
    Label(f2[:, end+1], right_label; rotation=-π / 2, tellwidth=true, tellheight=false, common_setting...)
    Label(f2[:, 0], left_label; rotation=+π / 2, tellwidth=true, tellheight=false, common_setting...)
    Label(f2[0, :], top_label; rotation=0, tellwidth=false, tellheight=true, common_setting...)
    Label(f2[end+1, :], bottom_label; rotation=0, tellwidth=false, tellheight=true, common_setting...)
end
dcmeanstyle = (color=:red, linestyle=:solid)
dcmedstyle = (color=:firebrick1, linestyle=:dash)

f1 = Figure(; resolution=(800, 1000))
pl_plots = f1[1, 1] = GridLayout()
pl_legend = f1[1, 2] = GridLayout()

colsize!(f1.layout, 1, Relative(3 / 4))
rainbowbars = visual(BarPlot, colormap=CF23.frc.colormap, strokewidth=0.5, gap=0.5) *
              mapping(color=:frc_ind) *
              mapping(:frc_ind,
                  :FittingDegreeMOM => identity => ylabel2) # WARN: it is not allowed to have integer grouping keys.
dfcb_mean = combine(groupby(dfcb, [:prp, :trial]), :FittingDegreeMOM => mean)
hlineofmean = data(dfcb_mean) * visual(HLines; dcmeanstyle...) * mapping(:FittingDegreeMOM_mean) # TODO: modify matlab code to export TIPTrueArea, TIPAllArea, EQKMissingNumber and EQKAllNumber for calculating overall fitting degree with 1 - sum(TIMTrueArea)/sum(TIPAllArea) - sum(EQKMissingNumber/EQKAllNumber) ???


clevel1 = visual(Band; alpha=0.5, color=:gray69) * (mapping(:frc_ind, :DCB_bottom, :DCB_low) + mapping(:frc_ind, :DCB_bottom, :DCB_high))
clevel2 = visual(ScatterLines; color=:black, linewidth=0.3, markersize=3) * (mapping(:frc_ind, :DCB_low) + mapping(:frc_ind, :DCB_high))


plt = (data(dfcb) * (clevel + rainbowbars + clevel2) + hlineofmean) * mapping(col=:trial, row=:prp)
draw!(pl_plots, plt; axis=(; xticklabelrotation=0.2π, limits=(nothing, Tuple(extrema((vcat(dfcb.FittingDegreeMOM, dfcb.DCB_low, dfcb.DCB_high))) .+ [-0.05, +0.05]))))
label_DcHist!(pl_plots; left_label="fitting degree", right_label="", bottom_label="Forecasting Phase")

Legend(pl_legend[:, :],
    [PolyElement(polycolor=color) for color in CF23.frc.colormap],
    P.uniqfrc,
    "Forecasting phase",
    labelsize=14,
    tellheight=false, tellwidth=true, halign=:left, valign=:top)
Legend(pl_legend[0, end],
    [[LineElement(; dcmeanstyle...)]],
    ["overall average"];
    valign=:bottom, tellheight=true
)
f1
Makie.save("FittingDegree_barplot_colored_by=frc.png", f1)

f2 = Figure(; resolution=(800, 550))
dfcb2 = combine(groupby(df, [:prp, :trial]), :FittingDegree => nanmean => :FittingDegreeMOT)
dropnanmissing!(dfcb2)
content2 = data(dfcb2) *
           (
               visual(BarPlot) *
               mapping(:prp => repus => xlabel2, :FittingDegreeMOT => ylabel2)
           ) *
           mapping(col=:trial)
draw!(f2, content2; axis=(xticklabelrotation=0.2π,))
label_DcHist!(f2; left_label="fitting degree", right_label="", bottom_label="")
f2
Makie.save("FittingDegree_barplot_mono_color_with=nanmean.png", f2)



f2a = Figure(; resolution=(550, 450))
dfcb2a = combine(groupby(df, [:prp, :trial]), :FittingDegree => nanmean => :FittingDegreeMOT)
dropnanmissing!(dfcb2a)
content2 = data(dfcb2a) *
           visual(BarPlot) *
           mapping(:trial => "joint-station set", :FittingDegreeMOT => ylabel2)
draw!(f2a, content2; axis=(xticklabelrotation=0.2π,))
f2a
Makie.save("FittingDegree_barplot_mono_color_with=nanmean_only_ULF-B.png", f2a)





# CHECKPOINT:
# - Write docstring in OkMakieToolkits
# - Have a train-test phase plot
# https://juliadatascience.io/recipe_df
# ## Distribution of fitting degree


legend_f3!(f3) = Legend(f3[0, end],
    [[LineElement(; dcmeanstyle...)], [LineElement(; dcmedstyle...)]],
    ["mean", "median"];
    valign=:top
)

# SETME:
f3histkwargs = (bins=-1.05:0.05:1.05,)
f3histkwargs_a = (bins=-0.05:0.05:1.05,)

# Figure 3:
f3 = Figure(; resolution=(800, 900))
dfn = deepcopy(df);
dropnanmissing!(dfn)
dcmm = combine(groupby(dfn, [:trial, :prp]),
    :FittingDegree => mean => "DC_mean",
    :FittingDegree => median => "DC_median")

dchist = data(dfn) * visual(Hist; f3histkwargs...) * mapping(:FittingDegree)


dcmean = data(dcmm) * visual(VLines; ymin=0, dcmeanstyle...) * mapping(:DC_mean => "mean")
dcmedian = data(dcmm) * visual(VLines; ymin=0, dcmedstyle...) * mapping(:DC_median => "median")

histogram_all = (dchist + dcmean + dcmedian) * mapping(col=:trial, row=:prp)

f3p = draw!(f3, histogram_all)
label_DcHist!(f3; right_label="", bottom_label=L"\text{Fitting Degree } D_C")
# legend!(f3[0, end], f3p; valign = :top) # Nothing happend!
legend_f3!(f3)
f3
Makie.save("FittingDegree_hist_overall_mono_color.png", f3)

# Figure 3a:
f3a = Figure(; resolution=(1000, 700))
raincloudkwargs = (plot_boxplots=true, orientation=:vertical,
    cloud_width=0.85,
    clouds=hist,
    markersize=1, jitter_width=0.02, # scatter plot settings
    boxplot_width=0.12, # boxplot settings
    gap=0, # gap between prp
)

df3a = stack(dfn, [:MissingRateForecasting, :AlarmedRateForecasting], [:trial, :prp])
df3acb = combine(groupby(df3a, [:trial, :prp, :variable]),
    :value => mean,
    :value => median)

hist3a = data(df3a) * visual(RainClouds; raincloudkwargs...) * mapping(:prp => :Filter, :value) * mapping(color=:prp)
# mean3a = data(df3acb) * visual(VLines; ymin=0, dcmeanstyle...) * mapping(:value_mean => "mean value")
# median3a = data(df3acb) * visual(VLines; ymin=0, dcmedstyle...) * mapping(:value_median => "median value")

histcomb_f3a = (hist3a) * mapping(row=:variable, col=:trial)
# histcomb_f3a = (hist3a + mean3a + median3a) * mapping(row=:variable, col=:trial)
f3ap = draw!(f3a, histcomb_f3a, palettes=(; color=CF23.prp.to_color.(1:4)))
label_DcHist!(f3a; right_label="variable", left_label="", bottom_label="probability density")
# legend_f3!(f3a)
f3a
Makie.save("MissingRateAlarmedRate_rainclouds_over_prp_trial.png", f3a)



# KEYNOTE:
# - AlgebraOfGraphics.histogram() * mapping results in `Combined{barplot}`
# - `mapping(:FittingDegree, color=:frc_color , stack=:frc_ind) *` causes error
# - `mapping(:FittingDegree, color=:frc_ind , stack=:frc_ind) *` causes error
# - `visual(Hist) *` with `stack = ` argument failed since Hist of Makie cannot be stacked
# - I cannot assign colormap, that I have to make CF23.prp.color the default Makie color
# - The default Makie color is Makie.wong_colors(), which has a length of 7; if the number of categories is larger than 7, you will see duplicated color patches.

xylimits = (-0.05, 1.05)

function fig5_molchan_by_prp(aog_layer::AlgebraOfGraphics.AbstractAlgebraic, target_file)
    f50res = (resolution=(800, 700),)
    f5sckwargs = (titlesize=13, aspect=1, xticklabelrotation=0.2π)
    f5 = Figure(; f50res...)

    set_aog_pallete!(CF23.trial) # The colors for the Figure 5 series
    plt5 = draw!(f5[1, 1], aog_layer; axis=(f5sckwargs..., limits=(xylimits, xylimits)))
    AlgebraOfGraphics.legend!(f5[1, 2], plt5)
    Makie.save(target_file, f5)
    return f5
end

# additional abline
randlinekwargs = (color="red", linestyle=:dashdot)
randguess = data((x=[0, 1], y=[1, 0])) * visual(Lines; randlinekwargs...) * mapping(:x => "alarmed rate", :y => "missing rate")

xymap = mapping(
    :AlarmedRateForecasting => identity => "alarmed rate",
    :MissingRateForecasting => identity => "missing rate",
)

visual_contour = AlgebraOfGraphics.density() * visual(Contour, levels=7, linewidth=1, alpha=0.8, labels=false)
visual_scatter = visual(Scatter, markersize=5, alpha=0.3)


molchan_all_frc = data(P.table) *
                  mapping(marker=:trial, color=:trial) *
                  mapping(layout=:prp => "filter") *
                  xymap

f5c = fig5_molchan_by_prp(molchan_all_frc * visual_contour + randguess, "MolchanDiagram_Contour_color=trial_layout=prp.png")
f5s = fig5_molchan_by_prp(molchan_all_frc * visual_scatter + randguess, "MolchanDiagram_Scatter_color=trial_layout=prp.png")


f5res = (resolution=(800, 700),)
f5abkwargs = (titlesize=11, aspect=1, xticklabelrotation=0.2π)
densitykwargs = (alpha=0.6, bins=-0.05:0.04:1.05, bandwidth=0.01, boundary=(-0.1, 1.1))

ratedensity = data(P.table) * visual(Density; densitykwargs...) * mapping(color=:trial) * mapping(layout=:frc_ind_frc)
f5a = draw(ratedensity * mapping(:AlarmedRateForecasting); axis=(f5abkwargs..., limits=(xylimits, (nothing, nothing)), xlabel="alarmed rate", ylabel="pdf"), figure=f5res)
Makie.save("MolchanDiagram_AlarmedRate_color=trial_layout=frc.png", f5a)

# AlgebraOfGraphics.legend!(f5[1,2], plt5a) # KEYNOTE: auto legend failed again

f5b = draw(ratedensity * mapping(:MissingRateForecasting); axis=(f5abkwargs..., limits=(xylimits, (nothing, nothing)), xlabel="missing rate", ylabel="pdf"), figure=f5res)
Makie.save("MolchanDiagram_MissingRate_color=trial_layout=frc.png", f5b)

# KEYNOTE:
# - When scatter points concentrates at one or a few values, RainClouds are ugly, and Density & Density-related (e.g., Violin) goes wrong and misleading.
# - I found no way to set AlgebraOfGraphics.histogram or .density to plot horizontally (the :direction argument for Hist and Density).
# - it is not necessary to have pdf <= 1; it requires only integral over the entire area to be 1.
# `AlgebraOfGraphic.density` use `KernelDensity.kde((df.AlarmedRateForecasting, df.MissingRateForecasting))`


# dfa = groupby(P.table, :trial)[(trial = "GM", )]

# dfan = dropnanmissing!(DataFrame(deepcopy(dfa)))

# be = KernelDensity.kde((dfan.AlarmedRateForecasting, dfan.MissingRateForecasting))
# # Molchan diagram
# Keys for AOG:
# - [How to combine AlgebraOfGraphics with plain Makie plots?](https://aog.makie.org/stable/FAQs/#How-to-combine-AlgebraOfGraphics-with-plain-Makie-plots?)
