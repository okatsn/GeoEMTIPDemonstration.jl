# https://juliadatascience.io/recipe_df
using GeoEMTIPDemonstration
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
using MolchanCB
using Dates
using Project2024
CWBProjectSummaryDatasets.datasets()

(df23, df24a, df24) = Project2024.load_all_trials(PhaseTest())


# # Keep only data where frc and prp labels matching the other dataset
# (otherwise, the comparison has no meaning)

function filter_intersect(nt)
    in(nt.prp, intersect(Set(df23.prp), Set(df24.prp))) &&
        in(nt.frc, intersect(Set(df23.frc), Set(df24.frc)))
end

filter!(AsTable(:) => filter_intersect, df23)
filter!(AsTable(:) => filter_intersect, df24)
filter!(AsTable(:) => filter_intersect, df24a)


# # Combine the two table

# Pre-process for consistency in columns of two datasets.

# df23 is of older format thus missing in some columns.
# missingcols = setdiff(Set(names(df24)), Set(names(df23)))
# for c in missingcols
#     insertcols!(df23, c => missing)
# end
select!(df24, names(df23))
select!(df24a, names(df23))
# KEYNOTE: Because later in the script `dropmissing!` is used a couple of times, which results in entirely remove the 2023 data if those unavailable columns are added and filled with missing values, I do discard columns of 2024 data that was not available in 2023 data instead.



# combine df23 and df24
df = DataFrame()
for dfi in [df23, df24, df24a]
    append!(df, dfi; promote=true)
end

# # Train-Test time span plot

TTP23a = TrainTestPartition23a(unique(df.frc), 3)
(ax0N, f0Nyr) = figureplot(TTP23a; size=(700, 400))


# NEQ summary table
dfneq = @chain df begin
    groupby([:prp, :trial, :frc])
    combine(Cols(r"NEQ") .=> (x -> only(unique(extrema(x)))); renamecols=false)
    groupby([:frc, :trial])
    combine([:NEQ_min, :NEQ_max] => ((a, b) -> extrema(vcat(a, b))) => :NEQ_range)
    unstack(:frc, :trial, :NEQ_range)
end



# #

# SETME: Parameter settings:
whichalphas = [0.32, 0.05]
confidence68 = 0.32

uniqueonly(x) = x |> unique |> only

fdpercs = ["$(Int(round((1-α) * 100)))%" for α in whichalphas]

