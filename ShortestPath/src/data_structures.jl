@kwdef mutable struct ShortestPathParams
    num_nodes::Int64 # number of nodes
    α::Float64 # controls number of edges
    num_edges::Int64 = 0

    source::Int64 = 0
    sink::Int64 = 0

    nodes = nothing
    distances = nothing
end

@kwdef mutable struct GeneralModelParameters
    num_x::Int64 = 0 # number of decisions that affect uncertainty
    num_x_bin::Int64 = 0 # number of binary decisions that affect uncertainty (num_x_cont = num_x - num_x_bin)
    num_y::Int64 = 0 # number of decisions that do not affect uncertainty
    num_y_bin::Int64 = 0 # number of binary decisions that do not affect uncertainty (num_x_cont = num_x - num_x_bin)
    num_ξ::Int64 = 0 # number of uncertain parameters

    num_cons::Int64 = 0 # number of constraints without uncertainty
    num_ξcons::Int64 = 0 # number of constraints with uncertainty
    num_ξset::Int64 = 0 # number of hyperplanes in uncertainty set

    Atilde::Matrix{Float64} = spzeros(num_cons, num_x) # coefficients of x in constraints without uncertainty
    Dtilde::Matrix{Float64} = spzeros(num_cons, num_y) # coefficients of y in constraints without uncertainty
    btilde::Vector{Float64} = spzeros(num_cons) # RHS in constraints without uncertainty

    a::Matrix{Float64} = zeros(num_ξcons, num_x) # coefficients of x in constraints with uncertainty
    d::Matrix{Float64} = zeros(num_ξcons, num_y) # coefficients of y in constraints with uncertainty
    b::Vector{Float64} = zeros(num_ξcons) # RHS in constraints with uncertainty

    Abar::Array{Float64, 3} = zeros(num_ξcons, num_ξ, num_x) # coefficients of (xξ) in constraints with uncertainty
    Dbar::Array{Float64, 3} = zeros(num_ξcons, num_ξ, num_y) # coefficients of (yξ) in constraints with uncertainty
    bbar::Matrix{Float64} = zeros(num_ξcons, num_ξ) # coefficients of ξ in constraints with uncertainty

    cost_x::Vector{Float64} = spzeros(num_x) # cost vector for x
    cost_y::Vector{Float64} = spzeros(num_y) # cost vector for y

    W::Matrix{Float64} = spzeros(num_ξset, num_ξ) # coefficients of ξ in uncertainty set
    U::Matrix{Float64} = spzeros(num_ξset, num_x) # coefficients of x in uncertainty set
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
    basis_constraints::Union{Vector{Int64}, Nothing}
    basis_variables::Union{Vector{Int64}, Nothing}
end

@kwdef mutable struct CCGSolutionInfo
    status = nothing
    objective::Vector{Float64} = []
    solvetime::Vector{Float64} = []
    num_iters::Int64 = 0
    worst_constraint_violation::Vector{Float64} = []
    x_sol = nothing
    y_sol = nothing
    bases_constraints = Dict()
    bases_variables = Dict()
    num_variables::Int64 = 0
    num_constraints::Int64 = 0
    num_quad_constraints::Int64 = 0
end