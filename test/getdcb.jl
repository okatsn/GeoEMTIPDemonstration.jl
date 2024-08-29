@testset "getdcb.jl" begin
    getdcb(0.32, big(117))
    getdcb(0.32, big(200))
    getdcb(0.01, 8)
    getdcb(0.015, 20)
end
