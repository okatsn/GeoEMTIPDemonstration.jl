abstract type FigureByGroup end
# struct FigureMolchan

struct StackedBarplot23a <: FigureByGroup 
    grouping
end # see figureplot23a.jl

function figureplot(::Preprocessed, ::FigureByGroup)
    error("Preprocessing is not matching the figure plot.")
end

function tablegroupselect(P::Preprocessed, FDB::FigureByGroup)
    group1keys = [k for (k, v) in pairs(FDB.grouping)]
    df = groupby(P.table, group1keys)[FDB.grouping]
    return df
end

