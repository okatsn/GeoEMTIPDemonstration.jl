using DataFrames, Gadfly, CSV
using Revise
using GeoEMTIPDemonstration
df = CSV.read(dir_cwb2023mid("summary_test.csv"), DataFrame);
transform!(df, :HitRatesForecasting => ByRow(x->1-x) => :MissingRateForecasting)
dfg = groupby(df, "prp")
uniqprp = string.(unique(df.prp))
uniqcolors = Scale.default_discrete_colors(length(uniqprp))
prp2index(str) = only(findall(occursin.(str, uniqprp)))
transform!(df, :prp => ByRow(prp2index) => :group1)
transform!(df, :group1 =>  ByRow(ind -> uniqcolors[ind]) => :group1_colors)


# ## All in one
plot(df, x=:AlarmedRateForecasting, y = :MissingRateForecasting, 
    intercept=[1], slope=[-1], Geom.abline(color="red", style=:dash),
    Geom.density2d(levels = 5), Geom.point, color = :group1_colors, alpha = [0.1],
    Coord.cartesian(xmin=0, xmax=1, ymin=0, ymax = 1, aspect_ratio=1)
)

# ## Each a subplot
set_default_plot_size(21cm, 8cm)
plot(df, x=:AlarmedRateForecasting, y = :MissingRateForecasting, 
    intercept=[1], slope=[-1], # args for abline
    xgroup = :prp, color = :group1_colors, alpha = [0.1],
    Geom.subplot_grid(
        Geom.density2d(levels = 7), 
        Geom.point,
        Geom.abline(color="red", style=:dash),
        Coord.cartesian(xmin=0, xmax=1, ymin=0, ymax = 1, aspect_ratio=1),
        # Coord.cartesian(xmin=0, xmax=1, ymin=0, ymax = 1, aspect_ratio=1)
    )
)

