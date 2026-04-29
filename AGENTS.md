# AGENTS.md — SubBottomProfiler.jl

This file provides instructions and context for AI coding agents (e.g. Claude Code,
Copilot, Cursor) working inside this repository. Read it before making any changes.

---

## Project overview

`SubBottomProfiler.jl` is a Julia package for reading, processing, and interpreting
marine sub-bottom profiler (SBP) data stored in SEG-Y format (rev 1 and rev 2).

The package targets geophysicists and marine geologists who need a scriptable,
reproducible processing chain—from raw SEG-Y ingest through signal conditioning,
geometric correction, and seismic attribute extraction to horizon picking and figure
export—all within a single Julia environment.

---

## Repository layout (top-level)

```
SubBottomProfiler.jl/
├── AGENTS.md          ← you are here
├── src/               ← all library source code
│   ├── io/            ← SEG-Y I/O and data models
│   ├── model/         ← core data structs
│   ├── processing/    ← signal processing algorithms
│   ├── interpretation/← horizon picking, layer tracking
│   ├── visualization/ ← plotting and figure export
│   ├── pipeline/      ← composable workflow engine
│   └── utils/         ← shared math / DSP helpers
├── cli/               ← command-line interface entry points
├── test/              ← test suite (mirrors src/ layout)
├── docs/              ← Documenter.jl sources and workflow configs
└── notebooks/         ← Jupyter/Pluto tutorial notebooks
```

Detailed file-by-file descriptions are in `README.md`.

---

## Language and tooling conventions

| Concern | Convention |
|---|---|
| Language | Julia ≥ 1.10 |
| Package manager | Pkg.jl — edit `Project.toml` and `Manifest.toml` only via `Pkg` REPL |
| Testing | `Test.jl` standard library; run with `julia --project -e "using Pkg; Pkg.test()"` |
| Documentation | Documenter.jl; build with `julia --project docs/make.jl` |
| Formatting | JuliaFormatter.jl with `.JuliaFormatter.toml` at repo root; run before every commit |
| Linting | StaticLint.jl (IDE) — agents should not suppress lint warnings without explanation |
| CI | GitHub Actions in `.github/workflows/ci.yml` — do not modify CI files without a comment explaining why |

---

## Coding style rules

1. **Module boundaries are strict.** Every subdirectory under `src/` is its own Julia
   module with a `Module.jl` wrapper file (e.g. `src/io/SegyIO.jl`). Never `include`
   files from a sibling module directly—import the exported symbols instead.

2. **Type-stable functions only.** All public functions must be type-stable. Use
   `@code_warntype` to verify before submitting. Avoid `Any`-typed fields in structs.

3. **No global mutable state.** Processing state must live in structs passed as
   arguments. Do not use global `const` for anything other than physical constants
   and lookup tables.

4. **Struct field naming.** Use `snake_case` for all identifiers. Struct names use
   `PascalCase`. Module names use `PascalCase`.

5. **Docstrings are mandatory** for every exported function and struct. Follow the
   Julia docstring convention (`""" ... """`). Include arguments, return type, and a
   one-line example.

6. **Physical units must be documented.** Any function parameter representing a
   physical quantity (time, depth, frequency, velocity) must state its unit in the
   docstring and, where feasible, use a `Unitful.jl` quantity type.

7. **Error handling.** Use Julia exceptions (`throw(ArgumentError(...))`,
   `throw(DomainError(...))`, etc.). Never use bare `error()` strings for recoverable
   conditions. Validate SEG-Y header fields at parse time and emit structured warnings
   via the `Logging` standard library.

8. **No hard-coded file paths.** All paths must be passed as arguments or resolved
   relative to a project root determined at runtime.

---

## SEG-Y specifics

- The only supported input format is SEG-Y (rev 1 and rev 2). Do not add readers for
  other formats without opening a discussion issue first.
- The canonical source for field byte locations is the SEG-Y rev 2 standard (2017).
  The mapping is defined in `src/io/trace_header.jl` and `src/io/binary_header.jl`.
  Do not duplicate or shadow these mappings elsewhere.
