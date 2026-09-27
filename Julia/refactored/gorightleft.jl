function checkRightCondition(arr::Vector{Int64})
    a = firstindex(arr)
    b = lastindex(arr)
    msg = "UnexpectedError"

    try
        a = a + 1

        if a != b
            a, b = remap(a, b)
            # Use a ternary operator or an if-else block cleanly
            if b - a > 1
                goright!(view(arr, a:b)) # Views require a range like a:b
            else
                endAlgorithmSafely(view(arr, a:b))
            end
        elseif a == b
            endAlgorithmSafely()
        else
            error(msg) # Standard way to throw an error message
        end
    catch e
        # Catch the exception object 'e' and log it
        @error "$msg Occured" exception=(e, catch_backtrace())
    end
end

"""
Verification of goleft! & goright! Entry PointsFor completeness, ensure your primary recursive wrappers pass the configuration properties properly without modifying the index tracking variables:
"""
function goleft!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    if b <= a return end

    res = cause(a, b, _view, stop_func, currentValue, mid_func)
    res === nothing && return # Stop evaluation loop instantly

    next_b = b - 1
    if next_b >= a
        goleft!(a, next_b, view(_view, a:next_b), stop_func, currentValue, mid_func)
    end
end

function goright!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    if a >= b return end

    res = cause(a, b, _view, stop_func, currentValue, mid_func)
    res === nothing && return

    next_a = a + 1
    if next_a <= b
        goright!(next_a, b, view(_view, next_a:b), stop_func, currentValue, mid_func)
    end
end

"""

 # Continuous Directional Drivers (goleft! and goright!)
 These functions serve as the continuous wrappers.
 Every time they step left or right, they invoke cause, which computes the new midpoints and re-subdivides the problem via `checkCond2`.

 """

 # --- CONTINUOUS LEFT STEPPING ---
function goleft!(_view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    goleft!(firstindex(_view), lastindex(_view), _view, stop_func, currentValue, mid_func)
end

function goleft!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    if b <= a return end

    # cause() evaluates stop_func, then automatically runs middle() and checkCond2()
    res = cause(a, b, _view, stop_func, currentValue, mid_func)
    res === nothing && return # Stop instantly if stop_func is true

    # Step down left-ward linearly while checkCond2 handles structural subdivision
    next_b = b - 1
    if next_b >= a
        goleft!(a, next_b, view(_view, a:next_b), stop_func, currentValue, mid_func)
    end
end

# --- CONTINUOUS RIGHT STEPPING ---
function goright!(_view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    goright!(firstindex(_view), lastindex(_view), _view, stop_func, currentValue, mid_func)
end

function goright!(a::Int64, b::Int64, _view::AbstractVector{Int64}, stop_func, currentValue, mid_func=middle)
    if a >= b return end

    res = cause(a, b, _view, stop_func, currentValue, mid_func)
    res === nothing && return

    # Step down right-ward linearly while checkCond2 handles structural subdivision
    next_a = a + 1
    if next_a <= b
        goright!(next_a, b, view(_view, next_a:b), stop_func, currentValue, mid_func)
    end
end
