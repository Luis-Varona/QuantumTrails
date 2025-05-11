using Test

include("../src/Simulation.jl")
# There are bugs precompiling `CairoMakie.jl` on x86 architecture in CI testing
haskey(ENV, "CI") || include("../src/Animation.jl")
include("../src/Routes.jl")

@info "Testing `Simulation` module"
include("test_simulation.jl")

# There are bugs precompiling `CairoMakie.jl` on x86 architecture in CI testing
if !haskey(ENV, "CI")
    @info "Testing `Animation` module"
    include("test_animation.jl")
end

@info "Testing `Routes` module"
include("test_routes.jl")
