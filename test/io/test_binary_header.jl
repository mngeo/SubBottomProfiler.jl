@testset "Binary Header" begin
    header = BinaryHeader(samples_per_trace=64, original_samples_per_trace=64, sample_interval_microseconds=250)
    io = IOBuffer()
    write_binary_header(io, header)
    seekstart(io)
    parsed = parse_binary_header(read(io, 400))
    @test parsed.samples_per_trace == 64
    @test parsed.sample_interval_microseconds == 250
end
