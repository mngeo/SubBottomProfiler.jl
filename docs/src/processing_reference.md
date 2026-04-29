```@meta
CurrentModule = SubBottomProfiler
```

# Processing Reference

```@setup processing
using SubBottomProfiler
```

All processing steps follow the same interface:

```julia
process(traces::Vector{Trace}, params) -> Vector{Trace}
```

At the dataset level:

```julia
process_dataset(dataset::Dataset, params) -> Dataset
```

```@docs
process
process_dataset
```

## Pipeline Registration

Registered processing steps can be used directly from Julia pipelines or TOML workflow files.

```@docs
PipelineStep
ProcessingPipeline
run_pipeline
load_workflow
run_workflow
```

## Preprocessing

```@docs
GainParams
AmplitudeThresholdParams
TvgParams
MuteParams
DcRemovalParams
TraceEditingParams
```

## Filtering

```@docs
BandpassParams
NotchFilterParams
FkFilterParams
MedianFilterParams
```

## Deconvolution

```@docs
SpikingDeconParams
PredictiveDeconParams
WienerFilterParams
WaveletEstimationParams
```

## Geometry

```@docs
NavMergeParams
BinningParams
SortingParams
OffsetCalculationParams
```

## Velocity

```@docs
VelocityModel1D
VelocityModel2D
SemblanceParams
NmoCorrectionParams
```

## Stacking And Migration

```@docs
MeanStackParams
DiversityStackParams
KirchhoffMigrationParams
FkMigrationParams
```

## Seismic Attributes

```@docs
EnvelopeParams
InstantaneousPhaseParams
InstantaneousFreqParams
RmsAmplitudeParams
ReflectionStrengthParams
```

## Example Pipeline

```@example processing
sample_count = 64
trace = Trace(
    TraceHeader(sample_count = sample_count, sample_interval_microseconds = 250),
    [sin(0.15 * i) for i in 1:sample_count],
)

dataset = Dataset(
    BinaryHeader(samples_per_trace = sample_count, original_samples_per_trace = sample_count),
    rpad("C 1 PROCESS", 3200),
    SegyModel.ExtendedTextHeader(String[]),
    [trace],
    SurveyGeometry(line_name = "process"),
)

pipeline = ProcessingPipeline([
    PipelineStep(:dc_removal, Dict{Symbol, String}()),
    PipelineStep(:gain, Dict{Symbol, String}(:mode => "agc", :window_samples => "8")),
    PipelineStep(:bandpass, Dict{Symbol, String}(:smoothing_samples => "5")),
    PipelineStep(:envelope, Dict{Symbol, String}()),
])

output = run_pipeline(dataset, pipeline)
length(output.traces)
```
