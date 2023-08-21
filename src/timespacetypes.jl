abstract type AbstractSpace end

"""
Abstract type `GeneralSpace` are the supertype for all dimension/coordinate specification concrete `struct`s of `ValueUnit`, such as `Longitude`, `Latitude` and `EventTime`.
"""
abstract type GeneralSpace <: AbstractSpace end
abstract type Spatial <: GeneralSpace end
abstract type Temporal <: GeneralSpace end


abstract type GeneralUnit end
abstract type Angular <: GeneralUnit end
abstract type EpochTime <: GeneralUnit end
struct Degree <: Angular end
struct JulianDay <: EpochTime end


"""
`ValueUnit` is a simple mutable concrete structure that holds a `value` and the `unit::GeneralUnit` of the value.
"""
mutable struct ValueUnit
    value
    unit::Type{<:GeneralUnit}
end

get_unit(S::AbstractSpace) = get_unit(S.vu)
get_value(S::AbstractSpace) = get_value(S.vu)
get_unit(vu::ValueUnit) = vu.unit
get_value(vu::ValueUnit) = vu.value

"""
The interface for constructing any concrete type belongs to `GeneralSpace`.

# Example
```jldoctest
Longitude(ValueUnit(1, Degree)) == GeneralSpace(Longitude, 1, Degree)

# output

true
```
"""
function GeneralSpace(t::Type{<:GeneralSpace}, value, unit)
    t(ValueUnit(value, unit))
end

struct Longitude <: Spatial
    vu::ValueUnit
end

Longitude(v, u) = Longitude(ValueUnit(v, u))

struct Latitude <: Spatial
    vu::ValueUnit
end
Latitude(v, u) = Latitude(ValueUnit(v, u))

struct EventTime <: Temporal
    vu::ValueUnit
end
EventTime(v, u) = EventTime(ValueUnit(v, u))

"""
`Distance` is the supertype for all types of "distance" on "GeneralSpace".
- Distance derived from multiple dimensional is beyond the scope of `Distance`.
- Each concrete struct of `GeneralUnit` corresponds to the only concrete struct of `Distance`
"""
abstract type Distance <: AbstractSpace end

# Distance(value, unit::Type{<:Angular}) = AngularDistance(value, unit)
# Distance(value, unit::Type{<:EpochTime}) = EpochDuration(value, unit)

"""
Function `disttype` defines the one-to-one correspondance between `U::GeneralUnit` and `T::Distance`; it returns the type/constructor `T`.

List:
- `disttype(::Type{<:Angular}) = AngularDistance`
- `disttype(::Type{<:EpochTime}) = EpochDuration`

"""
disttype(::Type{<:Angular}) = AngularDistance
disttype(::Type{<:EpochTime}) = EpochDuration

"""
`Distance(value, unit)` construct a concrete struct of `Distance`.

# Example

```jldoctest
Distance(5, Degree) == AngularDistance(ValueUnit(5, Degree))

# output

true


```

# Add a new type `<: Distance`

"Constructor" `Distance` relies on `disttype`. Following the following steps to add new utilities:

1. ```
   struct NewDistance <: Distance
       vu::ValueUnit
   end
   ```
2. `struct NewDistUnit <: GeneralUnitOrOneOfItsAbstractType end`
3. `distype(::Type{<:GeneralUnitOrOneOfItsAbstractType}) = NewDistance`


See also: `disttype`.
"""
function Distance(value, unit)
    t = disttype(unit)
    t(ValueUnit(value, unit))
end

struct AngularDistance <: Distance
    vu::ValueUnit
    # function AngularDistance(value, unit::Type{<:Angular})
    #     vu = ValueUnit(value, unit)
    #     new(vu)
    # end
end
AngularDistance(v, u) = AngularDistance(ValueUnit(v, u))

struct EpochDuration <: Distance
    vu::ValueUnit
    # function EpochDuration(value, unit::Type{<:EpochTime})
    #     vu = ValueUnit(value, unit)
    #     new(vu)
    # end
end
EpochDuration(v, u) = EpochDuration(ValueUnit(v, u))



struct UnitMismatch <: Exception end
Base.showerror(io::IO, e::UnitMismatch) = print(io, "Unit mistach.")



"""
Check if two objects of `ValueUnit` has the same unit.
"""
function sameunit(gs1, gs2)
    _sametype(get_unit(gs1), get_unit(gs2))
end

_sametype(a::Type{T}, b::Type{T}) where {T<:GeneralUnit} = true
_sametype(a, b) = throw(UnitMismatch())

function Base.isless(gs1::T, gs2::T) where {T<:AbstractSpace}
    sameunit(gs1, gs2)
    isless(get_value(gs1), get_value(gs2)) # This makes `extrema`, `maximum` and `minimum` works with `GeneralSpace`.
end


function Base.:-(gs1::T, gs2::T) where {T<:GeneralSpace}
    sameunit(gs1, gs2)
    Distance(get_value(gs1) - get_value(gs2), get_unit(gs1)) # extend `-` makes `diff` works with `GeneralSpace`
end
# CHECKPOINT

Base.:+(gs1::GeneralSpace, gs2::GeneralSpace) = get_value(gs1) + get_value(gs2)



function Base.:(==)(as1::AbstractSpace, as2::AbstractSpace)
    isequal(get_unit(as1), get_unit(as2)) && isequal(get_value(as1), get_value(as2))
end


function Base.isapprox(as1::AbstractSpace, as2::AbstractSpace)
    isequal(get_unit(as1), get_unit(as2)) && isapprox(get_value(as1), get_value(as2))
end
