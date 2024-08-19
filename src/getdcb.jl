function getdcb(α, neq)
    (alarmed, missed) = try
        (alarmed, missed) = getalms(α, neq) # fitting degree
    catch
        (alarmed, missed) = molchancb(neq, α)
    end
    fdcb = 1.0 .- alarmed .- missed
end
