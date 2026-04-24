"""
    parse_extended_headers(io::IO, count::Integer) -> ExtendedTextHeader

Read `count` SEG-Y extended textual header blocks from `io`.

Example: `parse_extended_headers(IOBuffer(), 0)`
"""
function parse_extended_headers(io::IO, count::Integer)::ExtendedTextHeader
    count >= 0 || throw(ArgumentError("count must be non-negative"))
    stanzas = String[]
    for _ in 1:count
        push!(stanzas, String(read(io, 3200)))
    end
    return ExtendedTextHeader(stanzas)
end
