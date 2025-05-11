# Copyright 2025 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

include("../config/settings.jl")
include("Simulation.jl")
include("Animation.jl")
include("Routes.jl")

using .Simulation
using .Animation
using .Routes

# TODO: Write the "glue" code to run everything
