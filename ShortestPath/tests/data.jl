# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(num_nodes::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the shortest path problem
    SPParams = ShortestPathParams(num_nodes=num_nodes, α=α)

    # temporary euclidean graph in R^2 with num_nodes number of nodes
    SPParams.nodes = rand(rng, 2, num_nodes)
    graph, distances = euclidean_graph(SPParams.nodes, p=2, bc=:periodic)

    # sorting distances
    distances = sort(collect(distances), by = x -> x[2])

    SPParams.source = src(distances[end][1]) # source of the longest edge in the temporary graph
    SPParams.sink = dst(distances[end][1]) # destination of the longest edge in the temporary graph
    
    # remove 100α% of the longest edges from the temporary graph
    SPParams.num_edges = Int(round(α*ne(graph)))
    for edge in SPParams.num_edges+1:ne(graph)
        rem_edge!(graph, distances[edge][1])
    end

    SPParams.distances = distances

    # Convert shortest path problem to general model
    ModelParams = GeneralModelParameters(num_x=SPParams.num_edges, num_y=SPParams.num_edges+1, num_y_bin=SPParams.num_edges, num_ξ=SPParams.num_edges, num_cons = 2*num_nodes+1, num_ξcons=1, num_ξset=2*SPParams.num_edges+1)

    # objective function
    ModelParams.cost_y[ModelParams.num_y] = 1 # epigraph variable

    # constraints without uncertainty
    # routing constraints
    for n in 1:num_nodes, e in 1:SPParams.num_edges
        if dst(distances[e][1]) == n
            ModelParams.Dtilde[n, e] = -1
            ModelParams.Dtilde[num_nodes+n, e] = 1
        elseif src(distances[e][1]) == n
            ModelParams.Dtilde[n, e] = 1
            ModelParams.Dtilde[num_nodes+n, e] = -1
        end
        if n == SPParams.source
            ModelParams.btilde[n] = 1
            ModelParams.btilde[num_nodes+n] = -1
        elseif n == SPParams.sink
            ModelParams.btilde[n] = -1
            ModelParams.btilde[num_nodes+n] = 1
        end
    end
    
    # limits on reinforcements ∑_e x_e ≤ 0.3*num_edges
    ModelParams.Atilde[ModelParams.num_cons, 1:ModelParams.num_x] .= 1
    ModelParams.btilde[ModelParams.num_cons] = 0.3*SPParams.num_edges

    # constraints with uncertainty
    ModelParams.d[1, ModelParams.num_y] = -1 # epigraph variable
    ModelParams.a[1, 1:ModelParams.num_x] .= 1 # c_e x_e
    for e in 1:SPParams.num_edges
        ModelParams.d[1, e] = distances[e][2]
        ModelParams.Dbar[1, e, e] = distances[e][2]
    end

    # uncertainty set
    ModelParams.W[1:ModelParams.num_ξ, 1:ModelParams.num_ξ] = -LinearAlgebra.I(ModelParams.num_ξ)

    ModelParams.W[ModelParams.num_ξ+1:2*ModelParams.num_ξ, 1:ModelParams.num_ξ] = LinearAlgebra.I(ModelParams.num_ξ)
    ModelParams.v[ModelParams.num_ξ+1:2*ModelParams.num_ξ] .= 1
    ModelParams.U[ModelParams.num_ξ+1:2*ModelParams.num_ξ, 1:ModelParams.num_x] = -0.2*LinearAlgebra.I(ModelParams.num_ξ)

    ModelParams.W[ModelParams.num_ξset, 1:ModelParams.num_ξ] .= 1
    ModelParams.U[ModelParams.num_ξset, 1:ModelParams.num_x] .= -0.2
    ModelParams.v[ModelParams.num_ξset] = round(SPParams.num_edges/5)
    
    return ModelParams
end
