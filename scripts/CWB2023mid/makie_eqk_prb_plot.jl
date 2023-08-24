using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Chain
using GeoMakie
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
using Clustering
using EventSpaceAlgebra


df_ge = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_GE_3yr_180d_500md_2023A10_compat_1")
df_gm = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_GM_3yr_180d_500md_2023A10_compat_1")
df_mix = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_MIX_3yr_180d_500md_2023A10_compat_1")

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



## Event clustering
eachevent = groupby(df, :eventId)
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
end # the use of `EventSpaceAlgebra` is intended to dispatch different `normalize` method according to the type of `EventSpaceAlgebra.Coordinate`

EQK_n = select(EQK, targetcols .=> ByRow(normalize); renamecols=false)

# # Clusterting by dbscan
dbresult = dbscan(get_value.(Matrix(EQK_n))', eqk_crad["eventLat"])
insertcols!(EQK, :clusterId => dbresult.assignments)

event2cluster(eventId) = Dict(EQK.eventId .=> EQK.clusterId)[eventId]

transform!(df, :eventId => ByRow(event2cluster) => :clusterId)

# CHECKPOINT:
# - remove any eventTime_x

groupdfs = groupby(df, [:prp, :trial, :clusterId])
dfg1 = groupdfs[15]

function eqkprb_plot(dfg1)
    dfg = deepcopy(dfg1)
    transform!(dfg, :dt => ByRow(datetime2julian) => :x)
    transform!(dfg, :eventTime => ByRow(get_value) => :evtx)

    probplt = data(dfg) * visual(Lines, colormap=:blues) * mapping(:x => identity => "date", :probabilityMean => identity => "probabilities around epicenter")
    if length(unique(dfg.eventId)) > 1
        probplt *= mapping(color=:eventId)
    end

    eqkplt = data(dfg) * visual(Scatter, color=:red) * mapping(:evtx, :eventSize)

    f = Figure()
    draw!(f[:, :], probplt)

    leftaxs = filter(x -> x isa Axis, f.content)

    rightaxs = twinaxis.(leftaxs; color=:red, other=(; ylabel="event magnitude", ylabelcolor=:red))
    draw!.(rightaxs, Ref(eqkplt))

    for (axleft, axright) in zip(leftaxs, rightaxs)
        for ax in [axleft, axright]
            ax.xticklabelrotation = 0.2π
            datetimeticks!(ax, identity.(dfg.dt), identity.(dfg.x), Month(3))
        end
    end

    # display(f)
    # Makie.inline!(true)
    # Makie.current_axis!(axleft)
    Makie.update_state_before_display!(f) # this has the same effect of display(f) but without displaying it. It is essential for axes to be correctly linked.

    # xlims!(axright, getlimits(axleft, 1))
    linkxaxes!(f)
    f
end



for dfg in groupdfs[10:15]
    with_theme(resolution=(1200, 600), Scatter=(marker=:star5, markersize=10, alpha=0.3), Lines=(; alpha=0.6, linewidth=0.7)) do
        f = eqkprb_plot(dfg)
        display(f)
    end
end



# Map plot
# https://quicademy.com/2023/07/17/the-5-best-geospatial-packages-to-use-in-julia/
# OpenStreetMapXPlot.jl with Makie: https://github.com/JuliaDynamics/Agents.jl/issues/437
# common geographics datasets such as location of shoreline, rivers and political boundaries https://juliageo.org/GeoDatasets.jl/dev/

# From example: https://geo.makie.org/stable/examples/#Italy's-states

using WGLMakie, GeoMakie
using GeoMakie.GeoJSON
using Downloads
using GeometryBasics
using GeoInterface

# Acquire data
it_states = Downloads.download("https://github.com/openpolis/geojson-italy/raw/master/geojson/limits_IT_provinces.geojson")
tw_counties = Downloads.download("https://github.com/g0v/twgeojson/raw/master/json/twCounty2010.geo.json")
geo = GeoJSON.read(read(tw_counties, String))

fig = Figure()
ga = GeoAxis(fig[1, 1]; dest="+proj=ortho +lon_0=120.1 +lat_0=23.9", lonlims=(118, 122.3), latlims=(21.8, 25.8))
poly!(ga, geo; strokecolor=:blue, strokewidth=1, color=(:blue, 0.5), shading=false);
# datalims!(ga) # this doesn't work


fig
