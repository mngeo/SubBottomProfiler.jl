```@meta
CurrentModule = SubBottomProfiler
```

# Getting Started

```@setup getting_started
using SubBottomProfiler
```

## Loading The Package

For a local checkout, load the package from source:

```julia
include("src/SubBottomProfiler.jl")
using .SubBottomProfiler
```

When using a Documenter docs build, the package is loaded from the active docs environment.

## Construct A Minimal Dataset

```@example getting_started
sample_count = 128
header = TraceHeader(sample_count = sample_count, sample_interval_microseconds = 250)
trace = Trace(header, sin.(range(0, 4pi; length = sample_count)))

dataset = Dataset(
    BinaryHeader(samples_per_trace = sample_count, original_samples_per_trace = sample_count),
    rpad("C 1 DEMO", 3200),
    SegyModel.ExtendedTextHeader(String[]),
    [trace],
    SurveyGeometry(line_name = "demo"),
)
```

## Read And Write SEG-Y

```@example getting_started
path = tempname() * ".segy"
write_segy(path, dataset)
loaded = read_segy(path)
(length(loaded.traces), loaded.binary_header.samples_per_trace)
```

## Apply A Simple Processing Sequence

```@example getting_started
processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:tvg, Dict{Symbol, String}(:sound_velocity_m_per_s => "1520.0", :reference_depth_m => "0.5")),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "linear", :slope_per_sample => "0.002")),
        PipelineStep(:envelope, Dict{Symbol, String}()),
    ]),
)

length(processed.traces)
```

## Pick Horizons

```@example getting_started
picks = pick_horizon(
    processed.traces,
    HorizonPickerParams(search_start_sample = 1, search_end_sample = 96),
)

first(picks)
```

## Export Outputs

```@example getting_started
plot = seismic_section(processed.traces)
figure_path = tempname() * ".svg"
picks_path = tempname() * ".csv"

export_figure(figure_path, plot)
export_interpretation(picks_path, picks)

(isfile(figure_path), isfile(picks_path))
```

## Create And Inspect A Wiggle Plot

```@example getting_started
wiggles = wiggle_plot(processed.traces; scale = 1.1, shade_side = :positive)

(wiggles.kind, wiggles.format, wiggles.metadata[:shade_side])
```

For interactive display, load `Makie` and a backend such as `GLMakie`, then either:

- call `wiggle_plot!(ax, traces; shade_side = :positive)` for embedding into an existing layout
- call `display_wiggle("line.segy"; stride = 20, shade_side = :negative)` for a quick on-screen inspection window

Use `shade_side = :none` when you want line wiggles without variable-area fill.

## Next Steps

- Review [SEG-Y Format Support](@ref) for the implemented file and header coverage.
- Review [Processing Reference](@ref) for registered processing steps.
- Review [Interpretation Guide](@ref) for picking, tracking, and export workflows.
- Review [CLI Reference](@ref) for the command-line interface.
