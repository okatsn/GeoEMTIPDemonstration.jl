@testset "getdcb.jl" begin
    getdcb(0.015, 20; cache=true)
    @test getdcb(0.015, 20; cache=true) == getdcb(0.015, 20; cache=false)
    @test haskey(GeoEMTIPDemonstration.binomial_cache, (0.015, 20))
    getdcb(0.01, 8; cache=false)
    @test !haskey(GeoEMTIPDemonstration.binomial_cache, (0.01, 8))

    a117 = getdcb(0.32, big(117))
    @test GeoEMTIPDemonstration.binomial_cache[(0.32, big(117))] == a117


end
