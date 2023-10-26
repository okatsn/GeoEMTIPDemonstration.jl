stloc_shift = Dict(
    "MS" => (:right, :bottom),
    "TW" => (:right, :top),
    "TT" => (:left, :bottom),
    "YL" => (:left, :bottom),
    "HC" => (:left, :bottom),
    "HL" => (:right, :center),
    "PT" => (:left, :bottom),
    "YH" => (:left, :bottom),
    "SL" => (:left, :bottom),
    "LY" => (:center, :bottom),
    "NC" => (:left, :bottom),
    "KM" => (:left, :bottom),
    "CS" => (:left, :bottom),
    "MT" => (:left, :bottom),
    "LN" => (:left, :bottom),
    "ZB" => (:right, :bottom),
    "XC" => (:right, :top),
    "SM" => (:right, :bottom),
    "CN" => (:center, :bottom),
    "KUOL" => (:left, :bottom),
    "HUAL" => (:right, :top),
    "TOCH" => (:left, :center),
    "ENAN" => (:left, :bottom),
    "SIHU" => (:left, :bottom),
    "HERM" => (:left, :bottom),
    "CHCH" => (:left, :bottom),
    "DAHU" => (:left, :bottom),
    "KAOH" => (:right, :bottom),
    "PULI" => (:left, :center),
    "SHRL" => (:right, :bottom),
    "SHCH" => (:left, :bottom),
    "FENL" => (:left, :bottom),
    "YULI" => (:right, :bottom),
    "RUEY" => (:left, :bottom),
    "LIOQ" => (:left, :bottom),
    "LISH" => (:left, :bottom),
    "DABA" => (:left, :bottom),
    "WANL" => (:center, :top),
    "FENG" => (:right, :bottom),
    "HUZS" => (:left, :bottom),
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
