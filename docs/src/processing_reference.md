# Processing Reference

All processing steps follow the same interface:

```julia
process(traces::Vector{Trace}, params) -> Vector{Trace}
```

At the dataset level:

```julia
process_dataset(dataset::Dataset, params) -> Dataset
```

## Pipeline Registration

Processing steps are registered by name and can be used in:

- `ProcessingPipeline`
- TOML workflow files loaded with `load_workflow`

Example:

```julia
pipeline = ProcessingPipeline([
    PipelineStep(:dc_removal, Dict{Symbol, String}()),
    PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "16")),
    PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "9")),
])
```

## Preprocessing

### `GainParams`

Fields:

- `mode::String`
- `window_samples::Int`
- `slope_per_sample::Float64`
- `exponent::Float64`

Example:

```julia
output = process(traces, GainParams(mode = "agc", window_samples = 32))
```

### `MuteParams`

Fields:

- `top_samples::Int`
- `bottom_samples::Int`
- `taper_fraction::Float64`

### `DcRemovalParams`

Fields:

- `enabled::Bool`

### `TraceEditingParams`

Fields:

- `kill_threshold::Float64`
- `reverse_samples::Bool`
- `pad_samples::Int`
- `resample_stride::Int`

## Filtering

### `BandpassParams`

Fields:

- `lowcut_hz::Float64`
- `highcut_hz::Float64`
- `smoothing_samples::Int`

### `NotchFilterParams`

- `noise_period_samples::Int`

### `FkFilterParams`

- `spatial_window::Int`

### `MedianFilterParams`

- `spatial_window::Int`

## Deconvolution

### `SpikingDeconParams`

- `prewhitening::Float64`

### `PredictiveDeconParams`

- `prediction_gap_samples::Int`

### `WienerFilterParams`

- `window_samples::Int`

### `WaveletEstimationParams`

- `window_samples::Int`

## Geometry

### `NavMergeParams`

- `overwrite_existing::Bool`

### `BinningParams`

- `bin_size_meters::Float64`

### `SortingParams`

- `key::Symbol`

### `OffsetCalculationParams`

- `coordinate_scale::Float64`

## Velocity

### `SemblanceParams`

- `window_samples::Int`

### `NmoCorrectionParams`

- `velocity_m_per_s::Float64`
- `stretch_mute_limit::Float64`

Example:

```julia
offset_traces = process(traces, OffsetCalculationParams())
corrected = process(offset_traces, NmoCorrectionParams(velocity_m_per_s = 1500.0))
```

## Stacking

### `MeanStackParams`

- `method::String`

### `DiversityStackParams`

- `trim_fraction::Float64`

## Migration

### `KirchhoffMigrationParams`

- `aperture_traces::Int`

### `FkMigrationParams`

- `spatial_window::Int`

## Attributes

### `EnvelopeParams`

- `store_key::Symbol`

### `InstantaneousPhaseParams`

- `unwrap_phase::Bool`

### `InstantaneousFreqParams`

- `sample_interval_seconds::Float64`

### `RmsAmplitudeParams`

- `window_samples::Int`

### `ReflectionStrengthParams`

- `power::Float64`

Example:

```julia
envelope = process(traces, EnvelopeParams())
phase = process(traces, InstantaneousPhaseParams())
rms_amp = process(traces, RmsAmplitudeParams(window_samples = 8))
```

## Workflow Example

```toml
[[steps]]
name = "dc_removal"

[[steps]]
name = "gain"
mode = "linear"
slope_per_sample = 0.002

[[steps]]
name = "semblance"
window_samples = 12

[[steps]]
name = "mean_stack"
method = "mean"
```
