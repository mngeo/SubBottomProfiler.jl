# Getting Started

## Loading The Package

The current repository layout is used directly from source:

```julia
include("src/SubBottomProfiler.jl")
using .SubBottomProfiler
```

## Construct A Minimal Dataset

```julia
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

```julia
write_segy("demo.segy", dataset)
loaded = read_segy("demo.segy")
println(length(loaded.traces))
```

## Apply A Simple Processing Sequence

```julia
processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "linear", :slope_per_sample => "0.002")),
        PipelineStep(:envelope, Dict{Symbol, String}()),
    ]),
)
```

## Pick Horizons

```julia
picks = pick_horizon(
    processed.traces,
    HorizonPickerParams(search_start_sample = 1, search_end_sample = 96),
)
```

## Export Outputs

```julia
plot = seismic_section(processed.traces)
export_figure("demo_section.svg", plot)
export_interpretation("demo_picks.csv", picks)
```

## Recommended Next Pages

- [segy_format.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/segy_format.md)
- [processing_reference.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/processing_reference.md)
- [interpretation_guide.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/interpretation_guide.md)
- [cli_reference.md](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/src/cli_reference.md)
