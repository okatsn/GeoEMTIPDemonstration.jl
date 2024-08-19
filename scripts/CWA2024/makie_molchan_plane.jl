# https://juliadatascience.io/recipe_df
using Chain
using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
using Printf
import NaNMath: mean as nanmean
# using Revise # using Revise through VSCode settings
using CWBProjectSummaryDatasets
using OkMakieToolkits
using OkDataFrameTools
using GeoEMTIPDemonstration
using MolchanCB
using Dates

df23 = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTest_MIX_3yr_180d_500md_2023A10")

df24 = CWBProjectSummaryDatasets.dataset("Summary_JointStation-J28-1qx", "PhaseTest_3yr_173d_J28")


# # Keep only data where frc and prp labels matching the other dataset
# (otherwise, the comparison has no meaning)

function filter_intersect(nt)
    in(nt.prp, intersect(Set(df23.prp), Set(df24.prp))) &&
        in(nt.frc, intersect(Set(df23.frc), Set(df24.frc)))
end

filter!(AsTable(:) => filter_intersect, df23)
filter!(AsTable(:) => filter_intersect, df24)




# # Calculate NEQ summary table
neq_summary(df) = @chain df begin
    groupby([:prp, :frc])
    combine(Cols(r"NEQ") .=> (x -> only(unique(extrema(x)))); renamecols=false)
    groupby([:frc])
    combine([:NEQ_min, :NEQ_max] => ((a, b) -> extrema(vcat(a, b))) => :NEQ_range)
end


neq_summary(df23)
neq_summary(df24)
