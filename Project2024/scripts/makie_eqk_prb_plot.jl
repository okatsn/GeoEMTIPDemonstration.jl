using DataFrames, CSV
using AlgebraOfGraphics
# import CairoMakie
using CairoMakie
using ColorSchemes
using Chain
using Statistics
using LaTeXStrings
using Printf
import NaNMath: mean as nanmean
# using Revise # using Revise through VSCode settings
using GeoEMTIPDemonstration
using Project2024
using CWBProjectSummaryDatasets
using OkMakieToolkits
using Dates
using OkFiles
using Shapefile
using CategoricalArrays
# clustering
using Clustering
using EventSpaceAlgebra
using Unitful
using NearestNeighbors
using LinearAlgebra
using Test

# Define the unit for scaling t in pointENU
@unit hr12 "12hr" Hour12 12u"hr" false

Unitful.register(@__MODULE__)


targetdir(args...) = joinpath("temp/2024", args...)
mkpath(targetdir())

# !!! note Map plot
#     https://quicademy.com/2023/07/17/the-5-best-geospatial-packages-to-use-in-julia/
#     OpenStreetMapXPlot.jl with Makie: https://github.com/JuliaDynamics/Agents.jl/issues/437
#     common geographics datasets such as location of shoreline, rivers and political boundaries https://juliageo.org/GeoDatasets.jl/dev/
#     Using AoG: https://statsforscaredecologists.netlify.app/posts/001_basic_map_julia/
#     using VegaLite: https://www.youtube.com/watch?v=mptWWrScdS4

# From example: https://geo.makie.org/stable/examples/#Italy's-states

# SETME
station_location = CWBProjectSummaryDatasets.dataset("GeoEMStation", "StationInfo")
transform!(station_location, :code => ByRow(station_location_text_shift) => :TextAlign)

# # Load all joint-station data here:

df = DataFrame()
all_trials = Project2024.load_all_trials(PhaseTestEQK())
append!(df, all_trials.t2)
append!(df, all_trials.t3)


# # Load and process Catalog

catalog = CWBProjectSummaryDatasets.dataset("EventMag3", "Catalog")
catalogM4 = filter(row -> row.M_L ≥ 4, catalog)


# Catalog of MagTIP type:
@chain catalogM4 begin
    # select!(Not(:DateTime), :DateTime => :DateTimeStr)
    # transform!(:time => (ByRow(t -> DateTime(t, "yyyy/mm/dd HH:MM"))); renamecols=false) # If the time field is in a correct format, it will automatically load as DateTime in the DataFrame.
    transform!(:time => ByRow(EventTimeJD) => :eventTime)
    transform!(:time => ByRow(t -> datetime2julian(t)) => :dt_julian)
    transform!(:Lat => ByRow(latitude) => :eventLat)
    transform!(:Lon => ByRow(longitude) => :eventLon)
    transform!(:M_L => ByRow(EventMagnitude{RichterMagnitude}) => :eventSize)
    transform!(:Depth => ByRow(Depth) => :eventDepth)
    transform!(Cols(:eventTime, :eventLat, :eventLon, :eventSize, :eventDepth) => ByRow(EventPoint) => :eventPoint)
end


train_yr = Year(3) # this is for earthquake plot # FIXME: is there other way to identify the training period information?

select_from_train(r) = x -> (x >= (first(r) - train_yr) && x <= last(r))


# # Map data

twshp = Shapefile.Table("data/map/COUNTY_MOI_1070516.shp")

twmap = data(twshp) * mapping(:geometry) * visual(
            Choropleth,
            color=:white, # "white" is required to make background clean
            linestyle=:solid,
            strokecolor=:turquoise2,
            strokewidth=0.75
        )

# palletes for `draw` of AlgebraOfGraphic (AoG)
# KEYNOTE:
# - For categorical array, it should be a vector.
# - For continuous array, use cgrad (e.g., `cgrad(:Paired_4)`).
# - AoG may ignore the `colormap` keyword, because AoG may supports multiple colormaps. See the [issue](https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/329).
# - Noted that `palettes` must take a `NamedTuple`. For example in `draw(plt, palettes=(color=cgrad(:Paired_4),))`, `color` is not a keyword argument for some internal function; it specify a dimension of the `plt` that was mapped before (e.g., `plt = ... * mapping(color = :foo_bar)...`).
# - NOTE: `palettes` is deprecated after AoG v0.7. One should use ` scales(Color=(; palette= ...), Layout=(; palette= ...))` instead.


