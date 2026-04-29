```@meta
CurrentModule = SubBottomProfiler
```

# API Reference

## Data Model

```@docs
TraceHeader
BinaryHeader
Trace
Dataset
SurveyGeometry
NavigationPoint
```

## Model Internals

```@meta
CurrentModule = SubBottomProfiler.SegyModel
```

```@docs
HeaderFieldInfo
ExtendedTextHeader
```

```@meta
CurrentModule = SubBottomProfiler
```

## Utilities

```@docs
moving_average
cosine_taper
linear_interpolate
clamp_index
convolve_same
autocorrelation
analytic_envelope
hilbert_phase
frequency_axis
padded_length
rms
mad
robust_zscore
twtt_to_depth
depth_to_twtt
meters_per_second_to_feet_per_second
feet_per_second_to_meters_per_second
```

## I/O Helpers

```@meta
CurrentModule = SubBottomProfiler.SegyIO
```

```@docs
validate_binary_header
parse_extended_headers
validate_trace_header
parse_navigation
```

```@meta
CurrentModule = SubBottomProfiler.Processing
```

## Processing Registry Internals

```@docs
describe_registered_steps
instantiate_registered_step
```

```@meta
CurrentModule = SubBottomProfiler.Pipeline
```

## Pipeline Logging

```@docs
log_progress
```

```@meta
CurrentModule = SubBottomProfiler
```

## Visualization

`wiggle_plot`, `wiggle_plot!`, and `display_wiggle` share the same wiggle-rendering
options. In particular, `shade_side = :positive | :negative | :none` controls
variable-area fill consistently across SVG export and the optional Makie backend.

```@docs
PlotSpec
wiggle_plot
wiggle_plot!
display_wiggle
seismic_section
spectrum_plot
velocity_panel
annotation_overlay
seabed_overlay
export_figure
```

## Global Index

```@index
Pages = [
    "segy_format.md",
    "processing_reference.md",
    "interpretation_guide.md",
    "api_reference.md",
]
```
