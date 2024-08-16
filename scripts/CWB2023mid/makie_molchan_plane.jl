# https://juliadatascience.io/recipe_df
using Chain
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


# NEQ summary table
dfneq = @chain df begin
    groupby([:prp, :trial, :frc])
    combine(Cols(r"NEQ") .=> (x -> only(unique(extrema(x)))); renamecols=false)
    groupby([:frc, :trial])
    combine([:NEQ_min, :NEQ_max] => ((a, b) -> extrema(vcat(a, b))) => :NEQ_range)
    unstack(:frc, :trial, :NEQ_range)
end

# SETME: Parameter settings:
whichalpha = 0.32

# # A dictionary function for efficiently obtain Molchan confidence boundary.
# `molchancb(N, alpha)` for N > 20 is slow (julia is slow in handling BigInt).
# As a result, it is necessary to build a dictionary function for all possible NEQ to avoid
# repeated calculation.
uniqNEQ = df[!, r"NEQ"] |> Matrix |> vec |> unique

DCB = Dict([α => Dict([neq => molchancb(big(neq), α) for neq in uniqNEQ]) for α in [0.05, 0.1, 0.32]])

getalms(α, neq) = DCB[α][neq]

uniqueonly(x) = x |> unique |> only

function getdcb(α, neq)
    (alarmed, missed) = try
        (alarmed, missed) = getalms(α, neq) # fitting degree
    catch
        (alarmed, missed) = molchancb(neq, α)
    end
    fdcb = 1.0 .- alarmed .- missed
end

fdperc = "$(Int(round((1-whichalpha) * 100)))%"

transform!(df,
    :NEQ_min => ByRow(n -> maximum(getdcb(whichalpha, n); init=-Inf)) => :DCB_high,
    :NEQ_max => ByRow(n -> maximum(getdcb(whichalpha, n); init=-Inf)) => :DCB_low,
    # init = -Inf is required since the result of getdcb (from molchancb) might be an empty vector.
) # KEYNOTE: It will be super slow (due to large N involved in factorial calculations) if directly uses NEQ_max => ByRow(molchancb).

# # Convert -Inf to NaN
# Is literal infinite
islinf(x::AbstractFloat) = isinf(x)
islinf(x) = false

df = ifelse.(islinf.(df), NaN, df)

dropnanmissing!(df, Not(r"NEQ"))


P = prep202304!(df)
transform!(P.table, [:frc, :frc_ind] => ByRow((x, y) -> @sprintf("(%.2d) %s", y, x)) => :frc_ind_frc)
# Colors:

CF23 = ColorsFigure23(P)
@assert isequal(P.table, df)

# # Common functions for plots

stryear(x) = "$x years"
repus(x) = replace(x, "_" => "-")
xlabel2 = L"\text{Filter}"
ylabel2 = L"D_c  \text{(averaged over trials)}"

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
end # Add left, top and bottom super labels.

# # Fitting Degree
# combined DataFrame for plot
dfcb = combine(groupby(df, [:frc_ind, :prp, :trial]), :FittingDegree => nanmean => :FittingDegreeMOM, :DCB_low => uniqueonly, :DCB_high => uniqueonly, nrow; renamecols=false)
dropnanmissing!(dfcb)

insertcols!(dfcb, :DCB_top => 1.0) # this is for plotting shaded area
insertcols!(dfcb, :DCB_bottom => -1.0)

dcmeanstyle = (color=:red, linestyle=:solid)
dcmedstyle = (color=:firebrick1, linestyle=:dash)

f1 = Figure(; size=(800, 1000))
pl_plots = f1[1, 1] = GridLayout()
pl_legend = f1[2, 1] = GridLayout()

# rowsize!(f1.layout, 1, Relative(3 / 4))
let
    rainbowbars = visual(BarPlot, colormap=CF23.frc.colormap, strokewidth=0.5, gap=0.3) *
                  mapping(color=:frc_ind) *
                  mapping(:frc_ind,
                      :FittingDegreeMOM => identity => ylabel2) # WARN: it is not allowed to have integer grouping keys.

    clevel1 = visual(Band; alpha=0.5, color=:gray69) * (mapping(:frc_ind, :DCB_bottom, :DCB_low) + mapping(:frc_ind, :DCB_bottom, :DCB_high))
    clevel2 = visual(ScatterLines; color=:black, linewidth=0.3, markersize=3) * (mapping(:frc_ind, :DCB_low) + mapping(:frc_ind, :DCB_high))


    plt = (data(dfcb) * (clevel1 + rainbowbars + clevel2)) * mapping(col=:trial, row=:prp)
    draw!(pl_plots, plt; axis=(; xlabel="", xticklabelrotation=0.2π, limits=(nothing, Tuple(extrema((vcat(dfcb.FittingDegreeMOM, dfcb.DCB_low, dfcb.DCB_high))) .+ [-0.05, +0.05]))))
end

label_DcHist!(pl_plots; left_label="fitting degree", right_label="", bottom_label="Forecasting Phase")

