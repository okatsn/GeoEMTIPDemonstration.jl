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
dictTX = Dict(fulldt .=> eachindex(fulldt))
transform!(df, :dt => ByRow(t -> dictTX[t]) => :x)
transform!(df, :eventTime => ByRow(t -> dictTX[floor(t, Day(1))]) => :eventTime_x)


groupby(df, [:eventTag]) |> length

dfg1 = groupby(df, [:eventTag])[1]

f = Figure()

probplt = data(dfg1) * visual(Lines) * mapping(:x, :probabilityMean, linestyle=:trial)

axleft, axright = twinaxis(f[1, 1])
linkxaxes!(axleft, axright)
# axleft = Axis(f[1, 1])
draw!(axleft, probplt)

evtlist = let uniqcols = [:eventTime, :eventTime_x, :eventSize, :eventLat, :eventLon]
    evtlist = combine(groupby(dfg1, uniqcols), uniqcols .=> unique)
end

evtx = evtlist.eventTime_x
scatter!(axright, evtx, fill(0, length(evtx)), markersize=10 .+ evtlist.eventSize * 3)

for ax in [axleft, axright]
    datetimeticks!(ax, df.dt, df.x, Month(1))
    ax.xticklabelrotation = 0.2π
end

f
