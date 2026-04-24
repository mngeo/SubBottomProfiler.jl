"""
    convolve_same(signal::AbstractVector{<:Real}, kernel::AbstractVector{<:Real}) -> Vector{Float64}

Convolve `signal` with `kernel` and return a vector with the same length as `signal`.

Example: `convolve_same([1, 2, 3], [1, -1])`
"""
function convolve_same(signal::AbstractVector{<:Real}, kernel::AbstractVector{<:Real})::Vector{Float64}
    isempty(signal) && return Float64[]
    isempty(kernel) && throw(ArgumentError("kernel must be non-empty"))
    full = zeros(Float64, length(signal) + length(kernel) - 1)
    for i in eachindex(signal)
        @inbounds for j in eachindex(kernel)
            full[i + j - 1] += Float64(signal[i]) * Float64(kernel[j])
        end
    end
    offset = div(length(kernel), 2)
    return [full[clamp(i + offset, 1, length(full))] for i in 1:length(signal)]
end

"""
    autocorrelation(signal::AbstractVector{<:Real}, max_lag::Integer) -> Vector{Float64}

Return the autocorrelation sequence from lag `0:max_lag`.

Example: `autocorrelation([1, 2, 1], 2)`
"""
function autocorrelation(signal::AbstractVector{<:Real}, max_lag::Integer)::Vector{Float64}
    max_lag >= 0 || throw(ArgumentError("max_lag must be non-negative"))
    result = zeros(Float64, max_lag + 1)
    for lag in 0:max_lag
        total = 0.0
        @inbounds for i in 1:(length(signal) - lag)
            total += Float64(signal[i]) * Float64(signal[i + lag])
        end
        result[lag + 1] = total
    end
    return result
end

"""
    analytic_envelope(signal::AbstractVector{<:Real}) -> Vector{Float64}

Approximate the instantaneous amplitude envelope using a first-derivative quadrature proxy.

Example: `analytic_envelope([0, 1, 0])`
"""
function analytic_envelope(signal::AbstractVector{<:Real})::Vector{Float64}
    n = length(signal)
    result = zeros(Float64, n)
    for i in eachindex(signal)
        prev = Float64(signal[max(1, i - 1)])
        next = Float64(signal[min(n, i + 1)])
        deriv = 0.5 * (next - prev)
        result[i] = hypot(Float64(signal[i]), deriv)
    end
    return result
end

"""
    hilbert_phase(signal::AbstractVector{<:Real}) -> Vector{Float64}

Approximate the instantaneous phase angle in radians.

Example: `hilbert_phase([0, 1, 0])`
"""
function hilbert_phase(signal::AbstractVector{<:Real})::Vector{Float64}
    n = length(signal)
    result = zeros(Float64, n)
    for i in eachindex(signal)
        prev = Float64(signal[max(1, i - 1)])
        next = Float64(signal[min(n, i + 1)])
        quadrature = 0.5 * (next - prev)
        result[i] = atan(quadrature, Float64(signal[i]))
    end
    return result
end