transform!(df, :eventId => CategoricalArray; renamecols=false)





# convert `probabilityTimeStr` to `DateTime`
transform!(df, :probabilityTimeStr => ByRow(t -> DateTime(t, "d-u-y")) => :dt) # FIXME: unify :time, :dt in this script
transform!(df, :eventTimeStr => ByRow(t -> EventTimeJD(DateTime(t, "d-u-y H:M:S"))) => :eventTime)

# Event location
transform!(df, :eventLat => ByRow(x -> latitude(x)); renamecols=false)
transform!(df, :eventLon => ByRow(x -> longitude(x)); renamecols=false)
transform!(df, :eventSize => ByRow(EventMagnitude{RichterMagnitude}); renamecols=false)
transform!(df, :eventDepth => ByRow(Depth); renamecols=false)


# Plot Catalog # WARN: catalog is detached from df
# TODO: Plot events of training and forecasting period separately,
# filter!(:time => select_from_train(extrema(df.dt)), catalogM4) # (Optional) Remove excessive earthquakes.
tkformat = v -> LaTeXString.(string.(round.(v, digits=2)) .* L"^\circ")
magtransform = x -> 7 + (x - 5) * 5 # transform M_L to markersize on the plot
catalogM5 = filter(:M_L => (x -> x ≥ 5.0), catalogM4)

f = with_theme(size=(600, 700)) do
    f = Figure()
    eqkmap = Axis(f[1, 0:11],
        # xticks=119.5:0.5:122.0,
        aspect=DataAspect(),
        xtickformat=tkformat,
        ytickformat=tkformat,
        titlesize=15,
        xlabel="Longitude",
        ylabel="Latitude",
        backgroundcolor=:white,
        limits=((118, 123.6), nothing))

    catalogplot = twmap + data(catalogM5) * visual(Scatter; colormap=:Spectral_4) * mapping(color=:dt_julian => "DateTime") * mapping(markersize=:M_L => magtransform) * mapping(:Lon, :Lat)
    gd = draw!(eqkmap, catalogplot)
    colorbar!(f[0, 1:10], gd; tickformat=(x -> ∘(string, Date, julian2datetime).(x)), label="Event Date", vertical=false)

    scatter!(eqkmap, station_location.Lon, station_location.Lat; marker=:utriangle, color=(:black, 0.9), markersize=11)
    text!(eqkmap, station_location.Lon, station_location.Lat; text=station_location.code,
        align=station_location.TextAlign, offset=GeoEMTIPDemonstration.textoffset.(station_location.TextAlign, 3), fontsize=11)

    MLrefs = catalogM5.M_L |> extrema .|> round |> collect |> v -> (range(v..., step=0.5)) |> collect
    MLrefx = fill(118.2, length(MLrefs))
    MLrefy = range(21.4, 23, length=length(MLrefs)) |> collect

    scatter!(eqkmap, MLrefx, MLrefy, markersize=magtransform.(MLrefs), color=:black)
    text!(eqkmap, MLrefx, MLrefy; text=string.(MLrefs), align=(:left, :center), offset=(10, 0.0), fontsize=13)
    text!(eqkmap, MLrefx[end], MLrefy[end]; text=L"$M_L$", align=(:center, :bottom), offset=(0.0, 15.0), fontsize=20)

    # for row in eachrow((filter(:code => (x -> x in ["KUOL", "HUAL"]), station_location)))
    #     arc!(eqkmap, Point2f(row.Lon, row.Lat), 0.94, -π, π; color=:red)
    #     scatter!(eqkmap, Point2f(row.Lon, row.Lat); marker=:utriangle, color=(:red, 1.0), markersize=11)
    # end
    display(f)
    f
end # TODO: Modify the smallest circle size and scale size, to make ML 5 event apparent.

Makie.save("Catalog_M5_map.png", f)



# # KEYNOTE: We show only cases after 2022 (it is too much to show all)
filter!(row -> row.dt > DateTime(2022, 1, 1), df) # FIXME: Revise this to be not dependent on hard coded Date Time.






# # Convert catalog events to points

# Create ENU points in a relative cartesian coordinate, against

