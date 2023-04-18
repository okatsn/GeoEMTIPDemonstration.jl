module GeoEMTIPDemonstration

# Write your package code here.

using DrWatson
include("projectdir.jl")
export dir_cwb2023mid

include("only1field.jl")
export only1field

using Dates
include("dateinterval.jl")
export DateInterval

include("toindex.jl")

using DataFrames
include("preprocess/summary_test.jl")
export prep202304!

using Gadfly: Scale.default_discrete_colors as gadfly_colors
using CairoMakie
include("figures/figureplot.jl")
include("figures/figureplot23a.jl")
export FDB2Panel23mid, figureplot
end
