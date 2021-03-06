module ScalarBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

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
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["isequal", tstr]   = @benchmarkable isequal($x, $x) time_tolerance=tol
    g["isinteger", tstr] = @benchmarkable isinteger($x) time_tolerance=tol
    g["isinf", tstr]     = @benchmarkable isinf($x) time_tolerance=tol
    g["isfinite", tstr]  = @benchmarkable isfinite($x) time_tolerance=tol
    g["isnan", tstr]     = @benchmarkable isnan($x) time_tolerance=tol
end

for T in REALS
    x = one(T)
    tstr = string(T)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["isless", tstr] = @benchmarkable isless($x, $x) time_tolerance=tol
end

for T in INTS
    x = one(T)
    tstr = string(T)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    g["iseven", tstr] = @benchmarkable iseven($x) time_tolerance=tol
    g["isodd", tstr]  = @benchmarkable isodd($x) time_tolerance=tol
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
    fstmth["add", xstr] = @benchmarkable @fastmath($x + $(copy(x))) time_tolerance=0.40
    fstmth["sub", xstr] = @benchmarkable @fastmath($x - $(copy(x))) time_tolerance=0.40
    fstmth["mul", xstr] = @benchmarkable @fastmath($x * $(copy(x))) time_tolerance=0.40
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

for X in (INTS..., Char, Bool)
    x = X(1) # one(X) is not valid for X==Char
    xstr = string(X)
    for Y in (INTS..., Bool)
        VERSION < v"0.6" && Y == BigInt && continue
        tol = (X != Y || X == BigInt || Y == BigInt) ? 0.40 : 0.25
        arith["rem type", xstr, string(Y)] = @benchmarkable %($x, $Y) time_tolerance=tol
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

g["indexed"] = @benchmarkable perf_iterate_indexed(10^5, 3) time_tolerance=0.25
g["in"]      = @benchmarkable perf_iterate_in(10^5, 3) time_tolerance=0.25

#######
# exp #
#######

g = addgroup!(SUITE, "floatexp")

g["ldexp", "norm -> norm",       "Float64"] = @benchmarkable ldexp($(1.7), $(10))
g["ldexp", "norm -> norm",       "Float32"] = @benchmarkable ldexp($(1.7f0), $(10))
g["ldexp", "norm -> subnorm",    "Float64"] = @benchmarkable ldexp($(1.7), $(-1028))
g["ldexp", "norm -> subnorm",    "Float32"] = @benchmarkable ldexp($(1.7f0), $(-128))
g["ldexp", "norm -> inf",        "Float64"] = @benchmarkable ldexp($(1.7), $(1028))
g["ldexp", "norm -> inf",        "Float32"] = @benchmarkable ldexp($(1.7f0), $(128))
g["ldexp", "subnorm -> norm",    "Float64"] = @benchmarkable ldexp($(1.7e-310), $(100))
g["ldexp", "subnorm -> norm",    "Float32"] = @benchmarkable ldexp($(1.7f-40), $(100))
g["ldexp", "subnorm -> subnorm", "Float64"] = @benchmarkable ldexp($(1.7e-310), $(-3))
g["ldexp", "subnorm -> subnorm", "Float32"] = @benchmarkable ldexp($(1.7f-40), $(-3))
g["ldexp", "inf -> inf",         "Float64"] = @benchmarkable ldexp($(Inf), $(10))
g["ldexp", "inf -> inf",         "Float32"] = @benchmarkable ldexp($(Inf32), $(10))

g["frexp", "norm",    "Float64"] = @benchmarkable frexp($(1.7))
g["frexp", "norm",    "Float32"] = @benchmarkable frexp($(1.7f0))
g["frexp", "subnorm", "Float64"] = @benchmarkable frexp($(1.7e-310))
g["frexp", "subnorm", "Float32"] = @benchmarkable frexp($(1.7f-40))
g["frexp", "inf",     "Float64"] = @benchmarkable frexp($(Inf))
g["frexp", "inf",     "Float32"] = @benchmarkable frexp($(Inf32))

g["exponent", "norm",    "Float64"] = @benchmarkable exponent($(1.7))
g["exponent", "norm",    "Float32"] = @benchmarkable exponent($(1.7f0))
g["exponent", "subnorm", "Float64"] = @benchmarkable exponent($(1.7e-310))
g["exponent", "subnorm", "Float32"] = @benchmarkable exponent($(1.7f-40))

