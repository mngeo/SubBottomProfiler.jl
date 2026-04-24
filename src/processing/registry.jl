const STEP_REGISTRY = Dict{Symbol, DataType}()

"""
    process(traces::Vector{Trace}, params) -> Vector{Trace}

Dispatch entry point for pure trace processing steps.

Example: `process(traces, GainParams())`
"""
function process(traces::Vector{Trace}, params)
    throw(ArgumentError("no processing implementation registered for $(typeof(params))"))
end

"""
    process_dataset(dataset::Dataset, params) -> Dataset

Apply a registered processing step to a dataset.

Example: `process_dataset(dataset, GainParams())`
"""
function process_dataset(dataset::Dataset, params)::Dataset
    return Dataset(dataset.binary_header, dataset.textual_header, dataset.extended_header, process(dataset.traces, params), dataset.geometry)
end

function register_step!(name::Symbol, params_type::DataType)::Nothing
    STEP_REGISTRY[name] = params_type
    return nothing
end

macro register_step(name, params_type)
    step_name = name isa QuoteNode ? name.value : name
    return esc(:(register_step!($(Expr(:quote, step_name)), $params_type)))
end

"""
    describe_registered_steps() -> Dict{Symbol, DataType}

Return the pipeline step registry.

Example: `describe_registered_steps()`
"""
describe_registered_steps()::Dict{Symbol, DataType} = copy(STEP_REGISTRY)

"""
    instantiate_registered_step(name::Symbol; kwargs...) -> Any

Instantiate a registered parameter struct by keyword arguments.

Example: `instantiate_registered_step(:gain; mode="agc")`
"""
function instantiate_registered_step(name::Symbol, kwargs::Dict{Symbol, String})
    haskey(STEP_REGISTRY, name) || throw(KeyError(name))
    params_type = STEP_REGISTRY[name]
    converted = Pair{Symbol, Any}[]
    for field_name in fieldnames(params_type)
        if haskey(kwargs, field_name)
            target_type = fieldtype(params_type, field_name)
            push!(converted, field_name => _coerce_workflow_value(kwargs[field_name], target_type))
        end
    end
    return params_type(; converted...)
end

function _coerce_workflow_value(value::String, ::Type{String})
    return value
end

function _coerce_workflow_value(value::String, ::Type{Int})
    return parse(Int, value)
end

function _coerce_workflow_value(value::String, ::Type{Int16})
    return Int16(parse(Int, value))
end

function _coerce_workflow_value(value::String, ::Type{Int32})
    return Int32(parse(Int, value))
end

function _coerce_workflow_value(value::String, ::Type{Float64})
    return parse(Float64, value)
end

function _coerce_workflow_value(value::String, ::Type{Bool})
    return lowercase(value) == "true"
end
