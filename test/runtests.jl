using Test

include("../src/SubBottomProfiler.jl")
using .SubBottomProfiler

include("fixtures/generate_synthetic.jl")

@testset "SubBottomProfiler" begin
    include("utils/test_dsp_utils.jl")
    include("io/test_data_sample_format.jl")
    include("io/test_binary_header.jl")
    include("io/test_trace_header.jl")
    include("io/test_segy_reader.jl")
    include("io/test_segy_writer.jl")
    include("processing/test_gain.jl")
    include("processing/test_filters.jl")
    include("processing/test_deconvolution.jl")
    include("processing/test_nmo.jl")
    include("processing/test_stacking.jl")
    include("processing/test_migration.jl")
    include("processing/test_attributes.jl")
    include("interpretation/test_horizon_picker.jl")
    include("interpretation/test_water_bottom.jl")
    include("pipeline/test_pipeline.jl")
    include("visualization/test_wiggle_plot.jl")
    include("cli/test_cli_view.jl")
end
