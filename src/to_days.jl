function to_days(v::Vector)
    ds = Day(0)
    for vi in v
        ds += to_days(vi)
    end
    ds
end


to_days(p::Week) = Day(p.value * 7)
to_days(p::Year) = Day(p.value * 365)
to_days(p::Day) = p

to_days(p::Dates.CompoundPeriod) = to_days(p.periods) # dispatch to to_days(v::Vector)