- IBM 360 floating-point conversion lives exclusively in
  `src/io/data_sample_format.jl`. Use the exported `ibm2ieee` / `ieee2ibm` functions;
  do not re-implement the conversion in processing code.
- Navigation data (NMEA, P1/90, UKOOA) is ingested through `src/io/nav_parser.jl`
  and merged into trace headers via `src/processing/geometry/nav_merge.jl`. Do not
  read navigation strings anywhere else.

---

## Processing pipeline rules

- Every processing step must be implemented as a **pure function** of the form:
  `process(traces::Vector{Trace}, params::MyParams) -> Vector{Trace}`.
  The input vector must never be mutated; return a new vector.
- Processing parameters must be defined as a `struct` in the same file as the
  algorithm, with all fields having default values so that `MyParams()` always
  produces a valid default configuration.
- All steps must be registerable with the pipeline engine in `src/pipeline/pipeline.jl`
  via the `@register_step` macro. New algorithms without a registration entry will not
  be accessible from TOML workflow configs or the CLI.
- Performance-critical inner loops (sample-level operations) should use `@inbounds`
  and `@simd` where mathematically safe. Annotate with a comment explaining why it is
  safe.

### Gain-processing conventions

- `GainParams` is the generic gain operator. Use it for:
  - `mode = "agc"` when local amplitude normalization is explicitly desired
  - `mode = "linear"` or `mode = "exponential"` for simple display-oriented gain ramps
- `TvgParams` is the physical time-varying gain operator. Use it when gain must be
  tied to acquisition geometry and propagation assumptions rather than sample index
  alone.
- AGC and TVG are **not interchangeable**. Do not present `GainParams(mode="agc")`
  as a substitute for `TvgParams` in code, docs, or examples.
- AGC should be treated as a local normalization step that can suppress relative
  reflector-amplitude contrasts. In seabed- or reflector-picking workflows, document
  clearly whether AGC is applied before picking, after picking, or only for display.
- TVG parameters must remain physically documented:
  - `sound_velocity_m_per_s` is in meters per second
  - `reference_depth_m` is in meters
  - `absorption_db_per_m` is in decibels per meter
  - any spreading-law exponent must be described as an amplitude-domain exponent
- If a workflow depends on water-bottom position before depth-aware gain correction,
  require that dependency explicitly. Do not hide seabed detection or depth reference
  estimation inside TVG code.
- If AGC or TVG behavior changes, update:
  - `README.md`
  - `docs/src/processing_reference.md`
  - any affected workflow examples under `docs/` or `README.md`

### Amplitude-thresholding conventions

- `AmplitudeThresholdParams` is the sample-level amplitude muting operator. Use it
  when weak residual amplitudes should be zeroed or shrunk before later steps such as
  stacking, AGC, or picking.
- Treat this step as an amplitude-domain threshold, not a time-window mute. Do not
  overload `MuteParams` or `TraceEditingParams` to implement the same behavior.
- `mode = "hard"` should set sub-threshold samples to numerical zero.
- `mode = "soft"` should attenuate sub-threshold samples toward zero without
  introducing sign changes.
- `threshold_percent` must be documented as a percentage of the selected reference.
- `reference = "trace_max"` and `reference = "trace_rms"` are not equivalent:
  - `trace_max` is appropriate when preserving only the strongest events is the goal
  - `trace_rms` is appropriate when thresholding should track broader trace energy
- In examples and workflows, be explicit about placement:
  - pre-stack thresholding suppresses low-level energy before coherent stacking
  - post-stack thresholding acts on already-averaged traces and behaves differently
- Document the risk that aggressive thresholding can erase weak real reflectors,
  especially if the result is used for interpretation rather than display-only
  quick looks.

### Band-pass filtering conventions

- `BandpassParams` is the canonical band-pass filter implementation. Do not describe
  it as a smoothing proxy in new docs or code comments; it is a real FFT-domain
  frequency-selective filter.
- Low and high cutoffs must be specified in hertz. New docstrings, examples, and
  workflow files must state that explicitly.
