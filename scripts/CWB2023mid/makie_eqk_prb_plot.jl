using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
using Printf
import NaNMath: mean as nanmean
# using Revise # using Revise through VSCode settings
using CWBProjectSummaryDatasets
using GeoEMTIPDemonstration
using OkMakieToolkits
using Dates
using OkFiles
# clustering
# using MLJ # for standardization


df_ge = CSV.read("data/temp/PhaseTestEQK_GE_3yr_180d_500md_2023J30.csv", DataFrame)
df_gm = CSV.read("data/temp/PhaseTestEQK_GM_3yr_180d_500md_2023J30.csv", DataFrame)
df_mix = CSV.read("data/temp/PhaseTestEQK_MIX_3yr_180d_500md_2023J30.csv", DataFrame)

tagdfs = Dict(
    "GE" => df_ge,
    "GM" => df_gm,
    "MIX" => df_mix
);

for (tag, df) in tagdfs
    insertcols!(df, :trial => tag)
end

df = vcat(df_ge, df_gm, df_mix)

# convert `probabilityTimeStr` to `DateTime`
transform!(df, :probabilityTimeStr => ByRow(t -> DateTime(t, "d-u-y")) => :dt)
transform!(df, :eventTimeStr => ByRow(t -> DateTime(t, "d-u-y H:M:S")) => :eventTime)

# full list of datetime; TimeAsX.
fulldt = df.dt |> unique |> sort
transform!(df, :dt => ByRow(datetime2julian) => :x)
transform!(df, :eventTime => ByRow(datetime2julian) => :eventTime_x)

groupdfs = groupby(df, [:prp])
dfg1 = groupdfs[1]

function eqkprb_plot(dfg1)
    probplt = data(dfg1) * visual(Lines) * mapping(:x, :probabilityMean, color=:trial)
    f = Figure()
    axleft, axright = twinaxis(f[1, 1])
    linkxaxes!(axleft, axright)
    # axleft = Axis(f[1, 1])
    draw!(axleft, probplt)

    evtlist = let uniqcols = [:eventTime, :eventTime_x, :eventSize, :eventLat, :eventLon]
        evtlist = combine(groupby(dfg1, uniqcols), uniqcols .=> unique)
    end

    evtx = evtlist.eventTime_x
    evtsz = evtlist.eventSize
    scatter!(axright, evtx, evtsz, markersize=5 .+ evtsz * 10, color=:red)

    for ax in [axleft, axright]
        datetimeticks!(ax, df.dt, df.x, Month(1))
        ax.xticklabelrotation = 0.2π
    end
    f
end

for dfg1 in groupdfs[1:2]
    with_theme(resolution=(1200, 300), Scatter=(alpha=0.3, marker=:circle)) do
        f = eqkprb_plot(dfg1)
        display(f)
    end
end
