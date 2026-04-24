```@meta
CurrentModule = SubBottomProfiler
```

# Interpretation Guide

```@setup interpretation
using SubBottomProfiler
```

The interpretation layer builds on processed traces and explicit pick objects.

## Pick Types

```@docs
HorizonPick
HorizonPickerParams
LayerTrackerParams
ReflectorStrengthParams
SeismicFaciesParams
WaterBottomPickerParams
VelocityAnalysisParams
```

## Core Interpretation Functions

```@docs
pick_horizon
pick_water_bottom
track_layers
reflector_strength
classify_facies
analyse_velocity
export_interpretation
```

## Typical Interpretation Sequence

```@example interpretation
sample_count = 96
trace = Trace(
    TraceHeader(sample_count = sample_count, sample_interval_microseconds = 250),
    [sin(0.12 * i) + (i == 24 ? 2.0 : 0.0) + (i == 56 ? 1.0 : 0.0) for i in 1:sample_count],
)

dataset = Dataset(
    BinaryHeader(samples_per_trace = sample_count, original_samples_per_trace = sample_count),
    rpad("C 1 INTERPRET", 3200),
    SegyModel.ExtendedTextHeader(String[]),
    [trace],
    SurveyGeometry(line_name = "interpret"),
)

processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "8")),
        PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "5")),
    ]),
)

water_bottom = pick_water_bottom(processed.traces, WaterBottomPickerParams(search_end_sample = 32))
picks = pick_horizon(processed.traces, HorizonPickerParams(search_start_sample = 20, search_end_sample = 80))
tracked = track_layers(picks, LayerTrackerParams(max_jump_samples = 3))
strength = reflector_strength(processed.traces, tracked, ReflectorStrengthParams(window_samples = 8))

(length(water_bottom), length(tracked), length(strength))
```

## Interpretation Export

```@example interpretation
export_path = tempname() * ".csv"
export_interpretation(export_path, tracked)
isfile(export_path)
```