Legend(pl_legend[1, 1],
    [PolyElement(polycolor=color) for color in CF23.frc.colormap],
    P.uniqfrc,
    "Forecasting phase",
    labelsize=12,
    tellheight=true, tellwidth=true, halign=:left, valign=:top, orientation=:horizontal, nbanks=4)

toppoints = [(0.0, 0.7), (0.33, 0.8), (0.66, 0.6), (1, 1)]
Legend(pl_legend[2, 1],
    [
        [
        PolyElement(color=:gray69, strokecolor=:black, strokewidth=0.5,
            alpha=0.5,
            points=Point2f[toppoints..., (1, 0), (0, 0)]),
        LineElement(color=:black, linestyle=nothing, points=Point2f.(toppoints), linewidth=1),
        MarkerElement(color=:black, markersize=4, marker=:circle, points=Point2f.(toppoints))
    ]
    ],
    ["≤ $fdperc confidence boundary of fitting degree for minimum/maximum number of target EQKs"];
    labelsize=15,
    valign=:bottom, tellheight=true
)
f1
Makie.save("FittingDegree_barplot_colored_by=frc.png", f1)


# # Overall fitting degrees

calcfd(τ, τ₀, μ, μ₀) = 1 - τ / τ₀ - μ / μ₀

dfcb2 = @chain df begin
    # Calculate total number of earthquakes and alarmed area
    # !!! note
    #     To calculate overall fitting degree, sum over the number of EQK and area of TIP is required.
    #     However, MagTIP-2022's `jointstation` did not yet return nEQK (number of target earthquakes)
    #     and areaTIP (spatial TIP area) for each model (out of total 500 permutations).
    #     I have no choice but use `NEQ_min`/`_max` (from MagTIP-2022's `jointstation_summary` with
    #     'CalculateNEQK' option) to "restore" the number of hitted/missed earthquakes using
    #     MissingRateForecasting and `NEQ_min`/`_max` (minimum/maximum possible number of target earthquakes).
    transform([:MissingRateForecasting, :NEQ_min] => ByRow((m, n) -> n * m) => :missed_min)
    transform([:MissingRateForecasting, :NEQ_max] => ByRow((m, n) -> n * m) => :missed_max)
    transform([:AlarmedRateForecasting, :frc] => ByRow((τ, t) -> τ * dtstr2nday(t)) => :alarmed_area)
    transform(:frc => ByRow(dtstr2nday) => :total_area)
    groupby([:frc, :prp, :trial])
    combine(Cols(r"NEQ", r"missed\_", r"\_area") .=> mean; renamecols=false)
    # NEQ must be integer, since in each frc, prp and trial, NEQ should be identical.
    transform(Cols(r"NEQ") .=> ByRow(Int); renamecols=false)
    #
    groupby([:prp, :trial])
    combine(Cols(r"NEQ", r"missed\_", r"\_area") .=> sum, ; renamecols=false)
    transform([:alarmed_area, :total_area, :missed_min, :NEQ_min] => ByRow(calcfd) => :DC_summary_min)
    transform([:alarmed_area, :total_area, :missed_max, :NEQ_max] => ByRow(calcfd) => :DC_summary_max)
    # !!! warning
    #     It should be noticed that here I assume spatial TIP area is identical accross frc.
    transform(AsTable(Cols(r"DC\_summary\_m")) => ByRow(mean) => :DC_summary)
    transform(AsTable(Cols(r"DC\_summary")) => ByRow(nt -> diff(sort(collect(nt)))) => :DC_error)
    transform(:DC_error => [:DC_error_low, :DC_error_high])
end


dfcb2a = @chain dfcb2 begin # separated since it is super slow
    transform(Cols(r"NEQ") .=> ByRow(BigInt); renamecols=false)
    transform(
        :NEQ_max => ByRow(n -> maximum(getdcb(whichalpha, n), init=-Inf)) => :DCB_low,
        :NEQ_min => ByRow(n -> maximum(getdcb(whichalpha, n), init=-Inf)) => :DCB_high
    )
    select(:prp, :trial, :DCB_low, :DCB_high)
end

dfcb2 = outerjoin(dfcb2, dfcb2a; on=[:prp, :trial])

# TODO: modify matlab code to export TIPTrueArea, TIPAllArea, EQKMissingNumber and EQKAllNumber for calculating overall fitting degree with 1 - sum(TIMTrueArea)/sum(TIPAllArea) - sum(EQKMissingNumber/EQKAllNumber) ???



dropnanmissing!(dfcb2)


