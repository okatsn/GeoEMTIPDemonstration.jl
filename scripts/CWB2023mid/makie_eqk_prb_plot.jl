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
using MLJ # for standardization
using Clustering
using OkMLModels
# sperical distance
using SphericalGeometry
using EventSpaceAlgebra


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

## Preprocess
# convert `probabilityTimeStr` to `DateTime`
transform!(df, :probabilityTimeStr => ByRow(t -> DateTime(t, "d-u-y")) => :dt)
transform!(df, :eventTimeStr => ByRow(t -> DateTime(t, "d-u-y H:M:S")) => :eventTime)
transform!(df, :eventTime => ByRow(x -> EventTime(datetime2julian(x), JulianDay)); renamecols=false)

# Event location
transform!(df, :eventLat => ByRow(x -> Latitude(x, Degree)); renamecols=false)
transform!(df, :eventLon => ByRow(x -> Longitude(x, Degree)); renamecols=false)


# Add event id
eachevent = groupby(df, [:eventTime, :eventSize, :eventLat, :eventLon])
transform!(eachevent, groupindices => :eventId)

## Event clustering
targetcols = [:eventTime, :eventLon, :eventLat]
EQK = combine(eachevent, [targetcols..., :eventId] .=> unique; renamecols=false) # unique earthquake events


## Standardization/Normalization
# normalized radius for DBSCAN
eqk = @view EQK[!, targetcols]
eqk_minmax = combine(eqk, All() .=> (x -> [extrema(x)...]); renamecols=false)
insertcols!(eqk_minmax, :transform => [:minimum, :maximum])

# a "dictionary" for indexing variable's range
evtvarrange = combine(eqk_minmax, Cols(r"event") .=> (x -> diff(x)); renamecols=false) |> eachrow |> only

eqk_crad = Dict( # SETME:
    "eventTime" => 30.0, #days
    "eventLon" => 0.1, # deg., ~11 km
    "eventLat" => 0.1,
) # radius for DBSCAN clustering

latrange = get_value.([evtvarrange.eventLon, evtvarrange.eventLat]) |> maximum

rrratio_time = get_value(evtvarrange.eventTime) / eqk_crad["eventLat"]
rrratio_maxspace = latrange / eqk_crad["eventLat"]


normalize(el::EventSpaceAlgebra.Spatial) = el
function normalize(el::EventSpaceAlgebra.Temporal)
    tp = typeof(el)
    newval = (get_value(el - minimum(EQK.eventTime))) /
             eqk_crad["eventTime"] * eqk_crad["eventLat"]
    tp(newval, get_unit(el))
end

EQK_n = select(EQK, targetcols .=> ByRow(normalize); renamecols=false)

# # Clusterting by dbscan
dbresult = dbscan(get_value.(Matrix(EQK_n))', eqk_crad["eventLat"])
insertcols!(EQK, :clusterId => dbresult.assignments)

describe(EQK)





# CHECKPOINT:
# - remove any eventTime_x



twopoints = SphericalGeometry.Point.(
    [24.2, 24.3],
    [121.0, 121.0],
)
angular_distance(twopoints...) * 6371 / 360 * 2π
# Verified with matlab code: deg2km(distance('gc', [24.2, 121.0], [24.3, 121.0]))


r_latlon = 0.1
EQK.eventLat |> diff .|> abs |> unique
r_latlon = 0.1


dfstd = MLJ.transform(mach, EQK)
dfstd.eventTime_x * 5 |> hist
df.eventTime_x |> hist

dfstd.eventLat |> hist
df.eventLat |> hist

# CHECKPOINT: Noted that in EQK and df, `targetcols` are the original








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
