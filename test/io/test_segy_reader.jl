@testset "SEG-Y Reader" begin
    path = joinpath(@__DIR__, "..", "fixtures", "sample_rev1.segy")
    generate_fixture(path)
    dataset = read_segy(path)
    @test length(dataset.traces) == 6
    @test dataset.binary_header.samples_per_trace == 64
end