- Filter validity depends on the trace sample interval:
  - reject or document cutoffs at or above Nyquist
  - be cautious with cutoffs below the effective frequency resolution of the trace
  - when discussing results, distinguish between theoretical requested cutoff and
    practical resolvable cutoff
- `smoothing_samples` in `BandpassParams` is the taper half-width controlling the
  transition around low/high cutoff edges. Treat it as part of the spectral taper,
  not as a time-domain smoothing window.
- When a workflow combines band-pass filtering with thresholding, stacking, AGC, or
  picking, document the order explicitly because the order materially affects the
  outcome.
- If the implementation or interpretation of `BandpassParams` changes, update:
  - `README.md`
  - `docs/src/processing_reference.md`
  - any affected workflow examples under `docs/` or `README.md`

### Stacking conventions

- `MeanStackParams` is the canonical trace-stacking interface for grouped averaging.
  Use it instead of ad hoc local stack helpers in package code, docs, or examples.
- Supported stacking modes must remain explicit:
  - `mode = "blind"` for non-overlapping bins such as traces `1:10`, `11:20`, `21:30`
  - `mode = "running"` for sliding windows controlled by `stack_size` and `step_size`
- Document the distinction between stack window size and step size. A running stack
  with `stack_size = 10` and `step_size = 1` is not equivalent to a blind 10-trace
  stack.
- `method = "mean"` and `method = "median"` have different noise behavior:
  - `mean` is the default coherent-energy stack
  - `median` is more robust to isolated outliers but should not be described as the
    same operation
- Stacking changes trace count and spatial sampling. Do not describe it as a
  trace-preserving display filter or as a no-op smoothing step.
- Output traces from stacking should preserve or attach trace-span metadata needed by
  later interpretation and export. For grouped stacks this includes, at minimum:
  - `:stack_fold`
  - `:stack_start_trace`
  - `:stack_end_trace`
- When stacking appears in a workflow, document its order relative to band-pass
  filtering, amplitude thresholding, AGC, and picking, since moving the stack step
  changes both amplitudes and interpretation behavior.
- If stacking behavior or parameters change, update:
  - `README.md`
  - `docs/src/processing_reference.md`
  - any affected workflow examples under `docs/` or `README.md`

---

## Interpretation module rules

- Horizon picks are stored as `HorizonPick` structs (defined in
  `src/interpretation/horizon_picker.jl`). Never store picks as raw arrays of
  floats—use the struct so provenance, confidence, and trace index are preserved.
- Water-bottom detection (`src/interpretation/water_bottom_picker.jl`) is a
  prerequisite for depth conversion. Any algorithm that requires a water-bottom
  reference must accept it as an explicit argument, not auto-detect it internally.
- ML hooks in `src/interpretation/seismic_facies.jl` use a `Flux.jl`-compatible
  model interface. Do not pin a specific Flux version—keep the interface generic so
  the user can supply any callable.

---

## Visualization rules

- All plot functions must accept an optional `Makie.Axis` argument so plots can be
  embedded into larger figure layouts. Never create a `Figure` implicitly inside a
  plotting function. The one exception is the explicit convenience helper
  `display_wiggle(...)`, which is allowed to create and display a `Makie.Figure`
  because its purpose is interactive screen display rather than plot construction.
- File-oriented plot builders should return `PlotSpec` values with enough metadata to
  support later overlays and export logic. For wiggle plots this includes, at minimum,
  `:trace_count`, `:sample_count`, and any rendering-mode flags needed by downstream
  helpers.
- Keep the SVG-backed and Makie-backed wiggle APIs behaviorally aligned. If a wiggle
  rendering option is added in one backend, update the other backend in the same
  change unless there is a documented technical reason not to.
- Wiggle variable-area shading must be controlled through the explicit
  `shade_side = :positive | :negative | :none` convention. The legacy
  `fill_positive` keyword may be retained for compatibility, but new examples and new
  code should use `shade_side`.
