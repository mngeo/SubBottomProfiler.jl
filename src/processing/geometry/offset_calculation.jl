"""
    OffsetCalculationParams

Offset calculation configuration.

Example: `OffsetCalculationParams()`
"""
Base.@kwdef struct OffsetCalculationParams
    coordinate_scale::Float64 = 1.0
end

function process(traces::Vector{Trace}, params::OffsetCalculationParams)::Vector{Trace}
    outputs = Trace[]
    for trace in traces
        dx = (trace.header.group_x - trace.header.source_x) * params.coordinate_scale
        dy = (trace.header.group_y - trace.header.source_y) * params.coordinate_scale
        header = TraceHeader(
            trace_sequence_line=trace.header.trace_sequence_line,
            trace_sequence_file=trace.header.trace_sequence_file,
            field_record=trace.header.field_record,
            trace_number_within_field_record=trace.header.trace_number_within_field_record,
            source_x=trace.header.source_x,
            source_y=trace.header.source_y,
            group_x=trace.header.group_x,
            group_y=trace.header.group_y,
            offset_meters=hypot(dx, dy),
            sample_count=trace.header.sample_count,
            sample_interval_microseconds=trace.header.sample_interval_microseconds,
            scalco=trace.header.scalco,
            scalel=trace.header.scalel,
            coordinate_units=trace.header.coordinate_units,
            extra=copy(trace.header.extra),
        )
        push!(outputs, Trace(header, trace.samples, trace.metadata))
    end
    return outputs
end

@register_step :offset_calculation OffsetCalculationParams
