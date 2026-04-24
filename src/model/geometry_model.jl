"""
    NavigationPoint

Navigation fix with geographic coordinates in decimal degrees and time in UTC.

Example: `NavigationPoint(1, 12.0, 54.0, DateTime(2024, 1, 1))`
"""
struct NavigationPoint
    trace_index::Int
    longitude_deg::Float64
    latitude_deg::Float64
    timestamp_utc::DateTime
end

"""
    SurveyGeometry

Survey geometry metadata for a dataset.

Example: `SurveyGeometry("line-01", NavigationPoint[])`
"""
Base.@kwdef struct SurveyGeometry
    line_name::String = "unknown"
    navigation::Vector{NavigationPoint} = NavigationPoint[]
    cdp_numbers::Vector{Int} = Int[]
    offsets_meters::Vector{Float64} = Float64[]
end
