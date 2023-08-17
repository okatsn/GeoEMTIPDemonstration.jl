abstract type GeneralSpace end
abstract type Spatial <: GeneralSpace end
abstract type Temporal <: GeneralSpace end


"""
# Example
```julia
Longitude(1, Degree) == GeneralSpace(Longitude, 1, Degree)
```
"""
function GeneralSpace(t::Type{<:GeneralSpace}, value, unit)
    t(value, unit)
end

struct Longitude <: Spatial
    value
    unit
end

struct Latitude <: Spatial
    value
    unit
end

struct EventTime <: Temporal
    value
    unit
end

abstract type Distanceness <: GeneralSpace end
abstract type Distance <: Distanceness end
abstract type Location <: Distanceness end

abstract type GeneralUnit end
abstract type Angular <: GeneralUnit end
abstract type GeneralTime <: GeneralUnit end
struct Degree <: Angular end
struct JulianDay <: GeneralTime end

Distance(value, unit::Type{<:Angular}) = AngularDistance(value, unit)
Distance(value, unit::Type{<:GeneralTime}) = TimeDuration(value, unit)



struct AngularDistance <: Distance
    value
    unit
end

struct TimeDuration <: Distance
    value
    unit
end




struct UnitMismatch <: Exception end
Base.showerror(io::IO, e::UnitMismatch) = print(io, "Unit mistach.")


"""
Check if two objects of `GeneralSpace` has the same unit.
"""
function sameunit(gs1::GeneralSpace, gs2::GeneralSpace)
    _sametype(gs1.unit, gs2.unit)
end

_sametype(a::Type{T}, b::Type{T}) where {T<:GeneralUnit} = true
_sametype(a, b) = throw(UnitMismatch())

function Base.isless(gs1::T, gs2::T) where {T<:GeneralSpace}
    sameunit(gs1, gs2)
    isless(gs1.value, gs2.value) # This makes `extrema`, `maximum` and `minimum` works with `GeneralSpace`.
end

function Base.:-(gs1::T, gs2::T) where {T<:GeneralSpace}
    sameunit(gs1, gs2)
    Distance(gs1.value - gs2.value, gs1.unit) # extend `-` makes `diff` works with `GeneralSpace`
end
# CHECKPOINT

Base.:+(gs1::GeneralSpace, gs2::GeneralSpace) = gs1.value + gs2.value
