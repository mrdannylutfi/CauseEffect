# Define a custom exception type if it doesn't already exist
struct UnexpectedError <: Exception
    msg::String
end


# 1. Custom writeError function to intercept unexpected exceptions
function writeError(msg::String, e::Exception)
    if e isa UnexpectedError
        println("Unexpected Error Occurred: ", msg)
        @error msg exception=(e, catch_backtrace())
    else
        # Allow other standard system errors to be logged or passed through
        println("A system exception occurred.")
        @error msg exception=(e, catch_backtrace())
    end
end


function docompare!!(idx1, idx2, arr_view)

    """
    Why this is optimized for Julia:
    1. Zero Allocations: The inline assignment syntax arr_view[idx1], arr_view[idx2] = arr_view[idx2], arr_view[idx1] is optimized by the Julia compiler to swap the elements entirely in local CPU registers without allocating temporary heap memory
    2. In-place Mutation: Because arr_view is a view of your global array, modifying arr_view inside this function directly updates the underlying data structures immediately.Integrating with your compareQuartetEnsure you update your compareQuartet calls to point to this new mutating name (docompare!):

    """
    # Check if the value at the first index is greater than the second
    if arr_view[idx1] > arr_view[idx2]
        # In-line swap the contents using Julia's native tuple assignment
        arr_view[idx1], arr_view[idx2] = arr_view[idx2], arr_view[idx1]
        is_swapped = true
    else
        is_swapped = false
    end

    # Return the indices along with the swap flag status
    return idx1, idx2, is_swapped
end

#---
function track_function(global_arr, view_segment )
# Setup data and a zeroed counter tracking object
# global_arr = [10, 3, 8, 6, 12, 1]
# view_segment = @view global_arr[1:4] # handles [10, 3, 8, 6]

# write a pointer (handler) : tracks number of swaps 
total_swaps = Ref(0)

# Run the quartet routine
compareQuartet(1, 2, 3, 4, view_segment, total_swaps)

# Check the accumulated results
println("Algorithm updated array: ", global_arr)
println("Total number of swaps performed: ", total_swaps[])

end

function compareQuartet(a, m1, m2, b, arr; exceptionParameter = UnexpectedError)

  """
   a pattern for sorting 4 elements ([6, 10, 3, 8] -> [3, 6, 8, 10])
    Your steps achieve this well: 
    1. docompare!(a, b) sorts the extremes.
    2. docompare!(m1, m2) sorts the inner elements.
    3. docompare!(a, m1) ensures the absolute lowest value bubbles to a.
    4. docompare!(m2, b) ensures the absolute highest value bubbles to b. 


  """
    try
        # Phase 1: Initialize coordinates relative to the array bounds
        println("phase1 : G1  (10, 3)  at indicies & G2 at indicies ")

        a = firstindex(arr)
        b = lastindex(arr)
        m1 = a + 1
        m2 = b - 1

        # Scan #1
        println("Scan #1")

        println("#1")
        a, b, isSwapped1 = docompare!(a, b, arr)
        println("arr = ", arr)

        println("#2")
        m1, m2, isSwapped2 = docompare!(m1, m2, arr)
        println("arr = ", arr)

        # Scan #2
        println("Scan #2")

        println("#3")
        a, m1, isSwapped3 = docompare!(a, m1, arr)
        println("arr = ", arr)

        println("#4")
        m2, b, isSwapped4 = docompare!(m2, b, arr)
        println("arr = ", arr)

        # Collect group flags
        swapped = [isSwapped1, isSwapped2, isSwapped3, isSwapped4]
        println("swapped = ", swapped)

        # Return updated indices and swap flags as a tuple
        return a, b, m1, m2, swapped

    catch e
        # Correctly forward the exception to your handler
        msg = "Unexpected error in compareQuartet"
        writeError(msg, e)

        # Optionally rethrow if it's not the type you want to silence
        if !(e isa exceptionParameter)
            rethrow(e)
        end
    end
end



function compareQuartet(a, m1, m2, b, _view)
    try
        # 1. Swap and sort internal pairs
        a,  b,  _isSwapped1 = swapContent(a,  b,  view(_view, a:b))
        println("_view = ", _view)
        m1, m2, _isSwapped2 = swapContent(m1, m2, view(_view, m1:m2))
        println("_view = ", _view)
        a,  m1, _isSwapped3 = swapContent(a,  m1, view(_view, a:m1))
        println("_view = ", _view)

        println("#4")
        m2, b, isSwapped4 = swapContent(a,  m1, view( _view, m2 : b))  # docompare!(m2, b, arr)
        println("_view = ", _view)

        #2 Collect group flags
        swapped = [isSwapped1, isSwapped2, isSwapped3, isSwapped4]


        # 3. Return the updated coordinates as a tuple
        return a, b, m1, m2, swapped

    catch e
        # Correctly forward the exception to your handler
        msg = "Unexpected error in compareQuartet"
        writeError(msg, e)

        # Correct Julia syntax for specific exception handling
        if e isa UnexpectedError
            # Correctly forward the exception to your handler
            msg = "Unexpected error in compareQuartet"
            #writeError(msg, e)
            @error "Unexpected error occurred in compareQuartet" exception=(e, catch_backtrace())

        # Optionally rethrow if it's not the type you want to silence
        #if !(e isa exceptionParameter)
        #      rethrow(e) # Pass along other unexpected errors
        #end
        else
            rethrow(e) # Pass along other unexpected errors
        end
    end
end


fucntion call_global_array(global_arr)

  # Declare a global array
  # global_arr = [10, 3, 8, 6, 12, 1, 5, 7]

  # target index range 2 to 5 of the global array as an arbitrary sub-segment
  # this maps index elements: [3, 8, 6, 12]
  segment_view = @view global_arr[2:5]

  # Pass the view slice cleanly into your function
  compareQuartet(2, 3, 4, 5, segment_view)

end

# Declare a global array
global_arr = [10, 3, 8, 6, 12, 1, 5, 7]

# target index range 2 to 5 of the global array as an arbitrary sub-segment
# this maps index elements: [3, 8, 6, 12]
segment_view = @view global_arr[2:5]

# Pass the view slice cleanly into your function
compareQuartet(2, 3, 4, 5, segment_view)
