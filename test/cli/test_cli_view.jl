include(joinpath(@__DIR__, "..", "..", "cli", "commands", "cmd_view.jl"))

@testset "CLI View" begin
    input_path = joinpath(@__DIR__, "..", "fixtures", "cli_view_input.segy")
    output_path = joinpath(@__DIR__, "..", "fixtures", "cli_view_output.svg")
    write_segy(input_path, synthetic_dataset(trace_count=8, sample_count=32))

    @test run_view([input_path, output_path]) == 0
    @test isfile(output_path)
    content = read(output_path, String)
    @test occursin("<svg", content)
    @test occursin("SubBottomProfiler seismic section", content)
end
