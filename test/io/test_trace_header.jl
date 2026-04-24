@testset "Trace Header" begin
    header = TraceHeader(sample_count=64, sample_interval_microseconds=250, source_x=10, source_y=20)
    io = IOBuffer()
    write_trace_header(io, header)
    seekstart(io)
    parsed = parse_trace_header(read(io, 240))
    @test parsed.sample_count == 64
    @test parsed.source_x == 10
end
