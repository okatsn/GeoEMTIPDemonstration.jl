using DataFrames, CSV
using AlgebraOfGraphics
using WGLMakie
using ColorSchemes
using LaTeXStrings
using CWBProjectSummaryDatasets
using GeoEMTIPDemonstration
using Shapefile
using EventSpaceAlgebra

station_location = CWBProjectSummaryDatasets.dataset("GeoEMStation", "StationInfo")
twshp = Shapefile.Table("data/map/COUNTY_MOI_1070516.shp")
twmap = data(twshp) * mapping(:geometry) * visual(
            Choropleth,
            color=:white, # "white" is required to make background clean
            linestyle=:solid,
            strokecolor=:turquoise2,
            strokewidth=0.75
        )

f = Figure(; resolution=(800, 600))

ga = Axis(f[:, :],
    # xticks=119.5:0.5:122.0,
    aspect=DataAspect(),
    xtickformat=v -> LaTeXString.(string.(v) .* L"^\circ E"),
    ytickformat=v -> LaTeXString.(string.(v) .* L"^\circ N"),
    xlabel="Longitude",
    ylabel="Latitude")
draw!(ga, twmap)


scatter!(ga, station_location.Lon, station_location.Lat; marker=:utriangle, color=(:blue, 1.0))

transform!(station_location, :code => ByRow(TWGEMSDatasets.station_location_text_shift) => :TextAlign)

text!(ga, station_location.Lon, station_location.Lat; text=station_location.code,
    align=station_location.TextAlign, offset=TWGEMSDatasets.textoffset.(station_location.TextAlign, 4), fontsize=12)
f
