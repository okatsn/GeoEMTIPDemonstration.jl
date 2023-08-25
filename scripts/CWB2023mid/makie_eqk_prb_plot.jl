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
using Clustering
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
dfg1 = groupdfs[1]

function eqkprb_plot(dfg1)
    dfg = deepcopy(dfg1)
    transform!(dfg, :dt => ByRow(datetime2julian) => :x)
    transform!(dfg, :eventTime => ByRow(get_value) => :evtx)

    probplt = data(dfg) * visual(Lines) * mapping(:x, :probabilityMean)
    eqkplt = data(dfg) * visual(Scatter, color=:red) * mapping(:evtx, :eventSize)

    f = Figure()
    axleft, axright = twinaxis(f[1, 1];
        left_ax=(; ylabel="probability"),
        right_ax=(; ylabel="event magnitude"),
        right_color=:red)

    for ax in [axleft, axright]
        datetimeticks!(ax, identity.(dfg.dt), identity.(dfg.x), Month(3))
        ax.xticklabelrotation = 0.2π
    end

    # axleft = Axis(f[1, 1])

    draw!(axleft, probplt)
    draw!(axright, eqkplt)

    # display(f)
    # Makie.inline!(true)
    # Makie.current_axis!(axleft)
    Makie.update_state_before_display!(f) # this has the same effect of display(f) but without displaying it. It is essential for axes to be correctly linked.

    # xlims!(axright, getlimits(axleft, 1))
    linkxaxes!(axleft, axright)
    f
end



for dfg in groupdfs[10:15]
    with_theme(resolution=(1200, 300), Scatter=(marker=:star5, markersize=10, alpha=0.3), Lines=(; alpha=0.6, linewidth=0.5)) do
        f = eqkprb_plot(dfg)
        display(f)
    end
end


using Unzip
using Downloads
downloader = Downloader()
twzip = download("https://data.moi.gov.tw/MoiOD/System/DownloadFile.aspx?DATA=72874C55-884D-4CEA-B7D6-F60B0BE85AB0")

compressed1 = open(twzip, "r") do io
    read(io)
end
CodecZlib.deflate!(compressed1)
decompressed1 = transcode(ZlibDecompressor, compressed1)


using CodecZlib
# References that may help:
# https://stackoverflow.com/questions/50233579/how-to-process-a-zipfile-using-julia
# https://discourse.julialang.org/t/reading-files-embedded-in-a-zip-file/10675/9