# Reference point: against `enu_ref`:
enu_ref = ArbitraryPoint(minimum(df.eventTime), latitude(23.9740), longitude(120.9798), Depth(0))

transform!(catalogM4, :eventPoint => ByRow(e -> XYZT(e, enu_ref)) => :pointENU)
transform!(df, Cols(:eventTime, :eventLat, :eventLon, :eventDepth) => ByRow((t, lat, lon, d) -> ArbitraryPoint(t, lat, lon, d)) => :eventPoint)
transform!(df, :eventPoint => ByRow(e -> XYZT(e, enu_ref)) => :pointENU)


# Scale the content values by custom units.

uconvert!.(Ref(u"km"), Ref(u"hr12"), df.pointENU)
uconvert!.(Ref(u"km"), Ref(u"hr12"), catalogM4.pointENU)

@assert get_units.(df.pointENU) |> unique |> only == [u"km", u"km", u"km", u"hr12"]
@assert get_units.(catalogM4.pointENU) |> unique |> only == [u"km", u"km", u"km", u"hr12"]


# SETME
r_dbscan = 10
r_kdtree = 30
# for every 10, it means is 10km/120hrs


let # Inspect the discrepancies between ENU's altitude and the original event Depth.
    tmp = select(df, Cols(:eventDepth, :pointENU) => ByRow((a, b) -> abs(abs(a.value) - abs(b.z))) => :DIFF)

    ff = Figure(; size=(2000, 1000))
    ax = Axis(ff[1, 1])
    lines!(ax, 1:nrow(df), -1 .* get_value.(df.eventDepth))
    lines!(ax, 1:nrow(df), get_value.(df.pointENU, :z), linestyle=:dot)

    ax2 = Axis(ff[2, 1])
    lines!(tmp.DIFF)
    ff

    fff = Figure(; size=(800, 800))
    ax3 = Axis(fff[1, 1])
    idperm = sortperm(tmp.DIFF)
    scatter!(ax3, get_value.(df.eventDepth)[idperm], tmp.DIFF[idperm])
    fff


    df[tmp.DIFF.>4u"km", :] |> describe
end

# # Event clustering

# Table of target earthquake
eachevent = groupby(df, :eventId)
EQK = combine(eachevent, :pointENU => first, :eventId => unique; renamecols=false) # unique earthquake events

event_points = [get_values(p) for p in EQK.pointENU]
targetevent_matrix = hcat(event_points...)

# Clusterting by dbscan
dbresult = dbscan(targetevent_matrix, r_dbscan)
insertcols!(EQK, :clusterId => dbresult.assignments)

event2cluster(eventId) = Dict(EQK.eventId .=> EQK.clusterId)[eventId]

transform!(df, :eventId => ByRow(event2cluster) => :clusterId)


# # Find all events in catalog that is near to each cluster center.
cluster_center = combine(groupby(df, :clusterId), :pointENU => centerpoint => :centerPoint)

@assert get_units.(cluster_center.centerPoint) |> unique |> only == [u"km", u"km", u"km", u"hr12"]

catalog_points = [get_values(p, [:x, :y, :z]) for p in catalogM4.pointENU]
cluster_centers = [get_values(p, [:x, :y, :z]) for p in cluster_center.centerPoint]

# Transpose for KDTree
catalog_matrix = hcat(catalog_points...) # size nd (dimension) × np (point). See https://github.com/KristofferC/NearestNeighbors.jl?tab=readme-ov-file#creating-a-tree
cluster_matrix = hcat(cluster_centers...)

# # Build a KDTree for the catalog data
catalog_tree = KDTree(catalog_matrix) # default leafsize is 10
nearby_points = inrange(catalog_tree, cluster_matrix, r_kdtree) # find points of catalog that are in the range of r around cluster center points.

insertcols!(cluster_center, :catalog_idx => nearby_points)

clusterid_to_nearby_event_index = Dict([row.clusterId => row.catalog_idx for row in eachrow(cluster_center)])

# # CHECKPOINT:
# - Find events around, and then filter them with depth < 50 km and time > 180 forecasting days.
# - Refer: https://chatgpt.com/c/66f665fa-05a8-8012-aaa0-cada9b73487c?model=o1-preview
# - https://chatgpt.com/c/66fa0750-7624-8012-8a5e-1118e8c9961a

# FIXME: Is it possible to eliminate the T-lead effect (that may cause probability declining artifact)?

