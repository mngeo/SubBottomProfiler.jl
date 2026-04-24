# SubBottomProfiler.jl

`SubBottomProfiler.jl` is a Julia package for reading, processing, interpreting, and exporting marine sub-bottom profiler data stored in SEG-Y rev 1 and rev 2 files.

The package is organized around a layered workflow:

1. Read SEG-Y data into typed Julia structs.
2. Apply pure processing steps to traces or datasets.
3. Run interpretation helpers such as water-bottom and horizon picking.
4. Build visualization specifications and export results.
5. Orchestrate end-to-end jobs through an in-memory pipeline or a TOML workflow.

This repository follows the architecture in [plan.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/plan.md) and the module layout shown in [sbp_software_architecture.svg](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/sbp_software_architecture.svg).

## Status

The current implementation is a complete, documented scaffold with working tests and examples. It includes:

- Typed models for headers, traces, datasets, geometry, and picks.
- Simplified SEG-Y I/O for sample formats `1`, `3`, and `5`.
- A processing registry with representative algorithms across preprocessing, filtering, deconvolution, geometry, velocity, stacking, migration, and attributes.
- Interpretation helpers for picking, tracking, facies classification, velocity analysis, and export.
- Lightweight visualization specs and figure export placeholders.
- A pipeline engine and TOML-driven workflows.
- A small CLI for `info`, `process`, `view`, and `export`.

It does not yet provide a full Makie backend, full SEG-Y standard coverage, or production-grade migration/deconvolution implementations. The README examples below are written against the code that exists now.

## Repository Layout

- `src/`
  Contains the package code. The top-level module includes the `Utils`, `SegyModel`, `SegyIO`, `Processing`, `Interpretation`, `Visualization`, and `Pipeline` submodules.
- `cli/`
  Command-line entry points and command dispatch.
- `docs/`
  Package documentation pages and example TOML workflows.
- `test/`
  Unit and integration tests based on generated synthetic SEG-Y fixtures.
- `notebooks/`
  Minimal placeholder notebooks for tutorial expansion.

## Package Structure

The primary user-facing exports are:

- Data model:
  `TraceHeader`, `BinaryHeader`, `Trace`, `Dataset`, `SurveyGeometry`, `NavigationPoint`
- I/O:
  `read_segy`, `write_segy`, `parse_binary_header`, `write_binary_header`, `parse_trace_header`, `write_trace_header`, `ibm2ieee`, `ieee2ibm`
- Processing:
  `process`, `process_dataset`, plus parameter structs such as `GainParams`, `BandpassParams`, `NmoCorrectionParams`, `MeanStackParams`, and `EnvelopeParams`
- Interpretation:
  `pick_horizon`, `pick_water_bottom`, `track_layers`, `reflector_strength`, `classify_facies`, `analyse_velocity`, `export_interpretation`
- Visualization:
  `wiggle_plot`, `seismic_section`, `spectrum_plot`, `velocity_panel`, `annotation_overlay`, `export_figure`
- Pipeline:
  `PipelineStep`, `ProcessingPipeline`, `run_pipeline`, `load_workflow`, `run_workflow`
- Utilities:
  `moving_average`, `analytic_envelope`, `frequency_axis`, `rms`, `twtt_to_depth`, and related helpers

## Getting Started

### Load the package from the repository

The repository currently exposes the module directly from `src/`.

```julia
include("src/SubBottomProfiler.jl")
using .SubBottomProfiler
```

### Create a minimal synthetic dataset

