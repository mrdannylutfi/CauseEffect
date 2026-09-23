
"""

trivialPartitionFunction with cleaned-up syntax, fixed loop logic,
and proper interval stacking

"""
function trivialPartitionFunction(a::Int64 = 1, b::Int64 = 9; limit::Int = 4)
    # Ensure limit is treated as a fixed constraint
    const_limit = limit
    _stack = Tuple{Int64, Int64}[]

    lower = copy(a)
    upper = copy(b)
    res = upper
    count = 1
    lastres = res

    # Main progressive reduction loop
    while res >= lower && const_limit < 5
        nonLinearPart = count * lower
        res = upper - nonLinearPart

        if res >= lower
            push!(_stack, (count, res))
            upper = res
            lastres = res
            count += 1
        else
            if lastres != lower
                push!(_stack, (count, lower))
            end
            break
        end
    end

    println("congratz you're done!")
    return _stack
end

function trivialPartitionFunction(a::Int64 = 1, b::Int64 = 9; limit::Int = 4)
    # Ensure limit is treated as a fixed constraint
    const_limit = limit 
    _stack = Tuple{Int64, Int64}[]
    
    lower = copy(a)
    upper = copy(b)
    res = upper
    count = 1
    lastres = res

    # Main progressive reduction loop
    while res >= lower && const_limit < 5
        nonLinearPart = count * lower
        res = upper - nonLinearPart

        if res >= lower
            push!(_stack, (count, res))
            upper = res
            lastres = res
            count += 1
        else
            if lastres != lower
                push!(_stack, (count, lower))
            end
            break
        end
    end

    println("congratz you're done!")
    return _stack
end



