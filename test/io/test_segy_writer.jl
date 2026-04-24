@testset "SEG-Y Writer" begin
    path = joinpath(@__DIR__, "..", "fixtures", "sample_rev2.segy")
    dataset = synthetic_dataset(trace_count=4, sample_count=32)
    write_segy(path, dataset)
    reread = read_segy(path)
    @test length(reread.traces) == 4
    @test reread.traces[1].samples[1] ≈ dataset.traces[1].samples[1] atol=1e-5
end