```julia
include("src/SubBottomProfiler.jl")
using .SubBottomProfiler

sample_count = 256
samples = [sin(0.1 * i) + (i == 64 ? 2.0 : 0.0) for i in 1:sample_count]

trace_header = TraceHeader(
    trace_sequence_line = 1,
    trace_sequence_file = 1,
    field_record = 1,
    trace_number_within_field_record = 1,
    source_x = 1000,
    source_y = 2000,
    group_x = 1010,
    group_y = 2020,
    sample_count = sample_count,
    sample_interval_microseconds = 250,
)

trace = Trace(trace_header, samples)

binary_header = BinaryHeader(
    samples_per_trace = sample_count,
    original_samples_per_trace = sample_count,
    sample_interval_microseconds = 250,
)

dataset = Dataset(
    binary_header,
    rpad("C 1 SYNTHETIC EXAMPLE", 3200),
    SegyModel.ExtendedTextHeader(String[]),
    [trace],
    SurveyGeometry(line_name = "demo-line"),
)
```

### Write and read a SEG-Y file

```julia
path = "demo.segy"
write_segy(path, dataset)
reloaded = read_segy(path)

println(length(reloaded.traces))
println(reloaded.binary_header.samples_per_trace)
```

## Data Model

The package is centered on a few typed structs:

- `TraceHeader`
  Per-trace SEG-Y metadata such as sequence numbers, coordinates, sample count, and sample interval.
- `BinaryHeader`
  File-level SEG-Y metadata such as sample interval, sample format, and revision.
- `Trace`
  A single trace, consisting of a `TraceHeader`, a `Vector{Float64}` of samples, and a `Dict{Symbol, Float64}` metadata store.
- `Dataset`
  A file-level container containing headers, traces, and `SurveyGeometry`.
- `SurveyGeometry`
  Line name, navigation fixes, CDP bins, and offsets.
- `HorizonPick`
  A structured pick with `trace_index`, `sample_index`, `confidence`, and `provenance`.

### Inspect a dataset

```julia
first_trace = reloaded.traces[1]

println(first_trace.header.sample_count)
println(first_trace.header.sample_interval_microseconds)
println(first_trace.samples[1:8])
```

## SEG-Y I/O

`read_segy(path)` reads:

- the 3200-byte textual header
- the 400-byte binary header
- zero or more extended textual header stanzas
- each 240-byte trace header followed by trace samples

Supported sample formats:

- `1`: IBM floating-point
- `3`: 16-bit integer
- `5`: IEEE floating-point

### Read a file and inspect headers

```julia
dataset = read_segy("demo.segy")

println(dataset.binary_header.segy_revision)
println(dataset.binary_header.data_sample_format)
println(dataset.traces[1].header.trace_sequence_line)
```

### Low-level header round-trip

```julia
io = IOBuffer()
write_binary_header(io, BinaryHeader(samples_per_trace = 128))
seekstart(io)
parsed_binary = parse_binary_header(read(io, 400))

io = IOBuffer()
write_trace_header(io, TraceHeader(sample_count = 128, sample_interval_microseconds = 250))
seekstart(io)
parsed_trace = parse_trace_header(read(io, 240))
```

### IBM float conversion

```julia
ibm_word = ieee2ibm(1.25)
value = ibm2ieee(ibm_word)
println(value)
```

## Processing Model

All processing steps are written as pure functions:

```julia
process(traces::Vector{Trace}, params::MyParams) -> Vector{Trace}
```

The original trace vector is not mutated. `process_dataset(dataset, params)` wraps the same logic at the dataset level.

### Simple processing sequence

```julia
traces_1 = process(dataset.traces, DcRemovalParams())
traces_2 = process(traces_1, GainParams(mode = "agc", window_samples = 16))
traces_3 = process(traces_2, BandpassParams(smoothing_samples = 9))
```

### Process a full dataset

```julia
processed_dataset = process_dataset(dataset, GainParams(mode = "linear", slope_per_sample = 0.002))
```

## Available Processing Steps

### Preprocessing

- `GainParams`
  `mode = "agc" | "linear" | "exponential"`
- `MuteParams`
  Top and bottom sample muting with cosine tapers.
- `DcRemovalParams`
  Remove mean amplitude from each trace.
- `TraceEditingParams`
  Reverse, resample, pad, or drop traces by threshold.

Example:

