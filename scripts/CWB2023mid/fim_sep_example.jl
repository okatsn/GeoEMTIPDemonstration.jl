using CSV, DataFrames
using Dates
using CairoMakie, AlgebraOfGraphics
using SWCForecastBase
using Statistics
iszero(v) = v == 0.0
nanmean(x) = mean(filter(!isnan, x))

df = CSV.read("LargeFiles/delete_after_2025/stn[CHCH]dt[20210101-20210105]type[GEMS].csv", DataFrame; header=
[
    :year, :month, :day, :hour, :minute, :second,
    :FIM_1minute_NS,
    :FIM_1minute_EW,
    :SE_1minute_NS,
    :SE_1minute_EW,
    :FIM_1hour_NS,
    :FIM_1hour_EW,
    :SE_1hour_NS,
    :SE_1hour_EW,
    :FIM_1day_NS,
    :FIM_1day_EW,
    :SE_1day_NS,
    :SE_1day_EW,
    :signal_15Hz_NS,
    :signal_15Hz_EW,
])

transform!(df,
    :second => ByRow(t -> round(rem(t, 1) * 1000)) => :millisecond,
    :second => ByRow(floor) => :second
)
transform!(df, [:year, :month, :day, :hour, :minute, :second, :millisecond] => ByRow(DateTime) => :time)
transform!(df, :time => ByRow(t -> floor(t, Minute(1))) => :time)

# df = ifelse.(iszero.(df), NaN, df)

df = combine(groupby(df, :time), :time => unique, Not(:time) .=> nanmean; renamecols=false)




df2 = stack(df, Cols(r"^FIM", r"^SE", r"^signal"), :time)

transform!(df2, :variable => ByRow(str -> begin
    e = split(str, "_")
    (metric=e[1], window=e[2], component=e[3])
end) => AsTable)

# filter!(:window => (str -> str in ["1hour", "15Hz"]), df2)
filter!(:value => !isnan, df2)

# dropmissing!(df2)

with_theme(resolution=(1000, 550)) do
    data(df2) * visual(Lines, linewidth=1) * mapping(:time, :value) * mapping(col=:component, row=:metric) * mapping(color=:window => sorter((["15Hz", "1minute", "1hour", "1day"]))) |> p -> draw(p; facet=(; linkyaxes=:rowwise), axis=(; xticklabelrotation=0.2π))
end
