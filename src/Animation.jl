# Copyright 2025 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

module Animation

# There are bugs precompiling `CairoMakie.jl` on x86 architecture in CI testing
haskey(ENV, "CI") || using CairoMakie

export WalkAnimator, update_anim!

mutable struct WalkAnimator
    scene::Scene
    time::Int
    x_scale::Float64
    y_scale::Float64
    y_offset::Float64
    mkr_colormap::Symbol
    mkr_colorrange::Tuple{Float64,Float64}
    mkr_size::Int
    line_alpha::Float64
    line_color::Symbol
    line_width::Float64

    function WalkAnimator(
        n_steps::Int,
        n_states::Int,
        width::Int,
        height::Int,
        bgcolor::Symbol,
        mkr_colormap::Symbol,
        mkr_colorrange::Tuple{Float64,Float64},
        mkr_size::Int,
        line_alpha::Float64,
        line_color::Symbol,
        line_width::Float64,
    )
        time = 0

        max_shift = div(n_states, 2)
        n_positions = 2n_steps * max_shift + 1
        origin = div(n_positions + 1, 2)

        x_scale = 0.98width / (n_steps + 2)
        y_scale = 0.98height / (n_positions + 2)

        y_offset = y_scale * (1 + (origin - 1))

        xs = [x_scale]
        ys = [y_offset]
        colors = [1.0]

        scene = Scene(; size=(width, height), backgroundcolor=bgcolor)
        campixel!(scene)
        scatter!(
            scene,
            xs,
            ys;
            color=colors,
            colormap=mkr_colormap,
            colorrange=mkr_colorrange,
            markersize=mkr_size,
        )

        return new(
            scene,
            time,
            x_scale,
            y_scale,
            y_offset,
            mkr_colormap,
            mkr_colorrange,
            mkr_size,
            line_alpha,
            line_color,
            line_width,
        )
    end
end

function update_anim!(
    anim::WalkAnimator, probs::Dict{Int,Float64}, paths::Dict{Int,Vector{Int}}
)
    anim.time += 1

    x = (anim.time + 1) * anim.x_scale
    xs = fill(x, length(probs))
    ys = keys(probs) .* anim.y_scale .+ anim.y_offset
    colors = map(sqrt, values(probs))
    scatter!(
        anim.scene,
        xs,
        ys;
        color=colors,
        colormap=anim.mkr_colormap,
        colorrange=anim.mkr_colorrange,
        markersize=anim.mkr_size,
    )

    for (src, dsts) in paths
        y1 = src * anim.y_scale + anim.y_offset

        for dst in dsts
            y2 = dst * anim.y_scale + anim.y_offset
            lines!(
                anim.scene,
                [x - anim.x_scale, x],
                [y1, y2];
                alpha=anim.line_alpha,
                color=anim.line_color,
                linewidth=anim.line_width,
            )
        end
    end

    return anim
end

end
