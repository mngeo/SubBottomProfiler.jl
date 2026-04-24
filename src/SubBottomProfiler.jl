module SubBottomProfiler

include("utils/Utils.jl")
include("model/SegyModel.jl")
include("io/SegyIO.jl")
include("processing/Processing.jl")
include("interpretation/Interpretation.jl")
include("visualization/Visualization.jl")
include("pipeline/Pipeline.jl")

using .Utils
using .SegyModel
using .SegyIO
using .Processing
using .Interpretation
using .Visualization
using .Pipeline

export Utils
export SegyModel
export SegyIO
export Processing
export Interpretation
export Visualization
export Pipeline

export moving_average, cosine_taper, linear_interpolate, clamp_index
export convolve_same, autocorrelation, analytic_envelope, hilbert_phase
export frequency_axis, padded_length, rms, mad, robust_zscore
export twtt_to_depth, depth_to_twtt, meters_per_second_to_feet_per_second, feet_per_second_to_meters_per_second
export TraceHeader, BinaryHeader, Trace, Dataset, SurveyGeometry, NavigationPoint
export read_segy, write_segy, ibm2ieee, ieee2ibm, write_binary_header, parse_binary_header, write_trace_header, parse_trace_header
export process, process_dataset
export GainParams, MuteParams, DcRemovalParams, TraceEditingParams
export BandpassParams, NotchFilterParams, FkFilterParams, MedianFilterParams
export SpikingDeconParams, PredictiveDeconParams, WienerFilterParams, WaveletEstimationParams
export NavMergeParams, BinningParams, SortingParams, OffsetCalculationParams
export VelocityModel1D, VelocityModel2D, SemblanceParams, NmoCorrectionParams
export MeanStackParams, DiversityStackParams
export KirchhoffMigrationParams, FkMigrationParams
export EnvelopeParams, InstantaneousPhaseParams, InstantaneousFreqParams
export RmsAmplitudeParams, ReflectionStrengthParams
export HorizonPick, HorizonPickerParams, LayerTrackerParams, ReflectorStrengthParams
export SeismicFaciesParams, WaterBottomPickerParams, VelocityAnalysisParams
export pick_horizon, pick_water_bottom, track_layers, reflector_strength, classify_facies, analyse_velocity, export_interpretation
export PlotSpec, wiggle_plot, seismic_section, spectrum_plot, velocity_panel, annotation_overlay, export_figure
export ProcessingPipeline, PipelineStep, run_pipeline, load_workflow, run_workflow

end
