# CLI Reference

The CLI entry point is [cli/main.jl](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/cli/main.jl:1).

Basic form:

```text
sbp <info|process|view|export> [args]
```

In this repository, invoke it with Julia:

```bash
julia cli/main.jl <command> ...
```

## `info`

Show a basic summary for a SEG-Y file.

```bash
julia cli/main.jl info line.segy
```

Current output includes:

- trace count
- samples per trace

## `process`

Run a workflow TOML file against an input SEG-Y and write a processed output SEG-Y.

```bash
julia cli/main.jl process input.segy docs/workflows/basic_processing.toml output.segy
```

Arguments:

- input SEG-Y path
- workflow TOML path
- output SEG-Y path

## `view`

Build a quick-look section specification and print a lightweight summary.

```bash
julia cli/main.jl view input.segy
```

This command currently reports:

- the generated plot kind
- the number of traces in the file

## `export`

Pick the water bottom and export picks.

```bash
julia cli/main.jl export input.segy picks.csv
```

Supported output formats follow the interpretation export layer:

- `.csv`
- `.geojson`
- `.shp`

## Workflow Files

Example workflow:

```toml
[[steps]]
name = "dc_removal"

[[steps]]
name = "gain"
mode = "agc"
window_samples = 16

[[steps]]
name = "bandpass"
smoothing_samples = 7
```

See [docs/workflows/basic_processing.toml](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/workflows/basic_processing.toml:1) and [docs/workflows/full_stack_workflow.toml](/home/mn/projects/sub-bottom-profiler/SubBottomProfiler.jl/docs/workflows/full_stack_workflow.toml:1).
