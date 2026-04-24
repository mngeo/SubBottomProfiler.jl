module Processing

using Statistics
using ..Utils: moving_average, cosine_taper, convolve_same, analytic_envelope, hilbert_phase, rms
using ..SegyModel: Trace, TraceHeader, Dataset, SurveyGeometry, NavigationPoint

include("registry.jl")
include("preprocess/gain.jl")
include("preprocess/mute.jl")
include("preprocess/dc_removal.jl")
include("preprocess/trace_editing.jl")
include("filter/bandpass.jl")
include("filter/notch_filter.jl")
include("filter/fk_filter.jl")
include("filter/median_filter.jl")
include("deconvolution/spiking_decon.jl")
include("deconvolution/predictive_decon.jl")
include("deconvolution/wiener_filter.jl")
include("deconvolution/wavelet_estimation.jl")
include("geometry/nav_merge.jl")
include("geometry/binning.jl")
include("geometry/sorting.jl")
include("geometry/offset_calculation.jl")
include("velocity/velocity_model.jl")
include("velocity/semblance.jl")
include("velocity/nmo_correction.jl")
include("stacking/mean_stack.jl")
include("stacking/diversity_stack.jl")
include("migration/kirchhoff_migration.jl")
include("migration/fk_migration.jl")
include("attributes/envelope.jl")
include("attributes/instantaneous_phase.jl")
include("attributes/instantaneous_freq.jl")
include("attributes/rms_amplitude.jl")
include("attributes/reflection_strength.jl")

export process, process_dataset, describe_registered_steps, instantiate_registered_step, @register_step
export GainParams, MuteParams, DcRemovalParams, TraceEditingParams
export BandpassParams, NotchFilterParams, FkFilterParams, MedianFilterParams
export SpikingDeconParams, PredictiveDeconParams, WienerFilterParams, WaveletEstimationParams
export NavMergeParams, BinningParams, SortingParams, OffsetCalculationParams
export VelocityModel1D, VelocityModel2D, SemblanceParams, NmoCorrectionParams
export MeanStackParams, DiversityStackParams
export KirchhoffMigrationParams, FkMigrationParams
export EnvelopeParams, InstantaneousPhaseParams, InstantaneousFreqParams, RmsAmplitudeParams, ReflectionStrengthParams

end
