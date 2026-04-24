Here's the full plan for a sub-bottom profiler SEG-Y processing and interpretation software in Julia.
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation-duration: 0.25s;
    animation-timing-function: cubic-bezier(0.19, 1, 0.22, 1);
  }
VvisualizeVvisualize show_widget
Project: SubBottomProfiler.jl
A Julia package for SEG-Y-based sub-bottom profiler data processing and interpretation.

Folder structure
SubBottomProfiler.jl/
│
├── AGENTS.md
├── README.md
├── LICENSE
├── Project.toml
├── Manifest.toml
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── docs.yml
│
├── src/
│   ├── SubBottomProfiler.jl          # Package root, exports
│   │
│   ├── io/
│   │   ├── SegyIO.jl                 # Module wrapper for I/O sub-system
│   │   ├── segy_reader.jl            # SEG-Y rev 1 & rev 2 byte-stream reader
│   │   ├── segy_writer.jl            # SEG-Y output writer
│   │   ├── binary_header.jl          # Binary file-header parsing & validation
│   │   ├── trace_header.jl           # 240-byte trace header parsing (all fields)
│   │   ├── extended_header.jl        # SEG-Y rev 2 extended textual headers
│   │   ├── data_sample_format.jl     # IBM float, IEEE float, int16/32 codecs
│   │   └── nav_parser.jl             # Navigation / positioning data ingest
│   │
│   ├── model/
│   │   ├── SegyModel.jl              # Module wrapper
│   │   ├── trace_model.jl            # Trace struct (header + samples + metadata)
│   │   ├── dataset_model.jl          # Dataset struct (collection of traces + geometry)
│   │   ├── header_model.jl           # Typed header field enums & constants
│   │   └── geometry_model.jl         # Survey geometry: CDP, shot, receiver positions
│   │
│   ├── processing/
│   │   ├── Processing.jl             # Module wrapper, processing registry
│   │   │
│   │   ├── preprocess/
│   │   │   ├── gain.jl               # AGC, TVG, exponential gain
│   │   │   ├── mute.jl               # Top mute, surgical mute, tapers
│   │   │   ├── dc_removal.jl         # DC bias removal
│   │   │   └── trace_editing.jl      # Kill, reverse, resample, pad
│   │   │
│   │   ├── filter/
│   │   │   ├── bandpass.jl           # Butterworth / Ormsby bandpass
│   │   │   ├── notch_filter.jl       # Notch filter for electrical noise
│   │   │   ├── fk_filter.jl          # F-K (frequency–wavenumber) filter
│   │   │   └── median_filter.jl      # Spatial median filter for random noise
│   │   │
│   │   ├── deconvolution/
│   │   │   ├── spiking_decon.jl      # Spiking (whitening) deconvolution
│   │   │   ├── predictive_decon.jl   # Predictive / gapped deconvolution
│   │   │   ├── wiener_filter.jl      # Wiener–Levinson deconvolution
│   │   │   └── wavelet_estimation.jl # Statistical & deterministic wavelet extraction
│   │   │
│   │   ├── geometry/
│   │   │   ├── nav_merge.jl          # Merge navigation into trace headers
│   │   │   ├── binning.jl            # CDP/CMP binning
│   │   │   ├── sorting.jl            # Ensemble sort (shot, CDP, offset)
│   │   │   └── offset_calculation.jl # Source–receiver offset computation
│   │   │
│   │   ├── velocity/
│   │   │   ├── velocity_model.jl     # 1-D & 2-D velocity model structs
│   │   │   ├── semblance.jl          # Semblance / velocity spectrum computation
│   │   │   └── nmo_correction.jl     # Normal moveout correction & stretch mute
│   │   │
│   │   ├── stacking/
│   │   │   ├── mean_stack.jl         # Mean / median / weighted stack
│   │   │   └── diversity_stack.jl    # Diversity / robust stack
│   │   │
│   │   ├── migration/
│   │   │   ├── kirchhoff_migration.jl  # Post-stack Kirchhoff time migration
│   │   │   └── fk_migration.jl         # Stolt F-K migration
│   │   │
│   │   └── attributes/
│   │       ├── envelope.jl           # Instantaneous amplitude (Hilbert)
│   │       ├── instantaneous_phase.jl
│   │       ├── instantaneous_freq.jl
│   │       ├── rms_amplitude.jl
│   │       └── reflection_strength.jl
│   │
│   ├── interpretation/
│   │   ├── Interpretation.jl         # Module wrapper
│   │   ├── horizon_picker.jl         # Manual & auto horizon picking
│   │   ├── layer_tracker.jl          # Seismic layer tracking / correlation
│   │   ├── reflector_strength.jl     # Reflector continuity & strength metrics
│   │   ├── seismic_facies.jl         # Facies classification (rules-based + ML hooks)
│   │   ├── water_bottom_picker.jl    # Automatic water-bottom detection
│   │   ├── velocity_analysis.jl      # Interactive velocity picking interface
│   │   └── export_interpretation.jl  # Export picks to CSV / shapefile / GeoJSON
│   │
│   ├── visualization/
│   │   ├── Visualization.jl          # Module wrapper
│   │   ├── wiggle_plot.jl            # Wiggle + variable-area trace display
│   │   ├── seismic_section.jl        # 2-D seismic section image (grayscale / colour)
│   │   ├── spectrum_plot.jl          # Amplitude & phase spectrum display
│   │   ├── velocity_panel.jl         # Semblance panel + pick overlay
│   │   ├── annotation_overlay.jl     # Horizon / label / scale-bar overlays
│   │   ├── colormaps.jl              # SBP-specific colourmaps (seismic, depth)
│   │   └── export_figure.jl          # PNG / SVG / PDF figure export
│   │
│   ├── pipeline/
│   │   ├── Pipeline.jl               # Module wrapper
│   │   ├── pipeline.jl               # Composable processing pipeline struct
│   │   ├── workflow.jl               # Named workflow definitions (TOML-driven)
│   │   ├── scheduler.jl              # Parallel / threaded execution scheduler
│   │   └── progress.jl               # Progress reporting & logging hooks
│   │
│   └── utils/
│       ├── Utils.jl                  # Module wrapper
│       ├── math_utils.jl             # Interpolation, windowing, taper functions
│       ├── dsp_utils.jl              # Convolution, correlation, Hilbert transform
│       ├── fft_utils.jl              # FFT helpers, zero-padding, frequency axes
│       ├── statistics_utils.jl       # Robust statistics for trace analysis
│       └── unit_conversion.jl        # Two-way time ↔ depth, m/s ↔ ft/s
│
├── cli/
│   ├── main.jl                       # Entry point for command-line execution
│   ├── cli.jl                        # Argument parsing (ArgParse.jl)
│   ├── commands/
│   │   ├── cmd_info.jl               # `sbp info <file.segy>` – header summary
│   │   ├── cmd_process.jl            # `sbp process` – run workflow
│   │   ├── cmd_view.jl               # `sbp view` – quick-look display
│   │   └── cmd_export.jl             # `sbp export` – convert / extract
│   └── config.jl                     # TOML workflow config loader & validator
│
├── test/
│   ├── runtests.jl                   # Test suite entry point
│   ├── fixtures/
│   │   ├── generate_synthetic.jl     # Synthetic SEG-Y fixture generator
│   │   ├── sample_rev1.segy          # Minimal SEG-Y rev 1 test file
│   │   └── sample_rev2.segy          # Minimal SEG-Y rev 2 test file
│   ├── io/
│   │   ├── test_segy_reader.jl
│   │   ├── test_segy_writer.jl
│   │   ├── test_binary_header.jl
│   │   ├── test_trace_header.jl
│   │   └── test_data_sample_format.jl
│   ├── processing/
│   │   ├── test_gain.jl
│   │   ├── test_filters.jl
│   │   ├── test_deconvolution.jl
│   │   ├── test_nmo.jl
│   │   ├── test_stacking.jl
│   │   ├── test_migration.jl
│   │   └── test_attributes.jl
│   ├── interpretation/
│   │   ├── test_horizon_picker.jl
│   │   └── test_water_bottom.jl
│   ├── pipeline/
│   │   └── test_pipeline.jl
│   └── utils/
│       ├── test_dsp_utils.jl
│       └── test_fft_utils.jl
│
├── docs/
│   ├── make.jl                       # Documenter.jl build script
│   ├── src/
│   │   ├── index.md
│   │   ├── getting_started.md
│   │   ├── segy_format.md
│   │   ├── processing_reference.md
│   │   ├── interpretation_guide.md
│   │   ├── cli_reference.md
│   │   └── api/                      # Auto-generated API pages
│   └── workflows/
│       ├── basic_processing.toml     # Example workflow config
│       └── full_stack_workflow.toml
│
└── notebooks/
    ├── 01_read_segy.ipynb
    ├── 02_basic_processing.ipynb
    ├── 03_deconvolution.ipynb
    ├── 04_interpretation.ipynb
    └── 05_visualization.ipynb

Now generating the AGENTS.md file:Created a file, read a fileCreated a file, read a file
Design decisions worth noting
Module isolation. Each subdirectory under src/ is a self-contained Julia module. The Processing.jl wrapper re-exports everything so the user sees a flat API, but internally the subsystems (filter, deconvolution, geometry, etc.) can't accidentally call each other without going through the public interface.
Pipeline-first architecture. Every algorithm is a pure process(traces, params) -> traces function registered with the pipeline engine. This means workflows can be defined entirely in TOML without writing Julia, and individual steps are trivially unit-testable in isolation.
Weak dependencies for heavy backends. GLMakie.jl (interactive display), Flux.jl (ML facies), and any GPU extension live in the [extensions] block—they load only when the user explicitly brings them in, keeping the base package fast to precompile.
SEG-Y as the single source of truth. All I/O funnels through src/io/. IBM float conversion, byte-location constants, and header field semantics live there and nowhere else, preventing silent misalignments when the standard's byte map is referenced in multiple places.
