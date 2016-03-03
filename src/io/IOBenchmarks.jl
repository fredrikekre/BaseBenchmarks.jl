module IOBenchmarks

using ..BaseBenchmarks: GROUPS
using BenchmarkTools
using Compat

#################
# read (#12364) #
#################

function perf_read!(io)
    seekstart(io)
    x = 0
    while !(eof(io))
        x += read(io, UInt8)
    end
    return x
end

g = addgroup!(GROUPS, "iobuffer read", ["io", "buffer", "stream", "read", "string"])

g["read"] = @benchmarkable perf_read!(IOBuffer(randstring(10^4)))
g["readstring"] = @benchmarkable readstring(IOBuffer(randstring(10^4)))

end # module
