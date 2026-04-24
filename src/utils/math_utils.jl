"""
    moving_average(values::AbstractVector{<:Real}, window::Integer) -> Vector{Float64}

Compute a centered moving average with `window` samples.

Example: `moving_average([1, 2, 3], 3)`
"""
function moving_average(values::AbstractVector{<:Real}, window::Integer)::Vector{Float64}
    window > 0 || throw(ArgumentError("window must be positive"))
    result = Vector{Float64}(undef, length(values))
    radius = max(div(window, 2), 0)
    for index in eachindex(values)
        lo = max(firstindex(values), index - radius)
        hi = min(lastindex(values), index + radius)
        total = 0.0
        count = 0
        @inbounds for inner in lo:hi
            total += Float64(values[inner])
            count += 1
        end
        result[index] = total / count
    end
    return result
end

"""
    cosine_taper(n::Integer; fraction::Float64=0.1) -> Vector{Float64}

Create a symmetric cosine taper of length `n`.

Example: `cosine_taper(16; fraction=0.25)`
"""
function cosine_taper(n::Integer; fraction::Float64=0.1)::Vector{Float64}
    n > 0 || throw(ArgumentError("n must be positive"))
    0.0 <= fraction <= 0.5 || throw(DomainError(fraction, "fraction must be between 0 and 0.5"))
    result = ones(Float64, n)
    edge = floor(Int, fraction * n)
    for i in 1:edge
        weight = 0.5 * (1.0 - cos(pi * i / max(edge, 1)))
        result[i] = weight
        result[n - i + 1] = weight
    end
    return result
end

"""
    linear_interpolate(values::AbstractVector{<:Real}, position::Float64) -> Float64

Linearly interpolate `values` at one-based fractional `position`.

Example: `linear_interpolate([10, 20], 1.5)`
"""
function linear_interpolate(values::AbstractVector{<:Real}, position::Float64)::Float64
    isempty(values) && throw(ArgumentError("values must be non-empty"))
    if position <= 1.0
        return Float64(values[firstindex(values)])
    elseif position >= length(values)
        return Float64(values[lastindex(values)])
    end
    lo = floor(Int, position)
    hi = ceil(Int, position)
    if lo == hi
        return Float64(values[lo])
    end
    α = position - lo
    return (1.0 - α) * Float64(values[lo]) + α * Float64(values[hi])
end

"""
    clamp_index(index::Integer, n::Integer) -> Int

Clamp `index` to the valid interval `1:n`.

Example: `clamp_index(0, 10)`
"""
clamp_index(index::Integer, n::Integer)::Int = max(1, min(Int(index), Int(n)))
