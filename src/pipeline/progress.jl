"""
    log_progress(message::AbstractString) -> Nothing

Emit a pipeline progress message through the logging subsystem.

Example: `log_progress("running gain")`
"""
function log_progress(message::AbstractString)::Nothing
    @info message
    return nothing
end
