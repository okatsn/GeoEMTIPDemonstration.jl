
mutable struct DateInterval{T<:Dates.AbstractTime}
    edges::Vector{T}
    count::Int
end

"""
Iterable `DataInterval`; returns `(t0, t1)` from `edges` where `(t0, t1) = edges[i], edges[i + 1]` for `i` in `1:length(edges)-1`.
"""
function DateInterval(edges)
    DateInterval(
        edges,
        length(edges) - 1
    )
end

Base.length(DI::DateInterval) = DI.count  # optional; but required if you are going to use `collect`

function Base.iterate(DI::DateInterval, state) # required
    if state > length(DI)
        next = nothing
    else
        t0 = DI.edges[state]
        t1 = DI.edges[state + 1]
        state = state + 1
        next = ((t0, t1), state)
    end

    return next # iterate should returns `next = (item, state)` or `nothing`, where `for` loop terminates when `nothing` is returned.
end

Base.iterate(DI::DateInterval) = Base.iterate(DI, 1) # required


# struct Squares
#     count::Int
# end

# Base.iterate(S::Squares, state=1) = state > S.count ? nothing : (state*state, state+1)
# Base.length(S::Squares) = S.count