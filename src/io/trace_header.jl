"""
    validate_trace_header(header::TraceHeader) -> TraceHeader

Validate a trace header and return it.

Example: `validate_trace_header(TraceHeader(sample_count=64, sample_interval_microseconds=250))`
"""
function validate_trace_header(header::TraceHeader)::TraceHeader
    header.sample_count >= 0 || throw(DomainError(header.sample_count, "sample_count must be non-negative"))
    header.sample_interval_microseconds > 0 || throw(DomainError(header.sample_interval_microseconds, "sample interval must be positive"))
    return header
end

"""
    parse_trace_header(buffer::Vector{UInt8}) -> TraceHeader

Parse the 240-byte SEG-Y trace header buffer.

Example: `parse_trace_header(zeros(UInt8, 240))`
"""
function parse_trace_header(buffer::Vector{UInt8})::TraceHeader
    length(buffer) == 240 || throw(ArgumentError("SEG-Y trace header must be 240 bytes"))
    read_i16(offset) = Int(reinterpret(Int16, reverse(buffer[offset:(offset + 1)]))[1])
    read_i32(offset) = Int32(reinterpret(Int32, reverse(buffer[offset:(offset + 3)]))[1])
    header = TraceHeader(
        trace_sequence_line=read_i32(1),
        trace_sequence_file=read_i32(5),
        field_record=read_i32(9),
        trace_number_within_field_record=read_i32(13),
        source_x=read_i32(73),
        source_y=read_i32(77),
        group_x=read_i32(81),
        group_y=read_i32(85),
        sample_count=read_i16(115),
        sample_interval_microseconds=read_i16(117),
        scalco=Int16(read_i16(71)),
        scalel=Int16(read_i16(69)),
        coordinate_units=Int16(read_i16(89)),
    )
    return header
end

"""
    write_trace_header(io::IO, header::TraceHeader) -> Nothing

Write a trace header to `io`.

Example: `write_trace_header(IOBuffer(), TraceHeader(sample_count=64))`
"""
function write_trace_header(io::IO, header::TraceHeader)::Nothing
    validate_trace_header(header)
    buffer = zeros(UInt8, 240)
    write_i16!(offset, value) = (buffer[offset:(offset + 1)] .= reverse(reinterpret(UInt8, [Int16(value)])))
    write_i32!(offset, value) = (buffer[offset:(offset + 3)] .= reverse(reinterpret(UInt8, [Int32(value)])))
    write_i32!(1, header.trace_sequence_line)
    write_i32!(5, header.trace_sequence_file)
    write_i32!(9, header.field_record)
    write_i32!(13, header.trace_number_within_field_record)
    write_i16!(69, header.scalel)
    write_i16!(71, header.scalco)
    write_i32!(73, header.source_x)
    write_i32!(77, header.source_y)
    write_i32!(81, header.group_x)
    write_i32!(85, header.group_y)
    write_i16!(89, header.coordinate_units)
    write_i16!(115, header.sample_count)
    write_i16!(117, header.sample_interval_microseconds)
    write(io, buffer)
    return nothing
end
