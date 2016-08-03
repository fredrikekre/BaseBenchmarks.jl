module ScalarBenchmarks

include(joinpath(Pkg.dir("BaseBenchmarks"), "src", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

import Compat: UTF8String, view

const SUITE = BenchmarkGroup()

const INTS = (UInt, Int, BigInt)
const FLOATS = (Float32, Float64, BigFloat)
const REALS = (INTS..., FLOATS...)
const COMPS = map(R -> Complex{R}, REALS)
const NUMS = (REALS..., COMPS...)
const BIGNUMS = (BigInt, BigFloat, Complex{BigInt}, Complex{BigFloat})

##############
# predicates #
##############

g = addgroup!(SUITE, "predicate", ["isinteger", "isinf", "isnan", "iseven", "isodd"])

for T in NUMS
    x = one(T)
    tstr = string(T)
    g["isequal", tstr]   = @benchmarkable isequal($x, $x)
    g["isinteger", tstr] = @benchmarkable isinteger($x)
    g["isinf", tstr]     = @benchmarkable isinf($x)
    g["isfinite", tstr]  = @benchmarkable isfinite($x)
    g["isnan", tstr]     = @benchmarkable isnan($x)
end

for T in REALS
    x = one(T)
    tstr = string(T)
    g["isless", tstr] = @benchmarkable isless($x, $x)
end

for T in INTS
    x = one(T)
    tstr = string(T)
    g["iseven", tstr] = @benchmarkable iseven($x)
    g["isodd", tstr]  = @benchmarkable isodd($x)
end

for b in values(g)
    b.params.time_tolerance = 0.25
end

##############
# arithmetic #
##############

arith = addgroup!(SUITE, "arithmetic")
fstmth = addgroup!(SUITE, "fastmath", ["arithmetic"])

for X in NUMS
    x = one(X)
    xstr = string(X)
    isbignum = in(X, BIGNUMS)
    fstmth["add", xstr] = @benchmarkable @fastmath($x * $(copy(x))) time_tolerance=0.40
    fstmth["sub", xstr] = @benchmarkable @fastmath($x - $(copy(x))) time_tolerance=0.40
    fstmth["mul", xstr] = @benchmarkable @fastmath($x + $(copy(x))) time_tolerance=0.40
    fstmth["div", xstr] = @benchmarkable @fastmath($x / $(copy(x))) time_tolerance=0.40
    for Y in NUMS
        y = one(Y)
        ystr = string(Y)
        tol = (X != Y || isbignum) ? 0.50 : 0.25
        arith["add", xstr, ystr] = @benchmarkable +($x, $y) time_tolerance=tol
        arith["sub", xstr, ystr] = @benchmarkable -($x, $y) time_tolerance=tol
        arith["mul", xstr, ystr] = @benchmarkable *($x, $y) time_tolerance=tol
        arith["div", xstr, ystr] = @benchmarkable /($x, $y) time_tolerance=tol
    end
end

#############
# iteration #
#############

function perf_iterate_indexed(n, v)
    s = 0
    for i = 1:n
        for j = 1:1
            @inbounds k = v[j]
            s += k
        end
    end
    s
end

function perf_iterate_in(n, v)
    s = 0
    for i = 1:n
        for k in v
            s += k
        end
    end
    s
end

g = addgroup!(SUITE, "iteration", ["indexed", "in"])

g["indexed"]   = @benchmarkable perf_iterate_indexed(10^5, 3)
g["in"]   = @benchmarkable perf_iterate_in(10^5, 3)


end # module
