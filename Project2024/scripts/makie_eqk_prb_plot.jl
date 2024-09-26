using DataFrames, CSV
using AlgebraOfGraphics
# import CairoMakie
using WGLMakie
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
for df0 in Project2024.load_all_trials(PhaseTestEQK())
    append!(df, df0; cols=:intersect)
end

# convert `probabilityTimeStr` to `DateTime`
transform!(df, :probabilityTimeStr => ByRow(t -> DateTime(t, "d-u-y")) => :dt)
transform!(df, :eventTimeStr => ByRow(t -> DateTime(t, "d-u-y H:M:S")) => :eventTime)
transform!(df, :eventTime => ByRow(x -> EventTime(datetime2julian(x), JulianDay)); renamecols=false)




# # Load and process Catalog

catalog = CWBProjectSummaryDatasets.dataset("EventMag4", "Catalog")

# Catalog of MagTIP type:
@chain catalog begin
    select!(Not(:DateTime), :DateTime => :DateTimeStr)
    transform!(:time => (ByRow(t -> DateTime(t, "yyyy/mm/dd HH:MM"))); renamecols=false)
end

train_yr = Year(3) # this is for earthquake plot # FIXME: is there other way to identify the training period information?

inrange(r) = x -> (x >= (first(r) - train_yr) && x <= last(r))
filter!(:time => inrange(extrema(df.dt)), catalog) # (Optional) Remove excessive earthquakes.
filter!(:Mag => (x -> x ≥ 5.0), catalog)

transform!(catalog, :time => ByRow(t -> datetime2julian(t)) => :dt_julian)

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

# Categorize :eventId
# - `eventId` is the hash of eventTimeStr, eventSize, eventLat, ...; see `preprocess_phase_test_eqk.jl` in CWBProjectSummaryDatasets.
# - This is critical for AlgebraOfGraphics to give a plot of lines where each line is a unique eventId.
# - Try the followings to figure out:
#   ```
#   tmp = append!(DataFrame(x=1:10, y=randn(10), type1=UInt(1), type2="a"), DataFrame(x=1:10, y=randn(10), type1=UInt(2), type2="b"))
#   data(tmp) * visual(Lines, colormap=:blues) * mapping(:x, :y) * mapping(color=:type1) |> draw
#   data(tmp) * visual(Lines, colormap=:blues) * mapping(:x, :y) * mapping(color=:type2) |> draw
#   ```
transform!(df, :eventId => CategoricalArray; renamecols=false)





# Plot Catalog # WARN: catalog is detached from df
# TODO: Plot events of training and forecasting period separately,

tkformat = v -> LaTeXString.(string.(round.(v, digits=2)) .* L"^\circ")
magtransform = x -> 7 + (x - 5) * 5 # transform Mag to markersize on the plot

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

    catalogplot = twmap + data(catalog) * visual(Scatter; colormap=:Spectral_4) * mapping(color=:dt_julian => "DateTime") * mapping(markersize=:Mag => magtransform) * mapping(:Lon, :Lat)
    gd = draw!(eqkmap, catalogplot)
    colorbar!(f[0, 1:10], gd; tickformat=(x -> ∘(string, Date, julian2datetime).(x)), label="Event Date", vertical=false)

    scatter!(eqkmap, station_location.Lon, station_location.Lat; marker=:utriangle, color=(:black, 0.9), markersize=11)
    text!(eqkmap, station_location.Lon, station_location.Lat; text=station_location.code,
        align=station_location.TextAlign, offset=GeoEMTIPDemonstration.textoffset.(station_location.TextAlign, 3), fontsize=11)

    MLrefs = catalog.Mag |> extrema .|> round |> collect |> v -> (range(v..., step=0.5)) |> collect
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
filter!(row -> DateTime(row.eventTime) > DateTime(2022, 1, 1), df) # FIXME: Revise this to be not dependent on hard coded Date Time.



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




# FIXME: Is it possible to eliminate the T-lead effect (that may cause probability declining artifact)?

frc_days = Day(173) # FIXME: Temp

