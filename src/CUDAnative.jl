isdefined(Base, :__precompile__) && __precompile__()

module CUDAnative

using CUDAdrv

# non-exported utility functions
import CUDAdrv: debug, DEBUG, trace, TRACE
export nvrtc


include("util.jl")

include("compilation.jl")
include("nvrtc.jl")

include("execution.jl")
include("intrinsics.jl")
include("arrays.jl")


function __init__()
    __init_util__()
end

end
