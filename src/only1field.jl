function only1field(d::Dict)
    key = keys(d) |> only
    d[key]
end

function only1key(d::Dict)
    return [v for (k, v) in d if !isempty(k)] |> only
end
