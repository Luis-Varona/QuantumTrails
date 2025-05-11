using CairoMakie

include("config/settings.jl")
include("src/Animation.jl")

using .Animation

anim = WalkAnimator(
    10,
    5,
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

for t in 1:10
    positions = rand(-2:2, 5)
    values = abs.(randn(5))
    values ./= sum(values)
    pdict = Dict(positions .=> values)

    pathdict = Dict{Int,Vector{Int}}()

    for pos in keys(pdict)
        pathdict[pos] = [pos - 1, pos + 1]
    end

    update_anim!(anim, pdict, pathdict)
end

display(anim.scene)
