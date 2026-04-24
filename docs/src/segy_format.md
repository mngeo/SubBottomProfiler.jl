```@meta
CurrentModule = SubBottomProfiler
```

# SEG-Y Format Support

```@setup segy
using SubBottomProfiler
```

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

The [`BinaryHeader`](@ref) struct stores:

- sample interval in microseconds
- sample count per trace
- sample format code
- SEG-Y revision
- fixed-length trace flag
- extended text header count

See [`BinaryHeader`](@ref) for the data type. The low-level binary-header I/O functions are documented here:

```@docs
parse_binary_header
write_binary_header
```

## Trace Header

The [`TraceHeader`](@ref) struct stores representative per-trace fields:

- trace sequence numbers
- field-record linkage
- source and group coordinates
- offset
- sample count
- sample interval
- scaling and coordinate units

See [`TraceHeader`](@ref) for the data type. The low-level trace-header I/O functions are documented here:

```@docs
parse_trace_header
write_trace_header
```

## Reading And Writing Files

```@docs
read_segy
write_segy
```

## Sample Conversion

The IBM conversion helpers are exported from the root package and are the canonical conversion path used by the I/O layer.

```@docs
ibm2ieee
ieee2ibm
```

## Navigation Parsing

Navigation input is currently exposed from the `SegyIO` submodule and expects a simplified CSV-like record:

```text
trace_index,longitude_deg,latitude_deg,ISO8601_timestamp
```

```@example segy
points = SegyIO.parse_navigation([
    "1,12.34,54.32,2024-01-01T00:00:00",
    "2,12.35,54.33,2024-01-01T00:00:01",
])

length(points)
```

## Limitations

- not all SEG-Y rev 2 fields are implemented
- the reader targets the current package structs rather than the full standard surface
- navigation parsing is intentionally simplified