g["significand", "norm",    "Float64"] = @benchmarkable significand($(1.7))
g["significand", "norm",    "Float32"] = @benchmarkable significand($(1.7f0))
g["significand", "subnorm", "Float64"] = @benchmarkable significand($(1.7e-310))
g["significand", "subnorm", "Float32"] = @benchmarkable significand($(1.7f-40))

g["exp", "normal path, k = 2",              "Float64"] = @benchmarkable exp($(1.5))
g["exp", "fast path, k = 1",                "Float64"] = @benchmarkable exp($(0.5))
g["exp", "no agument reduction, k = 9",     "Float64"] = @benchmarkable exp($(0.1))
g["exp", "small argument path",             "Float64"] = @benchmarkable exp($(2.0^-30))
g["exp", "normal path -> small, k = -1045", "Float64"] = @benchmarkable exp($(-724.0))
g["exp", "overflow",                        "Float64"] = @benchmarkable exp($(900.0))
g["exp", "underflow",                       "Float64"] = @benchmarkable exp($(-900.0))

g["exp", "normal path, k = 2",              "Float32"] = @benchmarkable exp($(1f5))
g["exp", "fast path, k = 1",                "Float32"] = @benchmarkable exp($(0f5))
g["exp", "no agument reduction, k = 9",     "Float32"] = @benchmarkable exp($(0f1))
g["exp", "small argument path",             "Float32"] = @benchmarkable exp($(2f0^-15))
g["exp", "normal path -> small, k = -1045", "Float32"] = @benchmarkable exp($(-724f0))
g["exp", "overflow",                        "Float32"] = @benchmarkable exp($(150f0))
g["exp", "underflow",                       "Float32"] = @benchmarkable exp($(-150f0))

g["exp10", "no agument reduction, k = 1",     "Float64"] = @benchmarkable exp10($(0.25))
g["exp10", "direct approx, k = 0",            "Float64"] = @benchmarkable exp10($(0.01))
g["exp10", "taylor expansion",                "Float32"] = @benchmarkable exp10($(2f0^-35))
g["exp10", "agument reduction, k = 2",        "Float64"] = @benchmarkable exp10($(0.5))
g["exp10", "agument reduction, k = 83",       "Float64"] = @benchmarkable exp10($(25.0))
g["exp10", "normal path -> small, k = -1075", "Float64"] = @benchmarkable exp10($(-323.6))
g["exp10", "overflow",                        "Float64"] = @benchmarkable exp10($(400.0))
g["exp10", "underflow",                       "Float64"] = @benchmarkable exp10($(-400.0))

g["exp10", "no agument reduction, k = 1",    "Float32"] = @benchmarkable exp10($(0.25f0))
g["exp10", "direct approx, k = 0",           "Float32"] = @benchmarkable exp10($(0.01f0))
g["exp10", "taylor expansion",               "Float32"] = @benchmarkable exp10($(2f0^-25))
g["exp10", "agument reduction, k = 2",       "Float32"] = @benchmarkable exp10($(0.5f0))
g["exp10", "agument reduction, k = 83",      "Float32"] = @benchmarkable exp10($(25.0f0))
g["exp10", "normal path -> small, k = -150", "Float32"] = @benchmarkable exp10($(-45.5f0))
g["exp10", "overflow",                       "Float32"] = @benchmarkable exp10($(100f0))
g["exp10", "underflow",                      "Float32"] = @benchmarkable exp10($(-100f0))

for b in values(g)
    b.params.time_tolerance = 0.40
end

##############
# intfuncs   #
##############

g = addgroup!(SUITE, "intfuncs", ["prevpow2", "nextpow2"])

for T in INTS
    x = T[0, 1, 2, 3, 4, 10, 100, 1024, 10000, 2^30, 2^30-1]
    if T == BigInt
        push!(x, big(2)^3000, big(2)^3000-1)
    end
    y = similar(x)
    tol = in(T, BIGNUMS) ? 0.40 : 0.25
    tstr = string(T)
    for funpow2 = (prevpow2, nextpow2), sgn = (+, -)
        g[string(funpow2), tstr, string(sgn)] = @benchmarkable map!($funpow2, $y, $(sgn(x))) time_tolerance=tol
    end
end

end # module
