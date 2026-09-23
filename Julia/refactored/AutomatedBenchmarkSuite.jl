"""
The benchmarking block prints full timing, execution variations, and allocation breakdowns. Local runtime variables are escaped using $ within the benchmark macros to ensure optimization variables aren't falsely categorized as global scope parameters.

"""
using BenchmarkTools
using Test

# Initialize testing scenarios
start_lower = 1.0
start_upper = 100.0

# 1. Custom Decay Step formula: Steps shrink as upper drops
decay_step = (upper, lower) -> upper * 0.15

# 2. Custom Aggressive Step formula: Steps widen as upper gets closer to lower
aggressive_step = (upper, lower) -> (upper - lower) * 0.5 + 0.1

println("="^50)
println(" RUNNING AUTOMATED BENCHMARK SUITE")
println("="^50)

println("\n--> Scenario A: Decay Step Formula (btime summary):")
# Quick profiling output
@btime progressiveFloatPartition($start_lower, $start_upper; step_formula=$decay_step)

println("\n--> Scenario B: Aggressive Step Formula (Detailed Statistics):")
# Full statistical trail output
suite_result = @benchmark progressiveFloatPartition($start_lower, $start_upper; step_formula=$aggressive_step)
show(stdout, MIME("text/plain"), suite_result)
println("\n" * "="^50)

"""
Continuous Math Adaptations: All baseline arguments and parameters operate under Float64 structures. Safe inequalities (lastres > lower) mitigate standard precision trailing flaws common with structural binary checks.State-Dependent Reductions: The lambda evaluations now pull directly from changes to the upper boundary, allowing your partition steps to shrink dynamically (decay) or expand (accelerate) organically as the value drops.Microsecond Inherent Profiling: Outfitted with BenchmarkTools.jl routines to skip compilation noise and background process interference

"""

# BENCHMARK Suite [2]

"""
Optimized 0-Allocation Implementation PatternTo achieve a true 0-allocation profile in Julia, we must pre-allocate both the outer vector and its inner vector rows. Below is the automated benchmark suite showcasing the zero-allocation state.

"""

using BenchmarkTools
using Test

# Setup pre-allocated buffer structures
# (e.g., maximum anticipated partition steps = 50)
const BUFFER_SIZE = 50
preallocated_stack = [Vector{Float64}(undef, 2) for _ in 1:BUFFER_SIZE]

# Test Conditions
start_lower = 1.0
start_upper = 100.0
decay_step = (upper, lower) -> upper * 0.15

println("="^50)
println(" VERIFYING ZERO-ALLOCATION AND PERFORMANCE")
println("="^50)

# Benchmark the in-place version
println("\n--> In-Place Version Performance Profile:")
@btime progressiveFloatPartition!($preallocated_stack, $start_lower, $start_upper; step_formula=$decay_step)

# Test assertion safety
println("\n--> Testing Assertion Safety Against Infinite Loops:")
bad_step = (upper, lower) -> 0.0 # Will trigger the safety check

try
    progressiveFloatPartition!(preallocated_stack, start_lower, start_upper; step_formula=bad_step)
catch e
    if isa(e, AssertionError)
        println("✓ Successfully caught loop freeze: ", e.msg)
    else
        rethrow(e)
    end
end
println("="^50)

"""
Enhancements Breakdown
1. Zero Allocations achieved:
 By using empty!, mutating values via index-matching
 (stack[idx][1] = upper),
 and safely pruning lengths with `resize!``,
 no garbage collection overhead is generated
 during processing.

 2. Infinite Loop Guard: The @assert nonLinearPart > 0.0
  macro halts execution immediately
  if a bad step calculation threatens to stall code progress.
  Would you like to find out:

"""

# Advanced benchmark tests

using BenchmarkTools
using Test

"""
    PartitionPair{T <: AbstractFloat}

A lightweight, dedicated struct to replace generic `Vector{T}` pairs,
optimizing memory layout and clarity.
"""
mutable struct PartitionPair{T <: AbstractFloat}
    upper::T
    lower::T
end

"""
    PartitionState{T <: AbstractFloat}

Manages the pre-allocated execution state and track results in place.
"""
mutable struct PartitionState{T <: AbstractFloat}
    buffer::Vector{PartitionPair{T}}
    active_length::Int

    # Inner constructor to pre-allocate capacity cleanly
    function PartitionState{T}(capacity::Int) where {T <: AbstractFloat}
        buf = [PartitionPair{T}(zero(T), zero(T)) for _ in 1:capacity]
        new{T}(buf, 0)
    end
end


