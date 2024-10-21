@testset "toindex_uniqsomething.jl" begin
    @test_throws MethodError GeoEMTIPDemonstration.toindex("Hello", Set(["HelloWorld", "Hello World", "Hello", "World"])) == 3

    @test GeoEMTIPDemonstration.toindex("Hello", ["HelloWorld", "Hello World", "Hello", "World"]) == 3

    @test GeoEMTIPDemonstration.toindex("Hello World", ["HelloWorld", "Hello World", "Hello", "World"]) == 2
    using DataFrames
    df = DataFrame(
        :a => 1:5,
        :trial => ["mix", "GE", "GE", "GEM", "EM"]
    )

    univalues = GeoEMTIPDemonstration.uniqsomething!(df, :trial)
    transform!(df, [:trial, :trial_ind] => ByRow(
        (f, i) -> univalues[i] == f
    ) => :test_results)
    @test all(df.test_results)
end