```julia
edited = process(
    dataset.traces,
    TraceEditingParams(reverse_samples = true, resample_stride = 2, pad_samples = 16),
)
```

### Filtering

- `BandpassParams`
  Simplified smoothing-based bandpass proxy.
- `NotchFilterParams`
  Periodic noise suppression with a simple difference kernel.
- `FkFilterParams`
  Spatial coherence smoothing across adjacent traces.
- `MedianFilterParams`
  Spatial median filtering trace-by-trace.

Example:

```julia
filtered = process(dataset.traces, MedianFilterParams(spatial_window = 1))
```

### Deconvolution

- `SpikingDeconParams`
- `PredictiveDeconParams`
- `WienerFilterParams`
- `WaveletEstimationParams`

Example:

```julia
deconvolved = process(dataset.traces, SpikingDeconParams(prewhitening = 0.02))
```

### Geometry and Navigation

- `NavMergeParams`
- `BinningParams`
- `SortingParams`
- `OffsetCalculationParams`

Example:

```julia
offset_traces = process(dataset.traces, OffsetCalculationParams(coordinate_scale = 1.0))
sorted_traces = process(offset_traces, SortingParams(key = :trace_sequence_line))
```

### Velocity and Moveout

- `VelocityModel1D`
- `VelocityModel2D`
- `SemblanceParams`
- `NmoCorrectionParams`

Example:

```julia
offset_traces = process(dataset.traces, OffsetCalculationParams())
nmo_traces = process(offset_traces, NmoCorrectionParams(velocity_m_per_s = 1500.0))
semblance_traces = process(dataset.traces, SemblanceParams(window_samples = 8))
```

### Stacking and Migration

- `MeanStackParams`
- `DiversityStackParams`
- `KirchhoffMigrationParams`
- `FkMigrationParams`

Example:

```julia
stacked = process(dataset.traces, MeanStackParams(method = "mean"))
migrated = process(dataset.traces, KirchhoffMigrationParams(aperture_traces = 2))
```

### Seismic Attributes

- `EnvelopeParams`
- `InstantaneousPhaseParams`
- `InstantaneousFreqParams`
- `RmsAmplitudeParams`
- `ReflectionStrengthParams`

Example:

```julia
envelope_traces = process(dataset.traces, EnvelopeParams())
phase_traces = process(dataset.traces, InstantaneousPhaseParams())
rms_traces = process(dataset.traces, RmsAmplitudeParams(window_samples = 12))
```

## Pipelines and Workflows

The package provides two orchestration layers:

- `ProcessingPipeline`
  Build a pipeline directly in Julia.
- TOML workflows
  Persist a named sequence of steps outside code.

### Build a pipeline in Julia

```julia
pipeline = ProcessingPipeline([
    PipelineStep(:dc_removal, Dict{Symbol, String}()),
    PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "16")),
    PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "7")),
    PipelineStep(:envelope, Dict{Symbol, String}()),
])

output = run_pipeline(dataset, pipeline)
```

### Run a workflow from TOML

The repository includes example workflows under [docs/workflows](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/workflows).

```julia
workflow = load_workflow("docs/workflows/basic_processing.toml")
output = run_pipeline(dataset, workflow)
```

Or directly:

```julia
output = run_workflow(dataset, "docs/workflows/full_stack_workflow.toml")
```

Example TOML:

```toml
[[steps]]
name = "dc_removal"

[[steps]]
name = "gain"
mode = "agc"
window_samples = 16

[[steps]]
name = "bandpass"
smoothing_samples = 7
```

## Interpretation

The interpretation layer works on processed traces and explicit pick objects.

### Water-bottom picking

```julia
water_bottom = pick_water_bottom(
    dataset.traces,
    WaterBottomPickerParams(search_end_sample = 128),
)
```

### Horizon picking and tracking

