stloc_shift = Dict(
    "MS" => (:left, :center),
    "TW" => (:right, :center),
    "TT" => (:left, :center),
    "YL" => (:center, :bottom),
    "HC" => (:left, :center),
    "HL" => (:right, :center),
    "PT" => (:left, :center),
    "YH" => (:left, :bottom),
    "SL" => (:left, :center),
    "LY" => (:right, :center),
    "NC" => (:left, :center),
    "KM" => (:left, :bottom),
    "CS" => (:left, :center),
    "MT" => (:left, :bottom),
    "LN" => (:left, :bottom),
    "ZB" => (:left, :top),
    "XC" => (:right, :top),
    "SM" => (:right, :center),
    "CN" => (:center, :bottom),
    "KUOL" => (:right, :center),
    "HUAL" => (:right, :center),
    "TOCH" => (:left, :center),
    "ENAN" => (:left, :center),
    "SIHU" => (:right, :center),
    "HERM" => (:right, :center),
    "CHCH" => (:right, :center),
    "DAHU" => (:center, :bottom),
    "KAOH" => (:right, :bottom),
    "PULI" => (:left, :center),
    "SHRL" => (:right, :center),
    "SHCH" => (:left, :bottom),
    "FENL" => (:left, :center),
    "YULI" => (:left, :center),
    "RUEY" => (:left, :center),
    "LIOQ" => (:left, :center),
    "LISH" => (:left, :bottom),
    "DABA" => (:left, :bottom),
    "WANL" => (:right, :top),
    "FENG" => (:right, :center),
    "HUZS" => (:left, :center),
)

station_location_text_shift(code) = stloc_shift[code]

function textoffset(s::Symbol, f)
    if s in [:left, :bottom]
        return +1.0 * f
    end

    if s in [:right, :top]
        return -1.0 * f
    end

    if s in [:baseline]
        return +1.1 * f
    end

    if s in [:center]
        return 0.0 * f
    end
    error("`$s` is unsupported.")
end

"""
# Example: Text `offset` according to `align`
```
station_location = DataFrame(
    Lon = [112.1, 112.3, 112.5],
    Lat = [21.1, 23.3, 25.5],
    code = ["YL", "AA", "KUOL"],
    TextAlign = [
        (:center, :top),
        (:right, :bottom),
        (:left, :bottom),
    ]
)
text(station_location.Lon, station_location.Lat;
    text=station_location.code,
    align=station_location.TextAlign,
    offset = textoffset.(station_location.TextAlign, 4),
    fontsize=15
    )
```
"""
function textoffset(t::Tuple{Symbol,Symbol}, f)
    return textoffset(t[1], f), textoffset(t[2], f)
end