frc_days = Day(173) # FIXME: Temp

disallowmissing!(df)
groupdfs = groupby(df, [:clusterId])
problayout = :trial
# # CHECKPOINT
# dfg1 = groupdfs[5] # [Issue solved] Time series is missing? A: the probabilities are mainly zeroes.

# dfg1 = groupdfs[6] # FIXME: why band that indicate probability low/high looks strange
# FIXME: This cluster is huge. Can I mark non-target earthquakes as other colors?
function eqkprb_plot(dfg1)
    # SETME
    targetscatterargs = (marker=:star5, alpha=0.7, color=:yellow, strokewidth=0.2, strokecolor=:red, markersize=15,)
    nontargetscatterargs = (alpha=0.7, markersize=5,
        color=:yellow,  # :transparent, # (:plum, 0.0), # :slategray4 # :goldenrod4
        strokecolor=(:red, 1.0),
        strokewidth=0.5)


    dfg = deepcopy(dfg1)



    # CHECKPOINT: TIP predictions can be larger than today because of the lead time. However, it is better to filter them out to avoid questioning.
    transform!(dfg, :dt => ByRow(t -> get_value(EventTimeJD(t))) => :tx)
    transform!(dfg, :eventTime => ByRow(get_value) => :evtx)
    @assert eltype(dfg.eventTime) isa Type{<:EventTimeJD}



    lenlayout = length(unique(dfg[!, problayout]))


    dfgc = combine(groupby(dfg, [:prp, :trial, :tx]),
        :tx => unique,
        :probabilityMean => mean => :y,
        :probabilityMean => maximum => :y_up,
        :probabilityMean => minimum => :y_lo,
        :trial => unique,
        :prp => unique;
        renamecols=false
    ) # KEYNOTE: (2024-10-22) probabilityMean is the probability around one grid size, about 4-9 cells that a radius 14.6261 km could cover.
    # See `approxGridSize` in MagTIP-2022.
    visline = visual(Lines) * mapping(:tx => identity => "date", :y => identity => "P")
    visband = visual(Band; alpha=0.15) * mapping(:tx, :y_lo, :y_up)
    probplt = data(dfgc) * (visband + visline) * mapping(layout=problayout) * mapping(color=:prp)



    eqkplts = [data(g) * visual(Scatter; targetscatterargs...) * mapping(:evtx, :eventSize => get_value) for g in groupby(dfg, problayout)] # target event scattered at time-series plot grouped by :trail.


    nontargetidx = clusterid_to_nearby_event_index[only(unique(dfg.clusterId))]
    tmpcatalog = transform(catalogM4, :eventTime => ByRow(get_value) => :evtx)[nontargetidx, :]
    non_target_is_not_empty = !isempty(tmpcatalog)

    if non_target_is_not_empty
        @assert only(unique(get_unit.(dfg.eventTime))) == only(unique(get_unit.(tmpcatalog.eventTime)))
        tmpcls = [
            ((xx0, xx1) = extrema(g.tx); # KEYNOTE: tx is the time stamps of probabilities, whereas evtx is the time stamps of events in the cluster.
            filter(row -> (row.evtx >= xx0 && row.evtx <= xx1), tmpcatalog))
            for (i, g) in enumerate(groupby(dfg, problayout))
        ]

        eqknontargetplts = [(
            (xx0, xx1) = extrema(g.evtx);
            data(tmpcls[i]) * visual(Scatter; nontargetscatterargs...) * mapping(:evtx, :eventSize => get_value))

                            for (i, g) in enumerate(groupby(dfg, problayout))]
    end

    f = Figure()
    # Draw probability plot
    # linecolors = get(ColorSchemes.colorschemes[:grayC25], 0.2:0.05:0.8)# |> reverse
    # linecolors = :matter
    # in palettes: color=linecolors,
    pprob = draw!(f[:, :], probplt, scales(Color=(; palette=Project2024.noredDark2.colors),
        Layout=(; palette=[(i, 1) for i in 1:lenlayout]) # specific layout order. See https://aog.makie.org/stable/gallery/gallery/layout/faceting/#Facet-wrap-with-specified-layout-for-rows-and-cols
        # What is a palette: https://aog.makie.org/stable/gallery/gallery/scales/custom_scales/#custom_scales
    ))

    Label(f[:, 0], "probability around epicenters", tellheight=false, rotation=0.5π)
    legend!(f[end+1, :], pprob; tellwidth=false, tellheight=true, titleposition=:left, orientation=:horizontal)

    # palettes=(; color=CF23.prp.to_color.(1:4))
    # Draw eqk stars on the right axis
    leftaxs = filter(x -> x isa Axis, f.content)
    rightaxs = OkMakieToolkits.twinaxis.(leftaxs; color=:red, other=(; ylabel="event magnitude", ylabelcolor=:red))
    if non_target_is_not_empty
        draw!.(rightaxs, eqknontargetplts)
    end
    draw!.(rightaxs, eqkplts)

    lenax = length(leftaxs)
    for (i, (axleft, axright)) in enumerate(zip(leftaxs, rightaxs))
        for ax in [axleft, axright]
            ax.xticklabelrotation = 0.2π
            datetimeticks!(ax, identity.(dfg.dt), identity.(dfg.tx), Month(1))
            if i != lenax
                ax.xticklabelsvisible[] = false
                ax.xticksvisible[] = false
            end # Leave only the ticks & tick labels of the bottom panel.
        end
    end

    # display(f)
    # Makie.inline!(true)
    # Makie.current_axis!(axleft)
    Makie.update_state_before_display!(f) # this has the same effect of display(f) but without displaying it. It is essential for axes to be correctly linked.

    # xlims!(axright, getlimits(axleft, 1))
    linkxaxes!(f)

    panel_map = f[:, end+1] = GridLayout()

    eventtrange = extrema(dfg.eventTime)
    function dtrangestr(d1, d2)
        if length(unique(eventtrange)) > 1
            return "Events in:\n$(DateTime(d1)) - $(DateTime(d2))"
        else
            return "Event Time: $(DateTime(d1))"
        end
    end

    geotitle = join([
            dtrangestr(eventtrange...)
        ], "; ")
    # Label(panel_map[2, 1], geotitle, tellheight=false, fontsize=15, halign=:right)

    ga = Axis(panel_map[:, :],
        # xticks=119.5:0.5:122.0,
        aspect=DataAspect(),
        xtickformat=tkformat,
        ytickformat=tkformat,
        title=geotitle,
        titlesize=15,
        xlabel="Longitude",
        ylabel="Latitude")
    draw!(ga, twmap)

    epi_plt = data(dfg) * visual(Scatter; targetscatterargs...) * mapping(:eventLon => get_value, :eventLat => get_value)
    if non_target_is_not_empty
        tmpcombined = vcat(tmpcls...) |> unique
        epi_plt2 = data(tmpcombined) * visual(Scatter; nontargetscatterargs...) * mapping(:eventLon => get_value, :eventLat => get_value)
        draw!(ga, epi_plt2)
    end
    # scatter!(ga, get_value.(dfg.eventLon), get_value.(dfg.eventLat))
    draw!(ga, epi_plt) # use AoG to plot epicenter to allow setting scatter markers in `with_theme`.

    scatter!(ga, station_location.Lon, station_location.Lat; marker=:utriangle, color=(:blue, 1.0))
    text!(ga, station_location.Lon, station_location.Lat; text=station_location.code,
        align=station_location.TextAlign, offset=GeoEMTIPDemonstration.textoffset.(station_location.TextAlign, 4), fontsize=15)

    colsize!(f.layout, 1, Relative(0.6))
    colgap!(f.layout, 1, Relative(0.02))
    # good resource: https://juliadatascience.io/makie_layouts

    r = 0.65
    xlims!(ga, extrema(get_value.(dfg.eventLon)) .+ (-r, +r)...)
    ylims!(ga, extrema(get_value.(dfg.eventLat)) .+ (-r, +r)...)

    f
end


# Loaded table preprocessing


for dfg in groupdfs
    with_theme(size=(1000, 700),
        Scatter=(;),
        Lines=(; alpha=1.0, linewidth=1.1), # Band=(; alpha=0.15) it is useless to assign it here.
        Axis=(; backgroundcolor=:white)
    ) do

        f = eqkprb_plot(dfg)
        display(f)
        id = dfg.clusterId |> unique |> only
        (dt0, dt1) = DateTime.(extrema(dfg.eventTime)) .|> (d -> floor(d, Day)) .|> Date .|> string
        # Makie.save(targetdir("Eventid[$id]From[$dt0]To[$dt1].png"), f)
    end
end
