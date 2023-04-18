abstract type MidtermFigure end
# struct FigureMolchan







struct Prep202304
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

