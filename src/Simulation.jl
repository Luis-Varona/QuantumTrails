# Copyright 2025 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

module Simulation

using LinearAlgebra
using Random
using SparseArrays

export WaveFunctionWrapper, StepData, collapse!, step!, get_step_data

mutable struct WaveFunctionWrapper
    amps::Vector{ComplexF64}
    buf::Vector{ComplexF64}
    paths::SparseMatrixCSC{Bool,Int}
    weights::Vector{ComplexF64}
    shifts::Vector{Int}
    origin::Int
    collapse_rate::Float64

    function WaveFunctionWrapper(n_steps::Int, n_states::Int, collapse_rate::Float64)
        shifts = _possible_shifts(n_states)
        n_positions = 2n_steps * maximum(shifts) + 1
        origin = div(n_positions + 1, 2)

        amps = zeros(ComplexF64, n_positions)
        @inbounds amps[origin] = 1.0
        buf = similar(amps)
        paths = spzeros(Bool, n_positions, n_positions)
        weights = _fourier_weights(n_states)

        return new(amps, buf, paths, weights, shifts, origin, collapse_rate)
    end
end

struct StepData
    probs::Dict{Int,Float64}
    paths::Dict{Int,Vector{Int}}
end

function _possible_shifts(n_states::Int)
    max_shift = div(n_states, 2)

    return if isodd(n_states)
        collect((-max_shift):max_shift)
    else
        vcat((-max_shift):-1, 1:max_shift)
    end
end

function _fourier_weights(n_states::Int)
    ω = exp(2π * im / n_states)
    return map(state -> ω^(state - 1) / sqrt(n_states), 1:n_states)
end

function collapse!(Ψ::WaveFunctionWrapper)
    probs = abs2.(Ψ.amps)
    fill!(Ψ.amps, 0.0)
    Ψ.paths.nzval .= false
    dropzeros!(Ψ.paths)

    cdf = cumsum(probs)
    final = searchsortedfirst(cdf, rand())
    @inbounds Ψ.amps[final] = 1.0
    @inbounds Ψ.paths[findall(!iszero, probs), final] .= true

    return Ψ
end

function step!(Ψ::WaveFunctionWrapper)
    rand() <= Ψ.collapse_rate && return collapse!(Ψ)

    fill!(Ψ.buf, 0.0)
    Ψ.paths.nzval .= false
    dropzeros!(Ψ.paths)

    for (src, amp) in enumerate(Ψ.amps), (i, shift) in enumerate(Ψ.shifts)
        if amp != 0.0
            dst = src + shift
            Ψ.paths[src, dst] = true
            @inbounds weight = Ψ.weights[i]
            @inbounds Ψ.buf[dst] += weight * amp
        end
    end

    Ψ.buf[abs2.(Ψ.buf) .< eps(Float64)] .= 0.0
    normalize!(Ψ.buf)
    Ψ.amps, Ψ.buf = Ψ.buf, Ψ.amps

    return Ψ
end

function get_step_data(Ψ::WaveFunctionWrapper)
    centre(k::Int) = k - Ψ.origin

    prob_vec = abs2.(Ψ.amps)
    probs = Dict(centre(i) => prob for (i, prob) in enumerate(prob_vec) if prob != 0.0)

    dsts_vec = map.(centre, findall.(!iszero, eachrow(Ψ.paths)))
    paths = Dict(centre(i) => dsts for (i, dsts) in enumerate(dsts_vec) if !isempty(dsts))

    return StepData(probs, paths)
end

end
