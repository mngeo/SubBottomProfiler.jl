@testset "Sample Format" begin
    value = 1.25
    @test isapprox(ibm2ieee(ieee2ibm(value)), value; atol=1e-3)
end
