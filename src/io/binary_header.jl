"""
    validate_binary_header(header::BinaryHeader) -> BinaryHeader

Validate binary header fields and return the validated header.

Example: `validate_binary_header(BinaryHeader(samples_per_trace=128))`
"""
function validate_binary_header(header::BinaryHeader)::BinaryHeader
    header.samples_per_trace >= 0 || throw(DomainError(header.samples_per_trace, "samples_per_trace must be non-negative"))
    header.sample_interval_microseconds > 0 || throw(DomainError(header.sample_interval_microseconds, "sample interval must be positive"))
    return header
end

"""
    parse_binary_header(buffer::Vector{UInt8}) -> BinaryHeader

Parse the 400-byte SEG-Y binary header buffer.

Example: `parse_binary_header(zeros(UInt8, 400))`
"""
function parse_binary_header(buffer::Vector{UInt8})::BinaryHeader
    length(buffer) == 400 || throw(ArgumentError("SEG-Y binary header must be 400 bytes"))
    read_i16(offset) = Int(reinterpret(Int16, reverse(buffer[offset:(offset + 1)]))[1])
    read_i32(offset) = Int32(reinterpret(Int32, reverse(buffer[offset:(offset + 3)]))[1])
    header = BinaryHeader(
        job_id=read_i32(1),
        line_number=read_i32(5),
        sample_interval_microseconds=read_i16(17),
        original_sample_interval_microseconds=read_i16(19),
        samples_per_trace=read_i16(21),
        original_samples_per_trace=read_i16(23),
        data_sample_format=Int16(read_i16(25)),
        ensemble_fold=Int16(read_i16(27)),
        trace_sorting_code=Int16(read_i16(29)),
        segy_revision=Int16(read_i16(301)),
        fixed_length_trace_flag=Int16(read_i16(303)),
        extended_text_header_count=Int16(read_i16(305)),
    )
    return validate_binary_header(header)
end

"""
    write_binary_header(io::IO, header::BinaryHeader) -> Nothing

Write a binary header to `io`.

Example: `write_binary_header(IOBuffer(), BinaryHeader())`
"""
function write_binary_header(io::IO, header::BinaryHeader)::Nothing
    validate_binary_header(header)
    buffer = zeros(UInt8, 400)
    write_i16!(offset, value) = (buffer[offset:(offset + 1)] .= reverse(reinterpret(UInt8, [Int16(value)])))
    write_i32!(offset, value) = (buffer[offset:(offset + 3)] .= reverse(reinterpret(UInt8, [Int32(value)])))
    write_i32!(1, header.job_id)
    write_i32!(5, header.line_number)
    write_i16!(17, header.sample_interval_microseconds)
    write_i16!(19, header.original_sample_interval_microseconds)
    write_i16!(21, header.samples_per_trace)
    write_i16!(23, header.original_samples_per_trace)
    write_i16!(25, header.data_sample_format)
    write_i16!(27, header.ensemble_fold)
    write_i16!(29, header.trace_sorting_code)
    write_i16!(301, header.segy_revision)
    write_i16!(303, header.fixed_length_trace_flag)
    write_i16!(305, header.extended_text_header_count)
    write(io, buffer)
    return nothing
end
