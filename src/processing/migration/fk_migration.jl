"""
    FkMigrationParams

Stolt-style F-K migration configuration.

Example: `FkMigrationParams(spatial_window=2)`
"""
Base.@kwdef struct FkMigrationParams
    spatial_window::Int = 2
end

function process(traces::Vector{Trace}, params::FkMigrationParams)::Vector{Trace}
    return process(traces, FkFilterParams(spatial_window=params.spatial_window))
end

@register_step :fk_migration FkMigrationParams