f2 = Figure(; size=(800, 550))
let dfcb = dfcb2
    x = :prp => repus => xlabel2
    dcbars = (
        visual(BarPlot; color=:royalblue4) *
        mapping(x, :DC_summary => ylabel2)
    )

    cusvis(namedcolor) = visual(ScatterLines; color=namedcolor, linewidth=1.5, markersize=10)

    dclevels = cusvis(:springgreen1) * mapping(x, :DCB_low) + cusvis(:springgreen3) * mapping(x, :DCB_high)

    errbars = visual(Errorbars; whiskerwidth=10, color=:cadetblue3) * mapping(x, :DC_summary, :DC_error_low, :DC_error_high) +
              visual(Scatter; color=:cadetblue3) * mapping(x, :DC_summary)

    draw!(f2, data(dfcb) * (dcbars + errbars + dclevels) * mapping(col=:trial); axis=(xticklabelrotation=0.2π,))
    Legend(f2[2, :],
        [
            [
                LineElement(color=:springgreen1, linestyle=nothing, points=Point2f[(0, 0.2), (1, 0.2)]),
                LineElement(color=:springgreen3, linestyle=nothing, points=Point2f[(0, 0.8), (1, 0.8)]),
                MarkerElement(color=[:springgreen1, :springgreen3], markersize=12, marker=:circle, points=Point2f[(0.5, 0.2), (0.5, 0.8)])],
            [
                PolyElement(color=:royalblue4, strokecolor=:black, strokewidth=0.5,
                    points=Point2f[(0, 0.8), (1, 0.8), (1, 0), (0, 0)]),
                MarkerElement(color=:cadetblue3, markersize=13, marker='工', points=Point2f[(0.5, 0.8)]),
                MarkerElement(color=:cadetblue3, markersize=6, marker=:circle, points=Point2f[(0.5, 0.8)])
            ]
        ],
        ["$fdperc Confidence boundary of fitting degree for minimum/maximum number of target EQKs",
            "Fitting degree with error concerning minimum/maximum number of target EQKs"], ;
        labelsize=15,
        valign=:bottom, tellheight=true
    )
end
label_DcHist!(f2; left_label="fitting degree", right_label="", bottom_label="")
f2
Makie.save("FittingDegree_barplot_mono_color_with=nanmean.png", f2)


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

# # Temporary treatment for aesthetic mapping issue
# - https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/505
# - https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/521
function AlgebraOfGraphics.aesthetic_mapping(::Type{Hist}, ::AlgebraOfGraphics.Normal)
    AlgebraOfGraphics.dictionary([
        1 => AlgebraOfGraphics.AesX,
        :color => AlgebraOfGraphics.AesColor,
    ])
end

function AlgebraOfGraphics.aesthetic_mapping(::Type{Density}, ::AlgebraOfGraphics.Normal)
    AlgebraOfGraphics.dictionary([
        1 => AlgebraOfGraphics.AesX,
        :color => AlgebraOfGraphics.AesColor,
        :linestyle => AlgebraOfGraphics.AesLineStyle,
    ])
end # https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/520

f3 = Figure(; size=(800, 900))
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
f3a = Figure(; size=(1000, 700))
raincloudkwargs = (plot_boxplots=true, orientation=:vertical,
    cloud_width=0.85,
    clouds=hist,
    markersize=1, # scatter plot settings
    # jitter_width=0.02, # FIXME: https://github.com/MakieOrg/Makie.jl/issues/3981
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
f3ap = draw!(f3a, histcomb_f3a, scales(Color=(; palette=CF23.prp.to_color.(1:4))))
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
    f50res = (size=(800, 700),)
    f5sckwargs = (titlesize=13, aspect=1, xticklabelrotation=0.2π)
    f5 = Figure(; f50res...)

    # # KEYNOTE: `set_aog_color_palette!` should be deprecated since color aesthetic won't be "pulled in via the theme" after AoG v0.7.
    # For more details refer to  https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/505

    plt5 = draw!(
        f5[1, 1],
        aog_layer,
        scales(Color=(; palette=CF23.trial.colormap));
        axis=(f5sckwargs..., limits=(xylimits, xylimits))
    )
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
visual_scatter = visual(Scatter, markersize=5, alpha=0.3) * mapping(marker=:trial)


molchan_all_frc = data(P.table) * xymap * mapping(color=:trial) *
                  mapping(layout=:prp => "filter")

f5c = fig5_molchan_by_prp(molchan_all_frc * (visual_contour + visual_scatter) + randguess, "MolchanDiagram_Contour_color=trial_layout=prp.png")
f5s = fig5_molchan_by_prp(molchan_all_frc * visual_scatter + randguess, "MolchanDiagram_Scatter_color=trial_layout=prp.png")


f5res = (size=(800, 700),)
f5abkwargs = (titlesize=11, aspect=1, xticklabelrotation=0.2π)

densitykwargs = (bandwidth=0.01, boundary=(-0.1, 1.1)) # KEYNOTE: `visual(Density)` failed using AoG v0.8.0 and Makie v0.21.6 at the step of generate legend ("ERROR: MethodError: no method matching legend_elements(::Type{Plot{…}}, ::Dictionaries.Dictionary{Symbol, Any}, ::Dictionaries.Dictionary{Union{…}, Any})")

ratedensity = data(P.table) * AlgebraOfGraphics.density() * mapping(color=:trial) * mapping(layout=:frc_ind_frc)
f5a = draw(ratedensity * mapping(:AlarmedRateForecasting),
    scales(Color=(; palette=CF23.trial.colormap, categories=CF23.trial.colortag));
    axis=(f5abkwargs..., limits=(xylimits, (nothing, nothing)), xlabel="alarmed rate", ylabel="pdf"), figure=f5res)
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
