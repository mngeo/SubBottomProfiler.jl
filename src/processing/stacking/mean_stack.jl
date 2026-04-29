"""
    MeanStackParams

Mean/median stacking configuration.

Arguments:
- `method`: sample reducer (`"mean"` or `"median"`).
- `mode`: stacking layout (`"blind"` or `"running"`).
- `stack_size`: number of traces per stack window.
- `step_size`: trace increment between adjacent output windows. Defaults to
  `stack_size`, which yields non-overlapping blind bins.

Example: `MeanStackParams(method="mean", mode="blind", stack_size=10)`
"""
Base.@kwdef struct MeanStackParams
    method::String = "mean"
    mode::String = "blind"
    stack_size::Int = 1
    step_size::Int = 0
end

function process(traces::Vector{Trace}, params::MeanStackParams)::Vector{Trace}
    isempty(traces) && return Trace[]
    params.stack_size > 0 || throw(ArgumentError("stack_size must be positive"))
    step_size = params.step_size == 0 ? params.stack_size : params.step_size
    step_size > 0 || throw(ArgumentError("step_size must be positive"))
    sample_count = length(first(traces).samples)
    all(length(trace.samples) == sample_count for trace in traces) || throw(ArgumentError("all traces must have the same sample count"))

    windows = _stack_windows(length(traces), params.mode, params.stack_size, step_size)
    stacked = Trace[]
    for (stack_index, (start_index, stop_index)) in enumerate(windows)
        chunk = @view traces[start_index:stop_index]
        samples = _stack_samples(chunk, sample_count, params.method)
        header = _stack_header(chunk, stack_index, start_index, stop_index)
        metadata = Dict(
            :stack_fold => Float64(length(chunk)),
            :stack_start_trace => Float64(start_index),
            :stack_end_trace => Float64(stop_index),
        )
        push!(stacked, Trace(header, samples, metadata))
    end
    return stacked
end

function _stack_windows(trace_count::Int, mode::String, stack_size::Int, step_size::Int)::Vector{Tuple{Int, Int}}
    windows = Tuple{Int, Int}[]
    if mode == "blind"
        for start_index in 1:step_size:trace_count
            stop_index = min(trace_count, start_index + stack_size - 1)
            push!(windows, (start_index, stop_index))
        end
    elseif mode == "running"
        last_start = max(1, trace_count - stack_size + 1)
        for start_index in 1:step_size:last_start
            stop_index = min(trace_count, start_index + stack_size - 1)
            push!(windows, (start_index, stop_index))
        end
        if isempty(windows)
            push!(windows, (1, trace_count))
        end
    else
        throw(ArgumentError("unsupported stack mode $(mode)"))
    end
    return windows
end

function _stack_samples(chunk, sample_count::Int, method::String)::Vector{Float64}
    if method == "median"
        return [median([trace.samples[i] for trace in chunk]) for i in 1:sample_count]
    elseif method == "mean"
        return [mean([trace.samples[i] for trace in chunk]) for i in 1:sample_count]
    end
    throw(ArgumentError("unsupported stack method $(method)"))
end

function _stack_header(chunk, stack_index::Int, start_index::Int, stop_index::Int)::TraceHeader
    first_header = first(chunk).header
    return TraceHeader(
        trace_sequence_line = Int32(stack_index),
        trace_sequence_file = Int32(stack_index),
        field_record = first_header.field_record,
        trace_number_within_field_record = Int32(stack_index),
        source_x = Int32(round(mean([trace.header.source_x for trace in chunk]))),
        source_y = Int32(round(mean([trace.header.source_y for trace in chunk]))),
        group_x = Int32(round(mean([trace.header.group_x for trace in chunk]))),
        group_y = Int32(round(mean([trace.header.group_y for trace in chunk]))),
        offset_meters = mean([trace.header.offset_meters for trace in chunk]),
        sample_count = first_header.sample_count,
        sample_interval_microseconds = first_header.sample_interval_microseconds,
        scalco = first_header.scalco,
        scalel = first_header.scalel,
        coordinate_units = first_header.coordinate_units,
        extra = Dict{Symbol, Int64}(
            :stack_fold => Int64(length(chunk)),
            :stack_start_trace => Int64(start_index),
            :stack_end_trace => Int64(stop_index),
        ),
    )
end

@register_step :mean_stack MeanStackParams
