include("config/settings.jl")
include("src/Simulation.jl")
include("src/Animation.jl")

using .Simulation
using .Animation

n_steps, n_states, collapse_rate = DEFAULT_STEPS, DEFAULT_STATES, DEFAULT_COLLAPSE_RATE
ψ = WaveFunctionWrapper(n_steps, n_states, collapse_rate)
anim = WalkAnimator(
    n_steps,
    n_states,
    SCENE_WIDTH,
    SCENE_HEIGHT,
    SCENE_BGCOLOR,
    MKR_COLORMAP,
    MKR_COLORRANGE,
    MKR_SIZE,
    LINE_ALPHA,
    LINE_COLOR,
    LINE_WIDTH,
)

for _ in 1:n_steps
    step!(ψ)
    data = get_step_data(ψ)
    update_anim!(anim, data.probs, data.paths)
end

display(anim.scene)

using CairoMakie
DEST = replace(PROGRAM_FILE, r".jl$" => ".png")
save(DEST, anim.scene; transparent=true)
