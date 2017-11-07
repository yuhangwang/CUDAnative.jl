using CUDAdrv, CUDAnative
VERSION >= v"0.7.0-DEV.1995" ? using Test : using Base.Test

"Dummy kernel doing 100 FMAs."
function kernel_100fma(a, b, c, out)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    @inbounds a_val = a[i]
    @inbounds b_val = b[i]
    @inbounds c_val = c[i]

    for j in 1:33
        a_val = CUDAnative.fma(a_val, b_val, c_val)
        b_val = CUDAnative.fma(a_val, b_val, c_val)
        c_val = CUDAnative.fma(a_val, b_val, c_val)
    end

    @inbounds out[i] = CUDAnative.fma(a_val, b_val, c_val)

    return nothing
end

function peakflops(n::Integer=5000, dev::CuDevice=CuDevice(0))
    ctx = CuContext(dev)

    dims = (n, n)
    a = round.(rand(Float32, dims) * 100)
    b = round.(rand(Float32, dims) * 100)
    c = round.(rand(Float32, dims) * 100)

    d_a = CuArray(a)
    d_b = CuArray(b)
    d_c = CuArray(c)
    d_out = similar(d_a)

    len = prod(dims)
    threads = min(len, 1024)
    blocks = len ÷ threads

    # warm-up
    @cuda (1, 1) kernel_100fma(d_a, d_b, d_c, d_out)
    synchronize(ctx)

    secs = CUDAdrv.@elapsed begin
        @cuda (blocks, threads) kernel_100fma(d_a, d_b, d_c, d_out)
    end
    flopcount = 200*len
    flops = flopcount / secs

    destroy!(ctx)
    return flops
end

println(peakflops())