groupdfs = groupby(df, [:clusterId])
problayout = :trial
# dfg1 = groupdfs[4]
function eqkprb_plot(dfg1)
    dfg = deepcopy(dfg1)

    tmp = @chain groupby(dfg, :eventId) begin
        combine(:dt => extrema => :t0t1)
        transform!(:t0t1 => ByRow(t -> minimum([t[1] + frc_days, t[2]])) => :frcend)
    end

    # Dictionary for the end day of frc
    d_frcend = Dict(tmp.eventId .=> tmp.frcend)

    # CHECKPOINT: TIP predictions can be larger than today because of the lead time. However, it is better to filter them out to avoid questioning.

    transform!(dfg, :dt => ByRow(datetime2julian) => :x)
    transform!(dfg, :eventTime => ByRow(get_value) => :evtx)



    lenlayout = length(unique(dfg[!, problayout]))


    dfgc = combine(groupby(dfg, [:prp, :trial, :x]),
        :x => unique,
        :probabilityMean => mean => :y,
        :probabilityMean => maximum => :y_up,
        :probabilityMean => minimum => :y_lo,
        :trial => unique,
        :prp => unique;
        renamecols=false
    )
    visline = visual(Lines) * mapping(:x => identity => "date", :y => identity => "P")
    visband = visual(Band; alpha=0.15) * mapping(:x, :y_lo, :y_up)
    probplt = data(dfgc) * (visband + visline) * mapping(layout=problayout) * mapping(color=:prp)



    eqkplts = [data(g) * visual(Scatter) * mapping(:evtx, :eventSize) for g in groupby(dfg, problayout)]


    f = Figure()
    # Draw probability plot
    # linecolors = get(ColorSchemes.colorschemes[:grayC25], 0.2:0.05:0.8)# |> reverse
    # linecolors = :matter
    # in palettes: color=linecolors,
    pprob = draw!(f[:, :], probplt, scales(Color=(; palette=WGLMakie.categorical_colors(:Set1_4, 4)),
        Layout=(; palette=[(i, 1) for i in 1:lenlayout]) # specific layout order. See https://aog.makie.org/stable/gallery/gallery/layout/faceting/#Facet-wrap-with-specified-layout-for-rows-and-cols
        # What is a palette: https://aog.makie.org/stable/gallery/gallery/scales/custom_scales/#custom_scales
    ))

    Label(f[:, 0], "probability around epicenters", tellheight=false, rotation=0.5π)
    legend!(f[end+1, :], pprob; tellwidth=false, tellheight=true, titleposition=:left, orientation=:horizontal)

    # palettes=(; color=CF23.prp.to_color.(1:4))
    # Draw eqk stars on the right axis
    leftaxs = filter(x -> x isa Axis, f.content)
    rightaxs = OkMakieToolkits.twinaxis.(leftaxs; color=:red, other=(; ylabel="event magnitude", ylabelcolor=:red))
    draw!.(rightaxs, eqkplts)

    lenax = length(leftaxs)
    for (i, (axleft, axright)) in enumerate(zip(leftaxs, rightaxs))
        for ax in [axleft, axright]
            ax.xticklabelrotation = 0.2π
            datetimeticks!(ax, identity.(dfg.dt), identity.(dfg.x), Month(1))
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

    epi_plt = data(dfg) * visual(Scatter) * mapping(:eventLon => get_value, :eventLat => get_value)
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
        Scatter=(marker=:star5, markersize=15, alpha=0.7, color=:yellow, strokewidth=0.2, strokecolor=:red),
        Lines=(; alpha=1.0, linewidth=1.1), # Band=(; alpha=0.15) it is useless to assign it here.
    ) do

        f = eqkprb_plot(dfg)
        display(f)
        id = dfg.clusterId |> unique |> only
        (dt0, dt1) = DateTime.(extrema(dfg.eventTime)) .|> (d -> floor(d, Day)) .|> Date .|> string
        Makie.save(targetdir("Eventid[$id]From[$dt0]To[$dt1].png"), f)
    end
end
