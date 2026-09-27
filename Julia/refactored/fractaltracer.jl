#fractaltracer.jl
"""
We use a clean, modular struct to safely pass depth counters down the call stack without relying on slow global variables.
"""
# A lightweight structural configuration context for safely debugging recursive layers
mutable struct FractalTracer
    max_depth::Int
    current_highest_depth::Int
end

# Concrete implementation of your stopping condition parameter
function safe_stop_condition(arr::AbstractVector{Int64}, currentValue::Int64)::Bool
    # --- SAFETY TRIGGER 1: Window Size Exhausted ---
    # Stop if the view window spans less than 2 distinct elements
    if length(arr) <= 1
        return true
    end

    # --- SAFETY TRIGGER 2: Content Threshold Reached ---
    # Stop if the total sum of elements inside this subview passes your currentValue limit
    if sum(arr) > currentValue
        return true
    end

    return false
end

"""
Instrumented Recursive ArchitectureWe inject the FractalTracer context and track the layout nesting levels. Every depth increment corresponds to an internal stack branch split.

"""
function cause(a::Int64, b::Int64, arr::AbstractVector{Int64}, stop_func, currentValue, mid_func, tracer::FractalTracer, depth::Int)
    # Check if we hit an artificial maximum structural limit to protect memory
    if depth > tracer.max_depth
        return nothing
    end

    # Update max metrics tracker
    if depth > tracer.current_highest_depth
        tracer.current_highest_depth = depth
    end

    # Evaluate dynamic stopping callback function
    if stop_func(arr, currentValue)
        return nothing
    end

    m1, m2, isWhole = mid_func(a, b)

    # Forward depth metadata deeper down the tree frame
    checkCond2(a, m1, m2, b, isWhole, arr, stop_func, currentValue, mid_func, tracer, depth)

    return m1, m2, isWhole
end

function checkCond2(a::Int64, m1::Int64, m2::Int64, b::Int64, isWhole::Bool, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func, tracer::FractalTracer, depth::Int)
    v_first = firstindex(_view)
    v_last  = lastindex(_view)
    indent  = "  "^depth # Formats indentation strings based on current depth

    if isWhole
        println("$(indent)▶ [Depth $depth] 3-Fractal Processing | Indices: $a:$b")
        compareTriad(a, m1, b, _view)

        # 1. Left Sub-Branch
        left_end = min(m1, v_last)
        if v_first < left_end
            new_left_view = view(_view, v_first:left_end)
            goleft!(v_first, left_end, new_left_view, stop_func, currentValue, mid_func, tracer, depth + 1)
        end

        # 2. Right Sub-Branch
        right_start = max(v_first, m1)
        if right_start < v_last
            new_right_view = view(_view, right_start:v_last)
            goright!(right_start, v_last, new_right_view, stop_func, currentValue, mid_func, tracer, depth + 1)
        end
    else
        println("$(indent)▶ [Depth $depth] 4-Fractal Processing | TwinMiddles: ($m1, $m2) | Indices: $a:$b")
        compareQuartet(a, m1, m2, b, _view)

        # 1. Left Sub-Branch
        left_end = min(m1, v_last)
        if v_first < left_end
            new_left_view = view(_view, v_first:left_end)
            goleft!(v_first, left_end, new_left_view, stop_func, currentValue, mid_func, tracer, depth + 1)
        end

        # 2. Right Sub-Branch
        right_start = max(v_first, m2)
        if right_start < v_last
            new_right_view = view(_view, right_start:v_last)
            goright!(right_start, v_last, new_right_view, stop_func, currentValue, mid_func, tracer, depth + 1)
        end
    end
end

# --- RECURSIVE LINEAR DIRECTIONAL WRAPPERS ---
function goleft!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func, tracer::FractalTracer, depth::Int)
    if b <= a return end

    res = cause(a, b, _view, stop_func, currentValue, mid_func, tracer, depth)
    res === nothing && return

    next_b = b - 1
    if next_b >= a
        goleft!(a, next_b, view(_view, a:next_b), stop_func, currentValue, mid_func, tracer, depth)
    end
end

function goright!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func, tracer::FractalTracer, depth::Int)
    if a >= b return end

    res = cause(a, b, _view, stop_func, currentValue, mid_func, tracer, depth)
    res === nothing && return

    next_a = a + 1
    if next_a <= b
        goright!(next_a, b, view(_view, next_a:b), stop_func, currentValue, mid_func, tracer, depth)
    end
end
"""

3. Execution Verification SuiteWe can configure a mock entry runner function that seeds an initial configuration environment to profile loop safety:

"""

global const Middles = Vector{Any}()

function execute_monitored_fractal()
    test_arr = [9, 2, 7, 4, 5, 1, 8]
    val_threshold = 100 # Change this lower (e.g., 15) to see the content trigger halt earlier

    # Initialize safety context parameters (cap execution at an absolute max tree depth of 10)
    tracer = FractalTracer(10, 0)

    println("==================================================")
    println("LAUNCHING TRACE PIPELINE")
    println("Original Target Frame Setup: ", test_arr)
    println("==================================================")

    # Initiate the processing chain from core ground floor (Depth 0)
    goleft!(1, length(test_arr), view(test_arr, 1:length(test_arr)), safe_stop_condition, val_threshold, middle, tracer, 0)

    println("==================================================")
    println("EXECUTION SUCCEEDED WITHOUT ERRORS")
    println("Deepest Matrix Level Explored: Depth ", tracer.current_highest_depth)
    println("Final Array State: ", test_arr)
    println("==================================================")
end

execute_monitored_fractal()

"""
Now that the continuous traversal tree tracks execution depths perfectly

"""
