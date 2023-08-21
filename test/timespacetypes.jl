@testset "timespacetypes.jl" begin
    # `sameunit` returns true for any arbitrary two concrete construct of `AbstractSpace`.
    @test GeoEMTIPDemonstration.sameunit(
        Longitude(1, Degree), Longitude(2, Degree)
    )
    @test GeoEMTIPDemonstration.sameunit(
        Longitude(1, Degree), Latitude(2, Degree)
    )
    @test GeoEMTIPDemonstration.sameunit(
        Longitude(1, Degree), Distance(2.3, Degree)
    )
    @test GeoEMTIPDemonstration.sameunit(
        EventTime(1, JulianDay), Distance(2.3, JulianDay)
    )
    @test GeoEMTIPDemonstration.sameunit(
        Distance(1, Degree), GeneralSpace(Latitude, 1, Degree)
    )
    @test_throws GeoEMTIPDemonstration.UnitMismatch GeoEMTIPDemonstration.sameunit(
        Distance(1, Degree), EventTime(1, JulianDay)
    )
    @test_throws GeoEMTIPDemonstration.UnitMismatch GeoEMTIPDemonstration.sameunit(
        Distance(1, Degree), Distance(1, JulianDay)
    )
    # Test `Distance` constructor
    @test Distance(2.3, Degree) == AngularDistance(ValueUnit(2.3, Degree))

    # Test `sameunit` error
    @test_throws GeoEMTIPDemonstration.UnitMismatch GeoEMTIPDemonstration.sameunit(
        GeneralSpace(EventTime, 1, JulianDay), GeneralSpace(Latitude, 2, Degree)
    )

    # Test `isless`
    @test isless(
        GeneralSpace(Latitude, 1, Degree), GeneralSpace(Latitude, 2, Degree)
    )
    @test_throws MethodError isless(
        GeneralSpace(Longitude, 1, Degree), GeneralSpace(Latitude, 1, Degree)
    ) # Longitude and Latitude is not comparable in size even when they are of the same unit

    @test isapprox(
        GeneralSpace(Longitude, 121.33, Degree) - GeneralSpace(Longitude, 110.0, Degree), Distance(11.33, Degree)
    )
    # TODO:
    # - Distance of the same unit is substractable/addable
    # - T<:Spatial can be substracted by Y<:...
end
