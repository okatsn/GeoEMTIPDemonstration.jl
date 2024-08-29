"""
A dictionary to cache computed binomial coefficients.
"""
const binomial_cache = Dict{Tuple{Float64,Int},Vector{Float64}}()


"""
`getdcb(α, neq)` calculate alarmed rate and hit rate for the given complementary confidence level `α` and number of earthquakes `neq`.

`getdcb` applies `big` if `neq` is larger than keyword argument `applybig` (40 by default).

Since julia is slow in handling `BigInt`, `getdcb` by default looks into dictionary `binomial_cache` first if there are cached results already; this behavior is controlled by `cache=true` keyword argument.
"""
function getdcb(α, neq; cache=true, applybig=40)
    if neq > applybig
        neq = big(neq)  # Use `big(neq)` to prevent stack overflow error.
    end

    if cache && haskey(binomial_cache, (α, neq))
        return binomial_cache[(α, neq)]
    end

    (alarmed, missed) = molchancb(neq, α)
    fdcb = 1.0 .- alarmed .- missed

    if cache
        binomial_cache[(α, neq)] = fdcb
    end
    return fdcb
end
