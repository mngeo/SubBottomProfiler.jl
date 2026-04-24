# SubBottomProfiler.jl

`SubBottomProfiler.jl` is a Julia package for reading, processing, interpreting, and exporting marine sub-bottom profiler data stored in SEG-Y rev 1 and rev 2 files.

The repository follows the architecture in [plan.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/plan.md) and the layered module design shown in [sbp_software_architecture.svg](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/sbp_software_architecture.svg). The current implementation provides a complete package skeleton with typed models, simplified SEG-Y I/O, a pipeline registry, representative processing algorithms, interpretation helpers, lightweight visualization specs, a small CLI, and a synthetic test suite.

## Layout

- `src/` contains the package code split into `io`, `model`, `processing`, `interpretation`, `visualization`, `pipeline`, and `utils` modules.
- `cli/` contains command entry points for `info`, `process`, `view`, and `export`.
- `test/` contains unit and integration tests built around generated synthetic SEG-Y fixtures.
- `docs/` contains Documenter sources and example TOML workflows.

## Quick Start

```julia
include("src/SubBottomProfiler.jl")
using .SubBottomProfiler

header = TraceHeader(sample_count=256, sample_interval_microseconds=250)
trace = Trace(header, sin.(range(0, 8pi; length=256)))
dataset = Dataset(BinaryHeader(samples_per_trace=256), rpad("SBP", 3200), SegyModel.ExtendedTextHeader(String[]), [trace], SurveyGeometry())

processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "16")),
    ]),
)
```

## Testing

Run the fast test suite with:

```bash
julia --project -e "using Pkg; Pkg.test()"
```
