module nvrtc

const libnvrtc = Libdl.find_library(["libnvrtc"], ["/opt/cuda/lib64"])
@assert libnvrtc != ""

@enum(Result,
      SUCCESS = 0,
      ERROR_OUT_OF_MEMORY = 1,
      ERROR_PROGRAM_CREATION_FAILURE = 2,
      ERROR_INVALID_INPUT = 3,
      ERROR_INVALID_PROGRAM = 4,
      ERROR_INVALID_OPTION = 5,
      ERROR_COMPILATION = 6,
      ERROR_BUILTIN_OPERATION_FAILURE = 7)

function GetErrorString(result :: Result)
  err = ccall((:nvrtcGetErrorString, libnvrtc), Ptr{Cchar}, (Result, ), result)
  unsafe_wrap(String, convert(Ptr{UInt8}, err))
end

function Version()
  r_major = Ref{Cint}()
  r_minor = Ref{Cint}()
  err = ccall((:nvrtcVersion, libnvrtc), Result, (Ref{Cint}, Ref{Cint}), r_major, r_minor)
  err != SUCCESS && error(GetErrorString(err))
  return (r_major[], r_minor[])
end

# opaque program handle
typealias Program Ptr{Void}

function CompileProgram(prog :: Program, options :: Vector{String})
  err = ccall((:nvrtcCompileProgram, libnvrtc), Result, (Program, Cint, Ptr{Ptr{Cchar}}), prog, length(options), options)
  if err != SUCCESS
    print(GetProgramLog(prog))
    error(GetErrorString(err))
  end
end

function CreateProgram(src :: String, name :: String, headers :: Vector{String}, includeNames :: Vector{String})
  @assert length(headers) == length(includeNames)
  prog = Ref{Program}()
  err = ccall((:nvrtcCreateProgram, libnvrtc),
              Result, (Ref{Program}, Cstring, Cstring, Cint, Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}),
              prog, src, name, length(headers), headers, includeNames)
  if err != SUCCESS
    print(GetProgramLog(prog[]))
    error(GetErrorString(err))
  end
  prog[]
end

function DestroyProgram(prog :: Program)
  r_prog = Ref{Program}(prog)
  err = ccall((:nvrtcDestroyProgram, libnvrtc), Result, (Ref{Program},), r_prog)
  err != SUCCESS && error(GetErrorString(err))
end

function GetPTX(prog :: Program)
  size = Ref{Csize_t}()
  err = ccall((:nvrtcGetPTXSize, libnvrtc), Result, (Program, Ref{Csize_t}), prog, size)
  err != SUCCESS && error(GetErrorString(err))

  ptx = Vector{Cchar}(size[])
  err = ccall((:nvrtcGetPTX, libnvrtc), Result, (Program, Ref{Cchar}), prog, ptx)
  err != SUCCESS && error(GetErrorString(err))

  String(reinterpret(UInt8, ptx))
end
  
function GetProgramLog(prog :: Program)
  size = Ref{Csize_t}()
  err = ccall((:nvrtcGetProgramLogSize, libnvrtc), Result, (Program, Ref{Csize_t}), prog, size)
  err != SUCCESS && error(GetErrorString(err))

  log = Vector{Cchar}(size[])
  err = ccall((:nvrtcGetProgramLog, libnvrtc), Result, (Program, Ref{Cchar}), prog, log)
  err != SUCCESS && error(GetErrorString(err))

  String(reinterpret(UInt8, log))
end
end # module
