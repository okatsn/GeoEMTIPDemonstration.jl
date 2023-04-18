
"""
`toindex(str::AbstractString, uniqlabels::Vector{<:AbstractString})` returns the only index of `uniqlabels` occurring in `str`.
"""
toindex(str::AbstractString, uniqlabels::Vector{<:AbstractString}) = only(findall(occursin.(str, uniqlabels)))
