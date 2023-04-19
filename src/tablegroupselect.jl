function tablegroupselect(P::Preprocessed; kwargs...)
    group1keys = [k for (k, v) in pairs(kwargs)]
    df = groupby(P.table, group1keys)[kwargs]
    return df
end

