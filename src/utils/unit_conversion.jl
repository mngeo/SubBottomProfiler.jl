"""
    twtt_to_depth(twtt_seconds::Real, velocity_m_per_s::Real) -> Float64

Convert two-way travel time in seconds to depth in meters using `velocity_m_per_s`.

Example: `twtt_to_depth(0.02, 1500.0)`
"""
twtt_to_depth(twtt_seconds::Real, velocity_m_per_s::Real)::Float64 = 0.5 * Float64(twtt_seconds) * Float64(velocity_m_per_s)

"""
    depth_to_twtt(depth_meters::Real, velocity_m_per_s::Real) -> Float64

Convert depth in meters to two-way travel time in seconds using `velocity_m_per_s`.

Example: `depth_to_twtt(15.0, 1500.0)`
"""
depth_to_twtt(depth_meters::Real, velocity_m_per_s::Real)::Float64 = 2.0 * Float64(depth_meters) / Float64(velocity_m_per_s)

"""
    meters_per_second_to_feet_per_second(value::Real) -> Float64

Convert velocity from meters per second to feet per second.

Example: `meters_per_second_to_feet_per_second(1500.0)`
"""
meters_per_second_to_feet_per_second(value::Real)::Float64 = Float64(value) * 3.280839895

"""
    feet_per_second_to_meters_per_second(value::Real) -> Float64

Convert velocity from feet per second to meters per second.

Example: `feet_per_second_to_meters_per_second(4921.26)`
"""
feet_per_second_to_meters_per_second(value::Real)::Float64 = Float64(value) / 3.280839895
