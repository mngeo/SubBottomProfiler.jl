"""
    padded_length(n::Integer) -> Int

Return the next power-of-two length greater than or equal to `n`.

Example: `padded_length(33)`
"""
function padded_length(n::Integer)::Int
    n > 0 || throw(ArgumentError("n must be positive"))
    value = 1
    while value < n
        value <<= 1
    end
    return value
end

"""
    frequency_axis(sample_interval_seconds::Float64, n::Integer) -> Vector{Float64}

Create a one-sided frequency axis in hertz for `n` samples.

Example: `frequency_axis(0.001, 8)`
"""
function frequency_axis(sample_interval_seconds::Float64, n::Integer)::Vector{Float64}
    sample_interval_seconds > 0.0 || throw(DomainError(sample_interval_seconds, "sample interval must be positive"))
    n > 0 || throw(ArgumentError("n must be positive"))
    nyquist = 1.0 / (2.0 * sample_interval_seconds)
    return collect(range(0.0, nyquist; length=div(n, 2) + 1))
end
