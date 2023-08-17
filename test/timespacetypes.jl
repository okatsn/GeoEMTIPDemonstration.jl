@testset "timespacetypes.jl" begin
    @test GeoEMTIPDemonstration.sameunit(
        Longitude(1, Degree), Longitude(2, Degree)
    )
    @test GeoEMTIPDemonstration.sameunit(
        Longitude(1, Degree), Latitude(2, Degree)
    )
    @test_throws GeoEMTIPDemonstration.UnitMismatch GeoEMTIPDemonstration.sameunit(
        EventTime(1, JulianDay), Latitude(2, Degree)
    )
    @test isequal(
        Longitude(121.33, Degree) - Longitude(110.33, Degree), AngularDistance(11.33, Degree)
    )
end
