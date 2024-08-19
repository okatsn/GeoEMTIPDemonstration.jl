
"""
`toindex(str::AbstractString, uniqlabels::Vector{<:AbstractString})` returns the only index of `uniqlabels` exactly matched by `str`.
"""
toindex(str::AbstractString, uniqlabels::Vector{<:AbstractString}) = only(findall(isequal.(str, uniqlabels)))
