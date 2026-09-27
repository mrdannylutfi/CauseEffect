#tree.jl

"""
1. Defining the Structure and FunctionFirst, let's define a simple tree node and a function that builds a balanced binary tree from an array of values.
"""
using Test
using AbstractTrees
using D3Trees

# Define a simple binary tree node
mutable struct TreeNode{T}
    val::T
    left::Union{TreeNode{T}, Nothing}
    right::Union{TreeNode{T}, Nothing}
end

# Make it compatible with AbstractTrees
AbstractTrees.children(node::TreeNode) = filter(!isnothing, [node.left, node.right])
AbstractTrees.nodevalue(node::TreeNode) = node.val

# Function to build a balanced binary tree from an array
function build_balanced_tree(arr::AbstractVector{T}) where T
    isempty(arr) && return nothing
    mid = cld(length(arr), 2)
    node = TreeNode(arr[mid], nothing, nothing)
    node.left = build_balanced_tree(arr[1:mid-1])
    node.right = build_balanced_tree(arr[mid+1:end])
    return node
end

# Helper to count total nodes in the tree
count_nodes(::Nothing) = 0
count_nodes(node::TreeNode) = 1 + count_nodes(node.left) + count_nodes(node.right)

"""
2. Automated Regression Test SuiteWe use Julia's @testset to verify that our tree builder correctly processes inputs of size 10, 100, and 1,000, ensuring the number of tree nodes always matches the input array length and root values are assigned correctly.
"""

@testset "Binary Tree Regression Tests" begin
    for n in [10, 100, 1000]
        @testset "Array size: $n" begin
            input_data = collect(1:n)
            root = build_balanced_tree(input_data)

            # Verify total nodes match input size
            @test count_nodes(root) == n

            # Verify root value is positioned at the middle index
            @test root.val == cld(n, 2)

            # Verify tree is not empty for non-empty input
            @test root !== nothing
        end
    end
end

"""
3. Interactive Hierarchy Graph VisualizationTo visualize the tree interactively, we can convert our TreeNode structure into a D3Trees object. This generates an interactive HTML-based collapsible tree hierarchy.

"""
function visualize_tree(root::TreeNode)
    # Convert our tree structure into a D3Trees representation
    # Using AbstractTrees integration via D3Trees
    dt = D3Tree(root, nodetext = string ∘ nodevalue)
    return dt
end

# Example usage with a smaller array size (e.g., 10 elements) for clean rendering
sample_root = build_balanced_tree(1:10)
interactive_graph = visualize_tree(sample_root)

# To display in a Jupyter notebook or export to an HTML file:
# display(interactive_graph)
# Int(ccall(:jl_generating_output, Cint, ())) == 0 && save("tree_visualization.html", interactive_graph)


"""
This automated suite ensures robustness and correctness across different scales, while the visualization tool provides immediate graphical feedback on the structural integrity of the generated hierarchies.

"""
