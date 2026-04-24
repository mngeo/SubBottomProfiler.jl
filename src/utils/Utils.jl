module Utils

using LinearAlgebra
using Statistics

include("math_utils.jl")
include("dsp_utils.jl")
include("fft_utils.jl")
include("statistics_utils.jl")
include("unit_conversion.jl")

export moving_average, cosine_taper, linear_interpolate, clamp_index
export convolve_same, autocorrelation, analytic_envelope, hilbert_phase
export frequency_axis, padded_length
export rms, mad, robust_zscore
export twtt_to_depth, depth_to_twtt, meters_per_second_to_feet_per_second, feet_per_second_to_meters_per_second

end
