# Interpretation Guide

The interpretation layer builds on processed traces and explicit pick objects.

## Horizon Picks

`HorizonPick` stores:

- `trace_index`
- `sample_index`
- `confidence`
- `provenance`

This keeps picks structured and trace-aware instead of using raw arrays.

## Water-Bottom Picking

Use `pick_water_bottom` to locate the first strong event within a limited sample window:

```julia
water_bottom = pick_water_bottom(
    traces,
    WaterBottomPickerParams(search_end_sample = 128),
)
```

## Horizon Picking

Use `pick_horizon` to search for the strongest event inside a given window:

```julia
picks = pick_horizon(
    traces,
    HorizonPickerParams(search_start_sample = 20, search_end_sample = 220),
)
```

## Layer Tracking

Use `track_layers` to smooth picks by limiting inter-trace jumps:

```julia
tracked = track_layers(picks, LayerTrackerParams(max_jump_samples = 4))
```

## Reflector Strength

Use `reflector_strength` to measure RMS amplitude around each pick:

```julia
strength = reflector_strength(
    traces,
    tracked,
    ReflectorStrengthParams(window_samples = 8),
)
```

## Facies Classification

The built-in facies classifier supports:

- rule-based thresholding
- a user-supplied callable model

Rule-based example:

```julia
labels = classify_facies(traces, SeismicFaciesParams(envelope_threshold = 0.5))
```

Model-based example:

```julia
my_model(samples) = maximum(abs.(samples)) > 1.0 ? "reflective" : "transparent"
labels = classify_facies(traces, SeismicFaciesParams(); model = my_model)
```

## Velocity Analysis

Use `analyse_velocity` to derive simplified velocity picks from semblance-like measures:

```julia
velocity_picks = analyse_velocity(traces, VelocityAnalysisParams(window_samples = 16))
```

## Interpretation Export

Supported export targets:

- `.csv`
- `.geojson`
- `.shp`

Example:

```julia
export_interpretation("picks.csv", tracked)
export_interpretation("picks.geojson", tracked)
```

## Typical Interpretation Sequence

```julia
processed = run_pipeline(
    dataset,
    ProcessingPipeline([
        PipelineStep(:dc_removal, Dict{Symbol, String}()),
        PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "16")),
        PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "7")),
    ]),
)

water_bottom = pick_water_bottom(processed.traces, WaterBottomPickerParams(search_end_sample = 96))
picks = pick_horizon(processed.traces, HorizonPickerParams(search_start_sample = 20, search_end_sample = 220))
tracked = track_layers(picks, LayerTrackerParams(max_jump_samples = 3))
strength = reflector_strength(processed.traces, tracked, ReflectorStrengthParams(window_samples = 8))
export_interpretation("tracked.csv", tracked)
```
