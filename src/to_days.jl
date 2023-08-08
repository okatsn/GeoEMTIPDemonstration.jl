
function to_days(v::Vector)
    ds = 0
    for vi in v
        ds += to_days(vi)
    end
    ds
end

onedayinsec = 86400

"""
Given `p::Period`, `to_days(p)` returns `Real` number of the value in the unit of day.
"""
to_days(p::Week) = p.value * 7
to_days(p::Year) = p.value * 365
to_days(p::Hour) = p.value / 24
to_days(p::Minute) = p.value / 1440
to_days(p::Second) = p.value / onedayinsec
to_days(p::Millisecond) = p.value * 0.001 / onedayinsec
to_days(p::Day) = p.value

"""
`to_days(p::Dates.CompoundPeriod)` returns the summation of `CompoundPeriod`.
"""
to_days(p::Dates.CompoundPeriod) = to_days(p.periods) # dispatch to to_days(v::Vector)
