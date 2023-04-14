function only1field(d::Dict)
    key = keys(d) |> only
    d[key]
end