@testset "Stacking" begin
    dataset = synthetic_dataset()
    stacked = process(dataset.traces, MeanStackParams())
    robust = process(dataset.traces, DiversityStackParams())
    @test length(stacked) == 1
    @test length(robust) == 1
end
