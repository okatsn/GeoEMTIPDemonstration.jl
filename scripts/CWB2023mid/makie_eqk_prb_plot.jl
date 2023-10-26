using DataFrames, CSV
using AlgebraOfGraphics
# using CairoMakie
using WGLMakie
using ColorSchemes
using Chain
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
using Shapefile
using CategoricalArrays
# clustering
using Clustering
using EventSpaceAlgebra


# !!! note Map plot
#     https://quicademy.com/2023/07/17/the-5-best-geospatial-packages-to-use-in-julia/
#     OpenStreetMapXPlot.jl with Makie: https://github.com/JuliaDynamics/Agents.jl/issues/437
#     common geographics datasets such as location of shoreline, rivers and political boundaries https://juliageo.org/GeoDatasets.jl/dev/
#     Using AoG: https://statsforscaredecologists.netlify.app/posts/001_basic_map_julia/
#     using VegaLite: https://www.youtube.com/watch?v=mptWWrScdS4

# From example: https://geo.makie.org/stable/examples/#Italy's-states

# SETME
df_ge = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_GE_3yr_180d_500md_2023A10_compat_1")
df_gm = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_GM_3yr_180d_500md_2023A10_compat_1")
df_mix = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTestEQK_MIX_3yr_180d_500md_2023A10_compat_1")
station_location = CWBProjectSummaryDatasets.dataset("GeoEMStation", "StationInfo")
twshp = Shapefile.Table("data/map/COUNTY_MOI_1070516.shp")

# palletes for `draw` of AlgebraOfGraphic (AoG)
# KEYNOTE:
# - For categorical array, it should be a vector.
# - For continuous array, use cgrad (e.g., `cgrad(:Paired_4)`).
# - AoG may ignore the `colormap` keyword, because AoG may supports multiple colormaps. See the [issue](https://github.com/MakieOrg/AlgebraOfGraphics.jl/issues/329).
# - Noted that `palettes` must take a `NamedTuple`. For example in `draw(plt, palettes=(color=cgrad(:Paired_4),))`, `color` is not a keyword argument for some internal function; it specify a dimension of the `plt` that was mapped before (e.g., `plt = ... * mapping(color = :foo_bar)...`).




# Merge DataFrame

tagdfs = Dict(
    "GE" => df_ge,
    "GM" => df_gm,
    "MIX" => df_mix
);

for (tag, df) in tagdfs
    insertcols!(df, :trial => tag)
end

df = vcat(df_ge, df_gm, df_mix)

# Categorize :eventId
# - This is critical for AlgebraOfGraphics to give a plot of lines where each line is a unique eventId.
# - Try the followings to figure out:
#   ```
#   tmp = append!(DataFrame(x=1:10, y=randn(10), type1=UInt(1), type2="a"), DataFrame(x=1:10, y=randn(10), type1=UInt(2), type2="b"))
#   data(tmp) * visual(Lines, colormap=:blues) * mapping(:x, :y) * mapping(color=:type1) |> draw
#   data(tmp) * visual(Lines, colormap=:blues) * mapping(:x, :y) * mapping(color=:type2) |> draw
#   ```
transform!(df, :eventId => CategoricalArray; renamecols=false)




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

groupdfs = groupby(df, [:trial, :clusterId])

lenprp = length(unique(df.prp))

# dfg1 = groupdfs[15]
function eqkprb_plot(dfg1)
    dfg = deepcopy(dfg1)
    transform!(dfg, :dt => ByRow(datetime2julian) => :x)
    transform!(dfg, :eventTime => ByRow(get_value) => :evtx)

    probplt = data(dfg) * visual(Lines) * mapping(:x => identity => "date", :probabilityMean => identity => "probability around epicenters") * mapping(layout=:prp)
    probplt *= mapping(color=:eventId)

    eqkplts = [data(g) * visual(Scatter) * mapping(:evtx, :eventSize) for g in groupby(dfg, :prp)]

    f = Figure()
    # Draw probability plot
    # linecolors = get(ColorSchemes.colorschemes[:grayC25], 0.2:0.05:0.8)# |> reverse
    # linecolors = :matter
    # in palettes: color=linecolors,
    draw!(f[:, :], probplt; palettes=(;
        color=get(ColorSchemes.colorschemes[:grayC25], [0.5]),
        layout=[(i, 1) for i in 1:lenprp] # specific layout order. See https://aog.makie.org/stable/gallery/gallery/layout/faceting/#Facet-wrap-with-specified-layout-for-rows-and-cols
    ))

    # Draw eqk stars on the right axis
    leftaxs = filter(x -> x isa Axis, f.content)
    rightaxs = twinaxis.(leftaxs; color=:red, other=(; ylabel="event magnitude", ylabelcolor=:red))
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
    tkformat = v -> LaTeXString.(string.(v) .* L"^\circ")

    twmap = data(twshp) * mapping(:geometry) * visual(
                Choropleth,
                color=:white, # "white" is required to make background clean
                linestyle=:solid,
                strokecolor=:turquoise2,
                strokewidth=0.75
            )
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
        align=station_location.TextAlign, offset=textoffset.(station_location.TextAlign, 4), fontsize=15)

    colsize!(f.layout, 1, Relative(0.6))
    colgap!(f.layout, 1, Relative(0.02))
    # good resource: https://juliadatascience.io/makie_layouts

    r = 0.65
    xlims!(extrema(get_value.(dfg.eventLon)) .+ (-r, +r)...)
    ylims!(extrema(get_value.(dfg.eventLat)) .+ (-r, +r)...)
    f
end


# Loaded table preprocessing
transform!(station_location, :code => ByRow(station_location_text_shift) => :TextAlign)


for dfg in groupdfs[1:1]
    with_theme(resolution=(1000, 700), Scatter=(marker=:star5, markersize=15, alpha=0.7, color=:red), Lines=(; alpha=1.0, linewidth=0.7)) do
        f = eqkprb_plot(dfg)
        display(f)
        trial = dfg.trial |> unique |> only
        id = dfg.clusterId |> unique |> only
        Makie.save("temp/trial[$trial]eventid[$id].png", f)
    end
end
