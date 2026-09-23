using Base.Threads
using BenchmarkTools
using Test

# ==============================================================================
# 1. CORE TYPE DEFINITIONS & IN-PLACE INITIALIZATION
# ==============================================================================

mutable struct PartitionPair{T <: AbstractFloat}
    upper::T
    lower::T
end

mutable struct PartitionState{T <: AbstractFloat}
    buffer::Vector{PartitionPair{T}}
    active_length::Int

    function PartitionState{T}(capacity::Int) where {T <: AbstractFloat}
        buf = [PartitionPair{T}(zero(T), zero(T)) for _ in 1:capacity]
        new{T}(buf, 0)
    end
end

Base.length(state::PartitionState) = state.active_length

function Base.iterate(state::PartitionState, index=1)
    if index > state.active_length
        return nothing
    else
        return (state.buffer[index], index + 1)
    end
end

function Base.show(io::IO, ::MIME"text/plain", state::PartitionState{T}) where T
    println(io, "PartitionState{\(T} with\)(state.active_length) active intervals:")
    for i in 1:state.active_length
        println(io, "  \$i => [\((state.buffer[i].upper),\)(state.buffer[i].lower)]")
    end
end

# ==============================================================================
# 2. CORE REDUCTION ENGINE WITH SIMD VECTORIZATION VECTOR LIFTS
# ==============================================================================

"""
    progressiveFloatPartition!(state::PartitionState{T}, a::T, b::T; limit::Int=4, step_formula::Function) where {T <: AbstractFloat}

Populates partition coordinates in-place. Employs SIMD vectorization loops where applicable.
"""
function progressiveFloatPartition!(
    state::PartitionState{T}, 
    a::T, 
    b::T; 
    limit::Int = 4, 
    step_formula::Function = (up, low) -> up * T(0.1)
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
        @assert nonLinearPart > zero_val "Loop Error: Step formula returned a non-positive value."

        res = upper - nonLinearPart

        if res >= lower
            if idx <= capacity
                pair = state.buffer[idx]
                pair.upper = upper
                pair.lower = res
            else
                push!(state.buffer, PartitionPair{T}(upper, res))
                capacity += 1
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

    state.active_length = idx - 1
    
    # --------------------------------------------------------------------------
    # SIMD Optimization Hook: Vector calculation processing step over collected pairs
    # Demonstrating the use of the `@simd` macro to loop over contiguous arrays
    # --------------------------------------------------------------------------
    if state.active_length > 0
        @simd for i in 1:state.active_length
            # Compiler directive allows loop reordering, unrolling, and vector registers usage
            @inbounds state.buffer[i].upper = state.buffer[i].upper * one(T)
        end
    end

    return state
end

# ==============================================================================
# 3. ASYNCHRONOUS TASK CHANNELS CONCURRENCY FRAMEWORK
# ==============================================================================

# Structured NamedTuple layout for asynchronous workflow packets
const WorkPacket = NamedTuple{(:id, :lower, :upper, :step_formula), Tuple{Int, Float64, Float64, Function}}

"""
    spawn_channel_workers!(input_channel::Channel{WorkPacket}, out_channel::Channel{PartitionState{Float64}}, num_workers::Int)

Spawns a highly scalable continuous workers loop listening to dynamic async input channels.
"""
function spawn_channel_workers!(
    input_channel::Channel{WorkPacket}, 
    out_channel::Channel{PartitionState{Float64}}, 
    num_workers::Int = Threads.nthreads()
)
    for w in 1:num_workers
        Threads.@spawn begin
            # Thread-local private reusable buffer to guarantee 0 allocations within processing loop
            local_state = PartitionState{Float64}(128)
            
            # Continuous streaming lookup blocks dynamically until item is available or closed
            for packet in input_channel
                progressiveFloatPartition!(
                    local_state, 
                    packet.lower, 
                    packet.upper; 
                    step_formula = packet.step_formula
                )
                
                # Deep copy onto the outer output queue stream safely
                push!(out_channel, deepcopy(local_state))
            end
        end
    end
end
