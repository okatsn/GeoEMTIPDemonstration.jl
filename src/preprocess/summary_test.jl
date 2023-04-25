

struct Prep202304 <: Preprocessed
    uniqprp
    uniqfrc
    toindex_prp
    toindex_frc
    table
end

"""
Given `df = CSV.read("summary_test.csv", DataFrame)`, `prep202304!(df)` calculates the following new columns:
- `:FittingDegree`
- `:prp_ind` (for `Makie` plot use) 
- `:frc_ind` (for `Makie` plot use)
"""
function prep202304!(df)
    # using Gadfly: Scale.default_discrete_colors as gadfly_colors
    # uniqcolors_prp = gadfly_colors(length(P.uniqprp))
    # uniqcolors_frc = gadfly_colors(length(P.uniqfrc))


    transform!(df, :HitRatesForecasting => ByRow(x->1-x) => :MissingRateForecasting)
    transform!(df, [:MissingRateForecasting, :AlarmedRateForecasting] => ByRow((x, y) -> 1-x-y) => :FittingDegree)
    uniqprp = string.(unique(df.prp))
    uniqfrc = string.(unique(df.frc))
    toindex_prp = x -> toindex(x, uniqprp)
    toindex_frc = x -> toindex(x, uniqfrc)
    transform!(df, :prp => ByRow(toindex_prp) => :prp_ind)
    transform!(df, :frc => ByRow(toindex_frc) => :frc_ind)

    return Prep202304(uniqprp, uniqfrc, toindex_prp, toindex_frc, df)
end

function Base.show(io::IO, P::Prep202304)
    println(io, "uniqprp:")
    for tag in P.uniqprp
        println("    $tag")
    end
    println(io, "uniqfrc: ")
    for tag in P.uniqfrc
        println("    $tag")
    end
    println(io, "table: a $(nrow(P.table)) by $(ncol(P.table)) table")

    println(io, "function `toindex_prp` for converting string to index.")
    println(io, "function `toindex_frc` for converting string to index.")
end

function dttag2datetime(frctag::AbstractString)
    delim = match(r"(\_|-)", frctag).match
    t1t2 = split(frctag, delim);
    t0, t1 = DateTime.(t1t2, Ref(dateformat"yyyymmdd$(delim)yyyymmdd"))
    return (dt0 = t0, dt1 = t1)
end