```julia
picks = pick_horizon(
    dataset.traces,
    HorizonPickerParams(search_start_sample = 10, search_end_sample = 200),
)

tracked = track_layers(picks, LayerTrackerParams(max_jump_samples = 3))
strength = reflector_strength(dataset.traces, tracked, ReflectorStrengthParams(window_samples = 8))
```

### Facies classification

```julia
labels = classify_facies(
    dataset.traces,
    SeismicFaciesParams(envelope_threshold = 0.5),
)
```

You can also pass a callable model:

```julia
dummy_model(samples) = maximum(abs.(samples)) > 1.0 ? "reflective" : "transparent"
labels = classify_facies(dataset.traces, SeismicFaciesParams(); model = dummy_model)
```

### Velocity analysis

```julia
velocity_picks = analyse_velocity(dataset.traces, VelocityAnalysisParams(window_samples = 16))
```

### Export picks

```julia
export_interpretation("picks.csv", picks)
export_interpretation("picks.geojson", picks)
export_interpretation("picks.shp", picks)
```

## Visualization

The current implementation returns lightweight `PlotSpec` objects instead of drawing directly. This makes the API usable without a heavy plotting dependency.

### Create a seismic section

```julia
section = seismic_section(dataset.traces)
println(section.kind)
println(section.payload[:matrix])
```

### Create wiggle, spectrum, and velocity panel specs

```julia
wiggles = wiggle_plot(dataset.traces; scale = 1.2)
spectrum = spectrum_plot(dataset.traces[1])
panel = velocity_panel([1450.0, 1500.0, 1550.0])
```

### Add annotations and export

```julia
annotated = annotation_overlay(section, ["water bottom", "candidate reflector"])
export_figure("section.svg", annotated)
export_figure("section.pdf", annotated)
export_figure("section.png", annotated)
```

## Utilities

Useful standalone helpers are exported at the package root.

```julia
avg = moving_average([1, 2, 3, 4], 3)
env = analytic_envelope([0.0, 1.0, 0.0, -1.0])
freq = frequency_axis(0.00025, 256)
depth = twtt_to_depth(0.02, 1500.0)
twtt = depth_to_twtt(15.0, 1500.0)
```

## CLI Usage

The CLI entry point is [cli/main.jl](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/cli/main.jl:1).

Usage:

```text
sbp <info|process|view|export> [args]
```

### Show dataset info

```bash
julia cli/main.jl info demo.segy
```

### Process a file through a workflow

```bash
julia cli/main.jl process demo.segy docs/workflows/basic_processing.toml demo_processed.segy
```

### Generate a quick-look section spec

```bash
julia cli/main.jl view demo.segy
```

### Export water-bottom picks

```bash
julia cli/main.jl export demo.segy picks.csv
```

## Testing

Run the test suite with a writable Julia depot.

```bash
JULIA_DEPOT_PATH=/tmp/julia-depot julia --project test/runtests.jl
```

The repository includes:

- utility tests
- SEG-Y binary and trace header tests
- SEG-Y read/write round-trip tests
- processing tests across all implemented step families
- interpretation tests
- pipeline and workflow tests

## Documentation Pages

Additional package documentation lives under [docs/src](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src):

- [index.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/index.md)
- [getting_started.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/getting_started.md)
- [segy_format.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/segy_format.md)
- [processing_reference.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/processing_reference.md)
- [interpretation_guide.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/interpretation_guide.md)
- [cli_reference.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/cli_reference.md)

## Current Limitations

- The plotting layer currently emits `PlotSpec` records rather than rendering full figures in Makie.
- Several processing algorithms are intentionally simplified placeholders suitable for scaffolding, tests, and API examples.
- SEG-Y support is focused on the implemented headers and formats rather than exhaustive revision-2 coverage.
- The package is included directly from `src/` in this repository layout instead of being installed from a registry.

## Development Notes

If you extend the package, follow the conventions in [AGENTS.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/AGENTS.md), especially:

- keep processing steps pure
- keep params typed and default-constructible
- register new steps in the processing registry
- add matching unit tests
- document public APIs and units
