@kwdef mutable struct ShortestPathParams
    num_nodes::Int64 # number of nodes
    α::Float64 # controls number of edges
    num_edges::Int64 = 0

    source::Int64 = 0
    sink::Int64 = 0

    nodes = nothing
    distances = nothing

    cost::Float64 = 0

    num_ξset::Int64 = 2*num_edges+1 # number of equations defining uncertainty set

    W::Matrix{Float64} = spzeros(num_ξset, num_edges) # coefficients of ξ in uncertainty set
    U::Matrix{Float64} = spzeros(num_ξset, num_edges) # coefficients of x in uncertainty set
    v::Vector{Float64} = spzeros(num_ξset) # RHS in uncertainty set
end

@kwdef mutable struct ReformulationSolutionInfo
    status = nothing
    objective::Union{Float64, Nothing} = nothing
    bound::Union{Float64, Nothing} = nothing
    gap::Union{Float64, Nothing} = nothing
    solvetime::Union{Float64, Nothing} = nothing
    x_sol = nothing
    y_sol = nothing
    num_variables::Union{Int64, Nothing} = nothing
    num_constraints::Union{Int64, Nothing} = nothing
    num_quad_constraints::Union{Int64, Nothing} = nothing
end

@kwdef mutable struct MPSolutionInfo
    status
    objective::Union{Float64, Nothing} = nothing
    bound::Union{Float64, Nothing} = nothing
    gap::Union{Float64, Nothing} = nothing
    solvetime::Union{Float64, Nothing} = nothing
    x_sol = nothing
    y_sol = nothing
    num_variables::Int64 = 0
    num_constraints::Int64 = 0
    num_quad_constraints::Int64 = 0
end

@kwdef mutable struct SPSolutionInfo
    status = nothing
    objective::Union{Float64, Nothing}
    basis_constraints = Dict()
    basis_variables = Dict()
end

@kwdef mutable struct CCGSolutionInfo
    status = nothing
    objective::Vector{Float64} = []
    solvetime::Vector{Float64} = []
    num_iters::Int64 = 0
    worst_constraint_violation::Vector{Float64} = []
    gap::Vector{Float64} = []
    x_sol = nothing
    y_sol = nothing
    bases_constraints = Dict()
    bases_variables = Dict()
    num_variables::Int64 = 0
    num_constraints::Int64 = 0
    num_quad_constraints::Int64 = 0
end