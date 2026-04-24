"""
    TraceEditingParams

Trace-editing configuration.

Example: `TraceEditingParams(reverse_samples=true, pad_samples=16)`
"""
Base.@kwdef struct TraceEditingParams
    kill_threshold::Float64 = Inf
    reverse_samples::Bool = false
    pad_samples::Int = 0
    resample_stride::Int = 1
end

function process(traces::Vector{Trace}, params::TraceEditingParams)::Vector{Trace}
    params.resample_stride > 0 || throw(ArgumentError("resample_stride must be positive"))
    edited = Trace[]
    for trace in traces
        if maximum(abs.(trace.samples)) > params.kill_threshold
            continue
        end
        samples = params.reverse_samples ? reverse(trace.samples) : copy(trace.samples)
        samples = samples[1:params.resample_stride:end]
        if params.pad_samples > 0
            append!(samples, zeros(params.pad_samples))
        end
        header = TraceHeader(
            trace_sequence_line=trace.header.trace_sequence_line,
            trace_sequence_file=trace.header.trace_sequence_file,
            field_record=trace.header.field_record,
            trace_number_within_field_record=trace.header.trace_number_within_field_record,
            source_x=trace.header.source_x,
            source_y=trace.header.source_y,
            group_x=trace.header.group_x,
            group_y=trace.header.group_y,
            offset_meters=trace.header.offset_meters,
            sample_count=length(samples),
            sample_interval_microseconds=trace.header.sample_interval_microseconds,
            scalco=trace.header.scalco,
            scalel=trace.header.scalel,
            coordinate_units=trace.header.coordinate_units,
            extra=copy(trace.header.extra),
        )
        push!(edited, Trace(header, samples, trace.metadata))
    end
    return edited
end

@register_step :trace_editing TraceEditingParams