- Default colourmaps are defined in `src/visualization/colormaps.jl`. Do not use
  Makie built-in colourmap names directly in algorithm files—always reference the
  package's exported colourmap constants so they can be changed centrally.
- `export_figure.jl` must support at minimum PNG (300 dpi), SVG, and PDF output.
  Do not add raster-only export paths.

---

## Testing requirements

- **Every public function must have at least one unit test** in the corresponding
  `test/` file (e.g. a function in `src/processing/filter/bandpass.jl` is tested in
  `test/processing/test_filters.jl`).
- Synthetic SEG-Y fixtures are generated by `test/fixtures/generate_synthetic.jl`.
  Do not commit large binary test files. If a test requires a real SEG-Y file, add it
  to `.gitignore` and document the download source in the test file header comment.
- Integration tests that run a full pipeline end-to-end live in
  `test/pipeline/test_pipeline.jl`. They are tagged `@tag :slow` and are excluded
  from the default CI run (fast tests only). Run them locally with
  `julia --project -e "using Pkg; Pkg.test(; test_args=[\"--slow\"])"`.
- Test coverage target: ≥ 85 % line coverage across `src/`. Coverage is reported in
  CI via `Coverage.jl`.

---

## How to add a new processing algorithm

1. Create `src/processing/<subsystem>/my_algorithm.jl`.
2. Define a `MyAlgorithmParams` struct with typed, defaulted fields and a docstring.
3. Implement `process(traces, params::MyAlgorithmParams) -> Vector{Trace}`.
4. Export the function and params struct from `src/processing/Processing.jl`.
5. Register the step in `src/pipeline/pipeline.jl` using `@register_step`.
6. Add tests in `test/processing/test_<subsystem>.jl`.
7. Add a docstring entry under `docs/src/processing_reference.md`.

---

## How to add a new CLI command

1. Create `cli/commands/cmd_<name>.jl`.
2. Define a `run_<name>(args)` function that validates arguments and calls into `src/`.
3. Register the subcommand in `cli/cli.jl` under the `ArgParse` table.
4. Document usage in `docs/src/cli_reference.md`.

---

## Dependency policy

- Prefer Julia standard library and registered General registry packages.
- New dependencies require an explicit comment in `Project.toml` explaining why the
  dependency is needed and what it replaces.
- Do not add Python, R, or C extension dependencies. If a C library is unavoidable,
  wrap it with a `_jll` artifact package.
- Heavy optional dependencies (e.g. `Flux.jl` for ML facies classification,
  `GLMakie.jl` for interactive display) must be declared as weak dependencies in
  `Project.toml` using the `[extensions]` mechanism introduced in Julia 1.9.

---

## Commit message format

```
<type>(<scope>): <short summary>

<body — optional, wrap at 72 chars>

Refs: #<issue>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`.
Scope mirrors the `src/` subdirectory name (e.g. `io`, `processing`, `interpretation`).

---

## What agents should NOT do

- Do not reformat files that are not being otherwise modified (run the formatter only
  on files touched by your change).
- Do not remove or weaken type annotations to silence compiler warnings.
- Do not bypass the pipeline registration system by calling processing functions
  directly from CLI code.
- Do not add `Revise.jl` or development-only packages to the main `[deps]` block.
- Do not commit `Manifest.toml` changes unless you have intentionally updated a
  dependency version and have confirmed tests pass.

---

## Glossary

| Term | Meaning |
|---|---|
| SBP | Sub-bottom profiler — acoustic system for imaging sediment layers below the seafloor |
| SEG-Y | Society of Exploration Geophysicists Y format — binary seismic data standard |
| Trace | Single acoustic pulse record (header + amplitude sample array) |
| CDP / CMP | Common depth point / common midpoint — binning concept for multi-channel data |
| TWTt | Two-way travel time — vertical axis unit in SBP sections (milliseconds) |
| AGC | Automatic gain control — time-variant amplitude normalisation |
| NMO | Normal moveout — correction for source–receiver offset in reflection timing |
| F-K | Frequency–wavenumber domain — used for directional noise filtering |
