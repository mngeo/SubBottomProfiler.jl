module Interpretation

using Statistics
using Dates
using ..Utils: rms, moving_average
using ..SegyModel: Trace, Dataset
using ..Processing: process, MeanStackParams, SemblanceParams

include("horizon_picker.jl")
include("layer_tracker.jl")
include("reflector_strength.jl")
include("seismic_facies.jl")
include("water_bottom_picker.jl")
include("velocity_analysis.jl")
include("export_interpretation.jl")

export HorizonPick, HorizonPickerParams, LayerTrackerParams, ReflectorStrengthParams
export WaterBottomPickResult, WaterBottomWindow, WaterBottomWindowEstimatorParams
export SeismicFaciesParams, WaterBottomPickerParams, SegmentedWaterBottomPickerParams, VelocityAnalysisParams
export pick_horizon, track_layers, reflector_strength, classify_facies, pick_water_bottom, pick_water_bottom_result, pick_water_bottom_segmented, pick_water_bottom_segmented_result, pick_water_bottom_adaptive, pick_water_bottom_adaptive_result, estimate_water_bottom_windows, analyse_velocity
export export_interpretation

end
