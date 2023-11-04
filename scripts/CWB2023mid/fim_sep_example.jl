using CSV, DataFrames
df = CSV.read("LargeFiles/delete_after_2025/fimsep_example.csv", DataFrame; header=
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
])
