DCB = Dict([α => Dict([neq => molchancb(big(neq), α) for neq in uniqNEQ]) for α in [0.05, 0.1, 0.32]])
# Expand this dictionary for your needs.

getalms(α, neq) = DCB[α][neq]

function getdcb(α, neq)
    (alarmed, missed) = try
        (alarmed, missed) = getalms(α, neq) # Looks into a dictionary so it will be much faster
    catch
        (alarmed, missed) = molchancb(neq, α) # Use `big(neq)` to prevent stack overflow error.
    end
    fdcb = 1.0 .- alarmed .- missed
end
