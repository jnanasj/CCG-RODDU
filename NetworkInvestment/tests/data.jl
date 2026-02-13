# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(num_nodes::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the shortest path problem
    NIParams = NetworkInvestmentParams(num_nodes=num_nodes, α=α)

    # temporary euclidean graph in R^2 with num_nodes number of nodes
    nodes = rand(rng, 2, num_nodes)
    graph, distances = euclidean_graph(nodes, p=2, bc=:periodic)

    # sorting distances
    distances = sort(collect(distances), by = x -> x[2])

    NIParams.source = src(distances[end][1]) # source of the longest edge in the temporary graph
    NIParams.sink = dst(distances[end][1]) # destination of the longest edge in the temporary graph
    
    # remove 100(1-α)% of the longest edges from the temporary graph
    NIParams.num_edges = Int(round(α*ne(graph)))
    for edge in NIParams.num_edges+1:ne(graph)
        rem_edge!(graph, distances[edge][1])
    end

    NIParams.distances = distances
    NIParams.transport_cost = zeros(NIParams.num_edges)
    NIParams.repair_cost = zeros(NIParams.num_edges)

    for e in 1:NIParams.num_edges
        NIParams.transport_cost[e] = distances[e][2]
        NIParams.repair_cost[e] = (50 + 20*rand(rng) - 10)distances[e][2]
    end
    NIParams.budget = 3*sum(NIParams.repair_cost)/10
    NIParams.ψ = 0.1

    # uncertainty set
    NIParams.num_ξset = 2*NIParams.num_edges+1

    NIParams.W = spzeros(NIParams.num_ξset, NIParams.num_edges)
    NIParams.U = spzeros(NIParams.num_ξset, NIParams.num_edges)
    NIParams.v = spzeros(NIParams.num_ξset)

    NIParams.W[1:NIParams.num_edges, 1:NIParams.num_edges] = -LinearAlgebra.I(NIParams.num_edges)

    NIParams.W[NIParams.num_edges+1:2*NIParams.num_edges, 1:NIParams.num_edges] = LinearAlgebra.I(NIParams.num_edges)
    NIParams.v[NIParams.num_edges+1:2*NIParams.num_edges] .= 1
    NIParams.U[NIParams.num_edges+1:2*NIParams.num_edges, 1:NIParams.num_edges] = -LinearAlgebra.I(NIParams.num_edges)
    
    NIParams.W[NIParams.num_ξset, 1:NIParams.num_edges] .= 1
    NIParams.U[NIParams.num_ξset, 1:NIParams.num_edges] .= -NIParams.ψ
    NIParams.v[NIParams.num_ξset] = NIParams.ψ*NIParams.num_edges
    
    return NIParams
end