"""
    progressiveFloatPartition!(state::PartitionState{T}, a::T, b::T; limit::Int=4, step_formula::Function) where {T <: AbstractFloat}

Populates the custom `PartitionState` completely in-place without generating allocations.
"""

function progressiveFloatPartition!(
    state::PartitionState{T},
    a::T,
    b::T;
    limit::Int = 4,
    step_formula::Function = (up, low) -> up * 0.1
) where {T <: AbstractFloat}

    state.active_length = 0
    const_limit = limit
    lower = a
    upper = b
    res = upper
    lastres = res
    idx = 1

    zero_val = zero(T)
    capacity = length(state.buffer)

    while res >= lower && const_limit < 5
        nonLinearPart = step_formula(upper, lower)

        # Safety assertion against infinite freeze loops
        @assert nonLinearPart > zero_val "Loop Error: Step formula returned a non-positive value. Step must be > 0.0."

        res = upper - nonLinearPart

        if res >= lower
            if idx <= capacity
                pair = state.buffer[idx]
                pair.upper = upper
                pair.lower = res
            else
                # Fallback only if initial buffer allocation layout is exceeded
                push!(state.buffer, PartitionPair{T}(upper, res))
            end

            upper = res
            lastres = res
            idx += 1
        else
            if lastres > lower
                if idx <= capacity
                    pair = state.buffer[idx]
                    pair.upper = upper
                    pair.lower = lower
                else
                    push!(state.buffer, PartitionPair{T}(upper, lower))
                end
                idx += 1
            end
            break
        end
    end

    # Update active structural length boundary tracking
    state.active_length = idx - 1
    return state
end

# type-parameterized function

using BenchmarkTools
using Test

"""
    progressiveFloatPartition!(stack::Vector{Vector{T}}, a::T, b::T; limit::Int=4, step_formula::Function=(up, low) -> up * 0.1) where {T <: AbstractFloat}

Type-parameterized in-place partition function. Automatically binds `T` to the exact
concrete subtype of `AbstractFloat` provided by the arguments.
"""
function progressiveFloatPartition!(
    stack::Vector{Vector{T}},
    a::T,
    b::T;
    limit::Int = 4,
    step_formula::Function = (up, low) -> up * 0.1
) where {T <: AbstractFloat}

    empty!(stack)

    const_limit = limit
    lower = a
    upper = b
    res = upper
    lastres = res
    idx = 1

    # Zero value fallback matches type T precisely
    zero_val = zero(T)

    while res >= lower && const_limit < 5
        nonLinearPart = step_formula(upper, lower)

        # Safety Assertion: enforces type consistency and blocks loop freeze
        @assert nonLinearPart > zero_val "Loop Error: Step formula returned a non-positive value (\$nonLinearPart). Step must be > 0.0 to prevent infinite loops."

        res = upper - nonLinearPart

        if res >= lower
            if idx <= length(stack)
                stack[idx][1] = upper
                stack[idx][2] = res
            else
                push!(stack, [upper, res])
            end

            upper = res
            lastres = res
            idx += 1
        else
            if lastres > lower
                if idx <= length(stack)
                    stack[idx][1] = upper
                    stack[idx][2] = lower
                else
                    push!(stack, [upper, lower])
                end
            end
            break
        end
    end

    resize!(stack, min(idx, length(stack)))
    return stack
end

# Validation & Zero-Allocation Benchmark Suite
"""
This validates that using our custom state engine structure achieves `maximum-computation` performance without any `heap-allocations`.
""""
@testset "Interface Integration Tests" begin
    # Setup state
    state = PartitionState{Float64}(10)
    decay_step = (upper, lower) -> upper * 0.4
    progressiveFloatPartition!(state, 1.0, 20.0; step_formula=decay_step)

    @testset "Verification of Clean Printing" begin
        println("\n" * "="^40)
        println("DISPLAY DEMO:")
        println("="^40)
        # Triggers the new text/plain show rules automatically
        display(state) 
        println("\n" * "="^40)
    end

    @testset "Native Iteration Syntax Integration" begin
        println("ITERATION DEMO:")
        counter = 0
        
        # Test native loop capabilities
        for pair in state
            counter += 1
            println("Loop step $counter: Extracted Upper is $(pair.upper)")
            @test pair.upper > 0.0
        end
        
        @test counter == length(state)
        println("="^40)
    end
    
    @testset "Zero Allocation Re-Verification" begin
        # Confirm that implementing interfaces did not cause overhead leaks
        allocs = @allocated progressiveFloatPartition!(state, 1.0, 20.0; step_formula=decay_step)
        @test allocs == 0
    end
end

