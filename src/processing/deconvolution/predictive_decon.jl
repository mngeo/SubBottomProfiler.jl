"""
    PredictiveDeconParams

Predictive deconvolution configuration.

Example: `PredictiveDeconParams(prediction_gap_samples=4)`
"""
Base.@kwdef struct PredictiveDeconParams
    prediction_gap_samples::Int = 4
end

function process(traces::Vector{Trace}, params::PredictiveDeconParams)::Vector{Trace}
    params.prediction_gap_samples >= 1 || throw(ArgumentError("prediction_gap_samples must be positive"))
    outputs = Trace[]
    for trace in traces
        predicted = copy(trace.samples)
        for i in (params.prediction_gap_samples + 1):length(predicted)
            predicted[i] -= predicted[i - params.prediction_gap_samples]
        end
        push!(outputs, Trace(trace.header, predicted, trace.metadata))
    end
    return outputs
end

@register_step :predictive_decon PredictiveDeconParams
