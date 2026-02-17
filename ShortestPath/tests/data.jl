# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(num_nodes::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the shortest path problem
    SPParams = ShortestPathParams(num_nodes=num_nodes, α=α)
    γ = 0.2
    SPParams.cost = 0.05

    # temporary euclidean graph in R^2 with num_nodes number of nodes
    SPParams.nodes = rand(rng, 2, num_nodes)
    graph, distances = euclidean_graph(SPParams.nodes, p=2, bc=:periodic)

    # sorting distances
    distances = sort(collect(distances), by = x -> x[2])

    SPParams.source = src(distances[end][1]) # source of the longest edge in the temporary graph
    SPParams.sink = dst(distances[end][1]) # destination of the longest edge in the temporary graph
    
    # remove 100(1-α)% of the longest edges from the temporary graph
    SPParams.num_edges = Int(round(α*ne(graph)))
    for edge in SPParams.num_edges+1:ne(graph)
        rem_edge!(graph, distances[edge][1])
    end

    SPParams.distances = distances

    # uncertainty set
    SPParams.num_ξset = 2*SPParams.num_edges+1

    SPParams.W = spzeros(SPParams.num_ξset, SPParams.num_edges)
    SPParams.U = spzeros(SPParams.num_ξset, SPParams.num_edges)
    SPParams.v = spzeros(SPParams.num_ξset)

    SPParams.W[1:SPParams.num_edges, 1:SPParams.num_edges] = -LinearAlgebra.I(SPParams.num_edges)

    SPParams.W[SPParams.num_edges+1:2*SPParams.num_edges, 1:SPParams.num_edges] = LinearAlgebra.I(SPParams.num_edges)
    SPParams.v[SPParams.num_edges+1:2*SPParams.num_edges] .= 1
    SPParams.U[SPParams.num_edges+1:2*SPParams.num_edges, 1:SPParams.num_edges] = -γ*LinearAlgebra.I(SPParams.num_edges)

    SPParams.W[SPParams.num_ξset, 1:SPParams.num_edges] .= 1
    SPParams.v[SPParams.num_ξset] = 2
    
    return SPParams
end
