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

# convert `timeStr` to `DateTime`
transform!(df, :timeStr => ByRow(t -> DateTime(t, "d-u-y")) => :dt)
select!(df, All(), :eventTime => ByRow(t -> DateTime(t, "y/m/d H:M")); renamecols=false)

# full list of datetime; TimeAsX.
fulldt = df.dt |> unique |> sort
dictTX = Dict(fulldt .=> eachindex(fulldt))
transform!(df, :dt => ByRow(t -> dictTX[t]) => :x)
transform!(df, :eventTime => ByRow(t -> dictTX[floor(t, Day(1))]) => :eventTime_x)




groupby(df, [:eventTag]) |> length

dfg1 = groupby(df, [:eventTag])[1]

f = Figure()

probplt = data(dfg1) * visual(Lines) * mapping(:x, :ProbabilityMean, linestyle=:trial)

axleft, axright = twinaxis(f[1, 1])
linkxaxes!(axleft, axright)
# axleft = Axis(f[1, 1])
draw!(axleft, probplt)

evtx = dfg1.eventTime_x |> unique
evty = fill(1, length(evtx))
scatter!(axright, evtx, evty, markersize=20)

f
