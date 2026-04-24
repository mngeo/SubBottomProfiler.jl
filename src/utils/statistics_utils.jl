"""
    rms(values::AbstractVector{<:Real}) -> Float64

Compute the root-mean-square amplitude.

Example: `rms([1, -1])`
"""
function rms(values::AbstractVector{<:Real})::Float64
    isempty(values) && return 0.0
    return sqrt(sum(abs2, Float64.(values)) / length(values))
end

"""
    mad(values::AbstractVector{<:Real}) -> Float64

Compute the median absolute deviation.

Example: `mad([1, 1, 2])`
"""
function mad(values::AbstractVector{<:Real})::Float64
    isempty(values) && return 0.0
    centre = median(Float64.(values))
    return median(abs.(Float64.(values) .- centre))
end

"""
    robust_zscore(values::AbstractVector{<:Real}) -> Vector{Float64}

Compute a robust z-score based on the median and MAD.

Example: `robust_zscore([1, 1, 2])`
"""
function robust_zscore(values::AbstractVector{<:Real})::Vector{Float64}
    isempty(values) && return Float64[]
    centre = median(Float64.(values))
    scale = max(mad(values), eps(Float64))
    return (Float64.(values) .- centre) ./ (1.4826 * scale)
end
