# SubBottomProfiler.jl

`SubBottomProfiler.jl` provides a scriptable workflow for SEG-Y-based sub-bottom profiler processing and interpretation in Julia.

## What The Package Does

- reads SEG-Y data into typed Julia structs
- applies pure processing steps trace-by-trace or dataset-by-dataset
- supports in-memory and TOML-driven workflows
- provides interpretation helpers for picking and export
- produces lightweight plot specifications for downstream rendering or export

## Main Modules

- `SegyModel`
  Core structs for headers, traces, datasets, geometry, and picks.
- `SegyIO`
  SEG-Y reading, writing, header parsing, sample-format conversion, and navigation parsing.
- `Processing`
  Registered algorithms grouped into preprocessing, filtering, deconvolution, geometry, velocity, stacking, migration, and attributes.
- `Interpretation`
  Horizon picking, water-bottom picking, layer tracking, facies classification, velocity analysis, and interpretation export.
- `Visualization`
  Lightweight `PlotSpec` builders and export helpers.
- `Pipeline`
  Processing pipelines and TOML workflow execution.
- `Utils`
  Numeric, DSP, statistical, and unit-conversion helpers.

## Typical Workflow

```julia
include("../src/SubBottomProfiler.jl")
using .SubBottomProfiler

dataset = read_segy("line.segy")

processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "16")),
        PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "7")),
    ]),
)

picks = pick_water_bottom(processed.traces, WaterBottomPickerParams(search_end_sample = 128))
plot = seismic_section(processed.traces)
export_interpretation("water_bottom.csv", picks)
export_figure("section.svg", plot)
```

See the repository [README.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/README.md) for a fuller walk-through.
