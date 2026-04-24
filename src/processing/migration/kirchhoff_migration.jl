"""
    KirchhoffMigrationParams

Post-stack time-migration configuration.

Example: `KirchhoffMigrationParams(aperture_traces=3)`
"""
Base.@kwdef struct KirchhoffMigrationParams
    aperture_traces::Int = 3
end

function process(traces::Vector{Trace}, params::KirchhoffMigrationParams)::Vector{Trace}
    params.aperture_traces > 0 || throw(ArgumentError("aperture_traces must be positive"))
    return process(traces, MedianFilterParams(spatial_window=params.aperture_traces))
end

@register_step :kirchhoff_migration KirchhoffMigrationParams
