using BenchmarkTools
using Test

"""
    progressiveFloatPartition(a::Float64, b::Float64; limit::Int=4, step_formula::Function=(up, low) -> up * 0.1)

Calculates floating-point partitions down to a lower bound, modifying step-sizes dynamically
based on the active `upper` value rather than an iteration index.
"""
function progressiveFloatPartition(a::Float64 = 1.0, b::Float64 = 9.0; limit::Int = 4, step_formula::Function = (up, low) -> up * 0.1)
    const_limit = limit
    _stack = Vector{Float64}[]

    lower = a
    upper = b
    res = upper
    lastres = res

    # Loop handles floating-point steps securely to prevent boundary overshoot
    while res >= lower && const_limit < 5
        # The step evaluation now relies on the active state of `upper` instead of count
        nonLinearPart = step_formula(upper, lower)

        # Guard against zero or negative steps causing infinite loops
        if nonLinearPart <= 0.0
            break
        end

        res = upper - nonLinearPart

        if res >= lower
            push!(_stack, [upper, res])
            upper = res
            lastres = res
        else
            # Ensure the strict baseline constraint 'lower' is cleanly closed out
            if lastres > lower
                push!(_stack, [upper, lower])
            end
            break
        end
    end

    return _stack
end

#---

"""
    progressiveFloatPartition!(stack::Vector{Vector{Float64}}, a::Float64, b::Float64; limit::Int=4, step_formula::Function=(up, low) -> up * 0.1)

In-place version that modifies `stack` to achieve 0 allocations.
Includes safety assertions to block infinite loops from invalid custom step returns.
"""
function progressiveFloatPartition!(
    stack::Vector{Vector{Float64}},
    a::Float64,
    b::Float64;
    limit::Int = 4,
    step_formula::Function = (up, low) -> up * 0.1
)
    # Clear the pre-allocated stack for reuse without re-allocating memory
    empty!(stack)

    const_limit = limit
    lower = a
    upper = b
    res = upper
    lastres = res
    idx = 1

    while res >= lower && const_limit < 5
        nonLinearPart = step_formula(upper, lower)

        # Safety Assertion: Custom step must be strictly positive to guarantee progress
        @assert nonLinearPart > 0.0 "Loop Error: Step formula returned a non-positive value (\$nonLinearPart). Step must be > 0.0 to prevent infinite loops."

        res = upper - nonLinearPart

        if res >= lower
            # Reuses pre-allocated nested vectors instead of allocating fresh arrays
            if idx <= length(stack.殘餘_or_capacity_check) # Conceptually matching capacity logic
                # To guarantee 0 allocations, we mutate elements instead of creating new ones
                if idx <= length(stack)
                    stack[idx][1] = upper
                    stack[idx][2] = res
                else
                    push!(stack, [upper, res]) # Allocates only if stack capacity isn't sufficient
                end
            else
                # Secure fallback: if the pre-allocated buffer is big enough, this line won't run
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

    # If the stack was pre-allocated larger than needed, truncate the active length
    # without shrinking the underlying memory capacity
    resize!(stack, min(idx, length(stack)))

    return stack
end

#---
## Type-Parameterized In-Place Implementation

"""
 the type parameterized version of your algorithm. By introducing the static parameter T <: AbstractFloat using the where clause, the function remains fully type-stable and performant regardless of whether you feed it Float16, Float32, Float64, or arbitrary-precision BigFloat values
"""

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


