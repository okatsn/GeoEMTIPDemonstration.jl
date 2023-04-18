abstract type FittingDegreeBarplot end
# struct FigureMolchan

struct FDB2Panel23mid <: FittingDegreeBarplot 
    grouping
end # see figureplot23a.jl

function figureplot(::Preprocessed, ::FittingDegreeBarplot)
    error("Preprocessing is not matching the figure plot.")
end

function tablegroupselect(P::Preprocessed, FDB::FittingDegreeBarplot)
    group1keys = [k for (k, v) in pairs(FDB.grouping)]
    df = groupby(P.table, group1keys)[FDB.grouping]
    return df
end

