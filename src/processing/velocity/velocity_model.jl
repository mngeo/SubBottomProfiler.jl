"""
    VelocityModel1D

One-dimensional interval velocity model in meters per second.

Example: `VelocityModel1D([0.0, 0.02], [1500.0, 1600.0])`
"""
struct VelocityModel1D
    twtt_seconds::Vector{Float64}
    velocity_m_per_s::Vector{Float64}
end

"""
    VelocityModel2D

Two-dimensional velocity grid in meters per second.

Example: `VelocityModel2D([0.0], [0.0], [1500.0;;])`
"""
struct VelocityModel2D
    x_meters::Vector{Float64}
    twtt_seconds::Vector{Float64}
    velocity_m_per_s::Matrix{Float64}
end
