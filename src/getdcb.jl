uniqNEQ = 0:10
DCB = Dict([α => Dict([neq => molchancb(big(neq), α) for neq in uniqNEQ]) for α in [0.05, 0.1, 0.32]])
# Expand this dictionary for your needs.
"""
A dictionary function for efficiently obtain Molchan confidence boundary.
"""
getalms(α, neq) = DCB[α][neq]


"""
`getdcb(α, neq)` calculate alarmed rate and hit rate for the given complementary confidence level `α` and number of earthquakes `neq`.
Use `big(neq)` instead if `neq > 20`.

Since `molchancb(N, alpha)` for N > 20 is slow because julia is slow in handling BigInt, `getdcb` looks into dictionary first if there are existing results already, and otherwise use `molchancb`.
"""
function getdcb(α, neq)
    (alarmed, missed) = try
        (alarmed, missed) = getalms(α, neq) # Looks into a dictionary so it will be much faster
    catch
        (alarmed, missed) = molchancb(neq, α) # Use `big(neq)` to prevent stack overflow error.
    end
    fdcb = 1.0 .- alarmed .- missed
end
