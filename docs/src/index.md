```@meta
CurrentModule = SubBottomProfiler
```

# SubBottomProfiler.jl

```@setup home
using SubBottomProfiler
```

`SubBottomProfiler.jl` provides a scriptable workflow for SEG-Y-based sub-bottom profiler processing and interpretation in Julia.

```@contents
Depth = 2
Pages = [
    "index.md",
    "getting_started.md",
    "segy_format.md",
    "processing_reference.md",
    "interpretation_guide.md",
    "cli_reference.md",
    "api_reference.md",
]
```

## Overview

The package is organized around a layered workflow:

1. Read SEG-Y data into typed Julia structs.
2. Apply pure processing steps to traces or datasets.
3. Run interpretation helpers such as water-bottom and horizon picking.
4. Build visualization specifications and export results.
5. Orchestrate end-to-end jobs through an in-memory pipeline or a TOML workflow.

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
  Lightweight `PlotSpec` builders, wiggle/seismic renderers, overlay helpers, and export helpers.
- `Pipeline`
  Processing pipelines and TOML workflow execution.
- `Utils`
  Numeric, DSP, statistical, and unit-conversion helpers.

## Typical Workflow

```@example home
sample_count = 64
trace = Trace(
    TraceHeader(sample_count = sample_count, sample_interval_microseconds = 250),
    [sin(0.2 * i) + (i == 20 ? 1.5 : 0.0) for i in 1:sample_count],
)

dataset = Dataset(
    BinaryHeader(samples_per_trace = sample_count, original_samples_per_trace = sample_count),
    rpad("C 1 EXAMPLE", 3200),
    SegyModel.ExtendedTextHeader(String[]),
    [trace],
    SurveyGeometry(line_name = "example"),
)

processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "8")),
        PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "5")),
    ]),
)

picks = pick_water_bottom(processed.traces, WaterBottomPickerParams(search_end_sample = 32))
plot = seismic_section(processed.traces)

(length(processed.traces), length(picks), plot.kind)
```

## Package Entry Points

Key user-facing exports include:

- data model types such as [`TraceHeader`](@ref), [`BinaryHeader`](@ref), [`Trace`](@ref), and [`Dataset`](@ref)
- I/O functions such as [`read_segy`](@ref) and [`write_segy`](@ref)
- processing entry points such as [`process`](@ref), [`process_dataset`](@ref), and [`run_pipeline`](@ref)
- interpretation functions such as [`pick_horizon`](@ref) and [`pick_water_bottom`](@ref)
- visualization builders such as [`wiggle_plot`](@ref), [`wiggle_plot!`](@ref), [`display_wiggle`](@ref), and [`seismic_section`](@ref)

## Visualization Notes

The package supports both export-oriented and interactive visualization workflows:

- [`wiggle_plot`](@ref) returns an SVG-backed `PlotSpec` for export and post-processing.
- [`wiggle_plot!`](@ref) renders directly into an existing `Makie.Axis` when the optional
  `Makie` extension is loaded.
- [`display_wiggle`](@ref) is the screen-display convenience helper that opens a
  `Makie.Figure` for a SEG-Y file or trace collection.

Wiggle variable-area shading is controlled with `shade_side`:

- `:positive` fills the positive lobe
- `:negative` fills the negative lobe
- `:none` disables fill

## Navigation

- Start with [Getting Started](@ref).
- Then see [SEG-Y Format Support](@ref).
- For algorithm coverage, see [Processing Reference](@ref) and [Interpretation Guide](@ref).
- For exported docstrings, see [API Reference](@ref).
