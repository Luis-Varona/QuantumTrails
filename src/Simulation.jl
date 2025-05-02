module Simulation

using LinearAlgebra
using Random

export WaveFunction, collapse!, step!, get_probabilities

mutable struct WaveFunction
    amps::Vector{ComplexF64}
    buf::Vector{ComplexF64}
    weights::Vector{ComplexF64}
    shifts::Vector{Int}
    collapse_rate::Float64

    function WaveFunction(n_steps::Int, n_states::Int, collapse_rate::Float64)
        shifts = _possible_shifts(n_states)
        n_positions = 2n_steps * maximum(shifts) + 1
        origin = div(n_positions + 1, 2)

        amps = zeros(ComplexF64, n_positions)
        @inbounds amps[origin] = 1.0
        buf = similar(amps)
        weights = _fourier_weights(n_states)

        return new(amps, buf, weights, shifts, collapse_rate)
    end
end

function _possible_shifts(n_states::Int)
    max_shift = div(n_states, 2)

    return if isodd(n_states)
        collect(-max_shift:max_shift)
    else
        vcat(-max_shift:-1, 1:max_shift)
    end
end

function _fourier_weights(n_states::Int)
    ω = exp(2π * im / n_states)
    return map(state -> ω^(state - 1) / sqrt(n_states), 1:n_states)
end

function collapse!(Ψ::WaveFunction)
    probs = abs2.(Ψ.amps)
    probs ./= sum(probs)
    fill!(Ψ.amps, 0.0)

    cdf = cumsum(probs)
    final = searchsortedfirst(cdf, rand())
    @inbounds Ψ.amps[final] = 1.0

    return Ψ
end

function step!(Ψ::WaveFunction)
    rand() <= Ψ.collapse_rate && return collapse!(Ψ)

    fill!(Ψ.buf, 0.0)

    for (a, amp) in enumerate(Ψ.amps), (s, shift) in enumerate(Ψ.shifts)
        if amp != 0.0
            @inbounds weight = Ψ.weights[s]
            @inbounds Ψ.buf[a + shift] += weight * amp
        end
    end

    normalize!(Ψ.buf)
    Ψ.amps, Ψ.buf = Ψ.buf, Ψ.amps

    return Ψ
end

function get_probabilities(Ψ::WaveFunction)
    probs = abs2.(Ψ.amps)
    threshold = sqrt(eps(Float64))
    probs[probs .< threshold] .= 0.0
    probs ./= sum(probs)
    origin = div(length(Ψ.amps), 2) + 1
    return Dict(i - origin => prob for (i, prob) in enumerate(probs) if prob > 0.0)
end

end