transform!(df,
    :NEQ_min => ByRow(n -> maximum(getdcb(confidence68, n); init=-Inf)) => :DCB_high,
    :NEQ_max => ByRow(n -> maximum(getdcb(confidence68, n); init=-Inf)) => :DCB_low,
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

CF23 = ColorsFigure23(P; prpcolor=Project2024.noredDark2.colors)
@assert isequal(P.table, df)

# Scales
# # This is new after AoG v0.7. Please refer https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/505
scales_prp = scales(Color=(; palette=CF23.prp.colormap, categories=CF23.prp.colortag))

scales_frc = scales(;
    bar_rainbowcolor=(
        Color = (palette=CF23.frc.colormap, categories=CF23.frc.colortag)
    )
)




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
# KEYNOTE: About fitting degree of the training phase:
# - Previously, the fitting of training phase is conducted via plotEQK1.m
#   - You can only calculate the fitting of the models of same "rank". E.g., best model (rank 1) of every station.
#   - Noted that the results is very different from joint-station fitting degree, even if you "add them all".
# - The 500 sets of indices of permutation in the jointstation step has not (and never) been saved.
# - So far there is no way to derive the true fitting degree of the
#   "training phase "of the 500 sets of jointstation parameters that
#   are used for forecasting, because those necessary detailed variables have
#   never been saved.
dfcb = combine(groupby(df, [:frc_ind, :frc, :prp, :trial]), :FittingDegree => nanmean => :FittingDegreeMOM, :DCB_low => uniqueonly, :DCB_high => uniqueonly, nrow; renamecols=false)
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
    rainbowbars = visual(BarPlot, strokewidth=0.5, gap=0.3) *
                  mapping(color=:frc => scale(:bar_rainbowcolor)) * # color can only be categorical (not Continuous).
                  mapping(:frc_ind,
                      :FittingDegreeMOM => identity => ylabel2)

    clevel1 = visual(Band; alpha=0.5, color=:gray69) * (mapping(:frc_ind, :DCB_bottom, :DCB_low) + mapping(:frc_ind, :DCB_bottom, :DCB_high))
    clevel2 = visual(ScatterLines; color=:black, linewidth=0.3, markersize=3) * (mapping(:frc_ind, :DCB_low) + mapping(:frc_ind, :DCB_high))


    plt = (data(dfcb) * (clevel1 + rainbowbars + clevel2)) * mapping(col=:trial, row=:prp)
    draw!(pl_plots, plt, scales_frc; axis=(; xlabel="", xticklabelrotation=0.2π, limits=(nothing, Tuple(extrema((vcat(dfcb.FittingDegreeMOM, dfcb.DCB_low, dfcb.DCB_high))) .+ [-0.05, +0.05]))))
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
display(f1)
Makie.save("FittingDegree_barplot_colored_by=frc.png", f1)


# # Overall fitting degrees

calcfd(τ, τ₀, μ, μ₀) = 1 - τ / τ₀ - μ / μ₀

dfcb2 = @chain df begin
    # Calculate total number of earthquakes and alarmed area
    # KEYNOTE:
    # - To calculate overall fitting degree, sum over the number of EQK and area of TIP is required.
    #   However, MagTIP-2022's `jointstation` did not yet return nEQK (number of target earthquakes)
    #   and areaTIP (spatial TIP area) for each model (out of total 500 permutations).
    #   I have no choice but use `NEQ_min`/`_max` (from MagTIP-2022's `jointstation_summary` with
    #   'CalculateNEQK' option) to "restore" the number of hitted/missed earthquakes using
    #   MissingRateForecasting and `NEQ_min`/`_max` (minimum/maximum possible number of target earthquakes).
    # - Because the true `total_area` of each forecasting phase could vary a little, thus
    #   the column is renamed as `pseudoTotal_area` to avoid misleading.
    # - Thus, the `DC_summary` is calculated based on averaged alarmed rate, rather than
    #   alarmed rate subdivided by total area (which is in fact unknown/not saved).
    #
    transform([:MissingRateForecasting, :NEQ_min] => ByRow((m, n) -> n * m) => :missed_min)
    transform([:MissingRateForecasting, :NEQ_max] => ByRow((m, n) -> n * m) => :missed_max)
    transform([:AlarmedRateForecasting, :frc] => ByRow((τ, t) -> τ * dtstr2nday(t)) => :alarmed_area)
    transform(:frc => ByRow(dtstr2nday) => :pseudoTotal_area)
    groupby([:frc, :prp, :trial])
    combine(Cols(r"NEQ", r"missed\_", r"\_area") .=> mean; renamecols=false)
    # NEQ must be integer, since in each frc, prp and trial, NEQ should be identical.
    transform(Cols(r"NEQ") .=> ByRow(Int); renamecols=false)
    #
    groupby([:prp, :trial])
    combine(Cols(r"NEQ", r"missed\_", r"\_area") .=> sum, ; renamecols=false)
    transform([:alarmed_area, :pseudoTotal_area, :missed_min, :NEQ_min] => ByRow(calcfd) => :DC_summary_min)
    transform([:alarmed_area, :pseudoTotal_area, :missed_max, :NEQ_max] => ByRow(calcfd) => :DC_summary_max)
    # !!! warning
    #     It should be noticed that here I assume spatial TIP area is identical accross frc.
    transform(AsTable(Cols(r"DC\_summary\_m")) => ByRow(mean) => :DC_summary)
    transform(AsTable(Cols(r"DC\_summary")) => ByRow(nt -> diff(sort(collect(nt)))) => :DC_error)
    transform(:DC_error => [:DC_error_low, :DC_error_high])
end


dfcb2a = @chain dfcb2 begin # separated since it is super slow
    transform(Cols(r"NEQ") .=> ByRow(BigInt); renamecols=false)
    transform(
        :NEQ_max => ByRow(n -> maximum(getdcb(0.32, n), init=-Inf)) => :DCB_low_68,
        :NEQ_min => ByRow(n -> maximum(getdcb(0.32, n), init=-Inf)) => :DCB_high_68,
        :NEQ_max => ByRow(n -> maximum(getdcb(0.05, n), init=-Inf)) => :DCB_low_95,
        :NEQ_min => ByRow(n -> maximum(getdcb(0.05, n), init=-Inf)) => :DCB_high_95,
    )
    select(:prp, :trial, :DCB_low, :DCB_high)
end

dfcb2 = outerjoin(dfcb2, dfcb2a; on=[:prp, :trial])

# TODO: modify matlab code to export TIPTrueArea, TIPAllArea, EQKMissingNumber and EQKAllNumber for calculating overall fitting degree with 1 - sum(TIMTrueArea)/sum(TIPAllArea) - sum(EQKMissingNumber/EQKAllNumber) ???



dropnanmissing!(dfcb2)


f2 = Figure(; size=(800, 550))

function dclevels(c; low=:DCB_low_99, high=:DCB_high_99)
    clevel = match.(Ref(r"\d+"), string.(high,low)) |> length
    strlegend(dccolor1) = "$clevel% Confidence boundary of fitting degree for minimum/maximum number of target EQKs"

    return (plt = cusvis(c.clow) * mapping(x, low) + cusvis(c.chigh) * mapping(x, high), description = )
end
let dfcb = dfcb2
    cusvis(namedcolor) = visual(ScatterLines; color=namedcolor, linewidth=1.5, markersize=10)

    dccolors1 = (clow=:gray95, chigh=:gray81, alpha=0.32)
    dccolors2 = (clow=:springgreen1, chigh=:springgreen3, alpha=0.95)

    clegend(c) = [
        LineElement(color=c.clow, linestyle=nothing, points=Point2f[(0, 0.2), (1, 0.2)]),
        LineElement(color=c.chigh, linestyle=nothing, points=Point2f[(0, 0.8), (1, 0.8)]),
        MarkerElement(color=[c.clow, c.chigh], markersize=12, marker=:circle, points=Point2f[(0.5, 0.2), (0.5, 0.8)])
    ]

    x = :prp => repus => xlabel2
    dcbars = (
        visual(BarPlot; color=:royalblue4) *
        mapping(x, :DC_summary => ylabel2)
    )


    dclevels1 = dclevels(dccolors1; low=:DCB_low_68, high=:DCB_high_68)
    dclevels2 = dclevels(dccolors2; low=:DCB_low_95, high=:DCB_high_95)

    errbars = visual(Errorbars; whiskerwidth=10, color=:cadetblue3) * mapping(x, :DC_summary, :DC_error_low, :DC_error_high) +
              visual(Scatter; color=:cadetblue3) * mapping(x, :DC_summary)

    draw!(f2, data(dfcb) * (dcbars + errbars + dclevels1 + dclevels2) * mapping(col=:trial); axis=(xticklabelrotation=0.2π,))
    Legend(f2[2, :],
        [
            clegend(dccolors1),
            clegend(dccolors2),
            [
                PolyElement(color=:royalblue4, strokecolor=:black, strokewidth=0.5,
                    points=Point2f[(0, 0.8), (1, 0.8), (1, 0), (0, 0)]),
                MarkerElement(color=:cadetblue3, markersize=13, marker='工', points=Point2f[(0.5, 0.8)]),
                MarkerElement(color=:cadetblue3, markersize=6, marker=:circle, points=Point2f[(0.5, 0.8)])
            ]
        ],
        [
            strlegend(dccolor1),
            strlegend(dccolor2),
            "Fitting degree with error concerning minimum/maximum number of target EQKs"], ;
        labelsize=15,
        valign=:bottom, tellheight=true
    )
end
label_DcHist!(f2; left_label="fitting degree", right_label="", bottom_label="")
display(f2)
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
display(f3)
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
f3ap = draw!(f3a, histcomb_f3a, scales_prp)
label_DcHist!(f3a; right_label="variable", left_label="", bottom_label="probability density")
# legend_f3!(f3a)
display(f3a)
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

molchan_all_frc = data(P.table) * xymap * mapping(col=:trial) *
                  mapping(row=:prp => "filter")

f5c = fig5_molchan_by_prp(molchan_all_frc * (visual_contour + visual_scatter) + randguess, "MolchanDiagram_Contour_color=trial_layout=prp.png")
f5s = fig5_molchan_by_prp(molchan_all_frc * visual_scatter + randguess, "MolchanDiagram_Scatter_color=trial_layout=prp.png")

display(f5c)
display(f5s)

visual_heatmap = visual(Histogram) # please refer:
visual_histogram2d = histogram()
# AlgebraOfGraphics just needs method definitions for `aesthetic_mapping`,
# this is why:
# - `visual(Heatmap)` without `AlgebraOfGraphics.density()` won't work (heatmap takes x, y, and z_color)
# - `hexbin` won't work.
f5h = let aog_layer = molchan_all_frc * (visual_histogram2d) + randguess
    f51res = (size=(800, 700),)
    f5sckwargs = (titlesize=13, aspect=1, xticklabelrotation=0.2π)
    f5 = Figure(; f51res...)

    # # KEYNOTE: `set_aog_color_palette!` should be deprecated since color aesthetic won't be "pulled in via the theme" after AoG v0.7.
    # For more details refer to  https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/505

    plt5 = draw!(
        f5[1, 1],
        aog_layer,
        scales(Color=(; colormap=(:linear_wcmr_100_45_c42_n256), colorrange=(0, 5))); # https://aog.makie.org/stable/generated/penguins/#Smooth-density-plots
        axis=(f5sckwargs..., limits=(xylimits, xylimits),
            xgridwidth=0.1,
            ygridwidth=0.1)
    )
    AlgebraOfGraphics.legend!(f5[1, 2], plt5)
    # Makie.save(target_file, f5)
    display(f5)
    f5
end

# CHECKPOINT: Move grid to the front
# https://discourse.julialang.org/t/how-to-add-grid-lines-on-top-of-a-heatmap-in-makie/77578/2


# KEYNOTE:
# - When scatter points concentrates at one or a few values, RainClouds are ugly, and Density & Density-related (e.g., Violin) goes wrong and misleading.
# - I found no way to set AlgebraOfGraphics.histogram or .density to plot horizontally (the :direction argument for Hist and Density).
# - it is not necessary to have pdf <= 1; it requires only integral over the entire area to be 1.
# `AlgebraOfGraphic.density` use `KernelDensity.kde((df.AlarmedRateForecasting, df.MissingRateForecasting))`
