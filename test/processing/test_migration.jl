@testset "Migration" begin
    dataset = synthetic_dataset()
    @test length(process(dataset.traces, KirchhoffMigrationParams())) == length(dataset.traces)
    @test length(process(dataset.traces, FkMigrationParams())) == length(dataset.traces)
end
