# SEG-Y Format Support

## Implemented Coverage

`SubBottomProfiler.jl` currently implements a simplified SEG-Y reader and writer with:

- 3200-byte textual header support
- 400-byte binary header parsing and writing
- 240-byte trace header parsing and writing
- extended textual header stanza reading
- trace sample reading and writing for formats `1`, `3`, and `5`

Supported sample formats:

- `1`: IBM floating-point
- `3`: 16-bit integer
- `5`: IEEE floating-point

## Binary Header

The `BinaryHeader` struct stores:

- sample interval in microseconds
- sample count per trace
- sample format code
- SEG-Y revision
- fixed-length trace flag
- extended text header count

Example:

```julia
header = BinaryHeader(
    sample_interval_microseconds = 250,
    samples_per_trace = 256,
    data_sample_format = 5,
)
```

Low-level round-trip:

```julia
io = IOBuffer()
write_binary_header(io, header)
seekstart(io)
parsed = parse_binary_header(read(io, 400))
```

## Trace Header

The `TraceHeader` struct stores representative per-trace fields:

- trace sequence numbers
- field-record linkage
- source and group coordinates
- offset
- sample count
- sample interval
- scaling and coordinate units

Example:

```julia
trace_header = TraceHeader(
    trace_sequence_line = 1,
    trace_sequence_file = 1,
    source_x = 1000,
    source_y = 2000,
    group_x = 1010,
    group_y = 2020,
    sample_count = 512,
    sample_interval_microseconds = 250,
)
```

## Reading A File

```julia
dataset = read_segy("line.segy")

println(dataset.binary_header.data_sample_format)
println(dataset.binary_header.samples_per_trace)
println(dataset.traces[1].header.sample_count)
```

## Writing A File

```julia
write_segy("line_out.segy", dataset)
```

## Sample Conversion

The IBM conversion helpers are exported from the root package and should be the single conversion path:

```julia
word = ieee2ibm(1.25)
value = ibm2ieee(word)
```

## Navigation Parsing

Navigation input is currently a simplified CSV-like text parser expecting:

```text
trace_index,longitude_deg,latitude_deg,ISO8601_timestamp
```

Example:

```julia
points = SegyIO.parse_navigation([
    "1,12.34,54.32,2024-01-01T00:00:00",
    "2,12.35,54.33,2024-01-01T00:00:01",
])
```

## Limitations

- not all SEG-Y rev 2 fields are implemented
- the reader targets the package’s current binary and trace header structs
- navigation parsing is intentionally simplified
