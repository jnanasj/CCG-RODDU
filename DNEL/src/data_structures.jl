@kwdef mutable struct DNELParameters
    N::Int64 # number of buses in the system

    I::Int64 = 0 # number of generators (not including renewables)
    J::Int64 = 0 # number of renewable generators
    K::Int64 = 0 # number of loads
    L::Int64 = 0 # number of transmission lines

    scaling_factor::Float64 = 0 # scaling factor

    generators = Dict() # bus where generators are present => reference dispatch, reserve, min capacity, max capacity
    renewables = Dict() # bus where renewables are present => contribution factor, nominal capacity, min capacity, max capacity
    loads = Dict() # bus where demand exists => demand
    lines = Dict() # (from bus, to bus) => line flow distribution, transmission limit
end

@kwdef mutable struct GeneralModelParameters
    num_x::Int64 = 0 # number of decisions that affect uncertainty
    num_y::Int64 = 0 # number of decisions that do not affect uncertainty
    num_ξ::Int64 = 0 # number of uncertain parameters

    num_cons::Int64 = 0 # number of constraints without uncertainty
    num_ξcons::Int64 = 0 # number of constraints with uncertainty
    num_ξset::Int64 = 0 # number of hyperplanes in uncertainty set

    lower_x::Vector{Float64} = spzeros(num_x) # lower bound of variables 'x'
    upper_x::Vector{Float64} = spzeros(num_x) # upper bound of variables 'x'
    lower_y::Vector{Float64} = spzeros(num_y) # lower bound of variables 'y'
    upper_y::Vector{Float64} = spzeros(num_y) # upper bound of variables 'y'
    lower_ξ::Vector{Float64} = spzeros(num_ξ) # lower bound of variables 'ξ'
    upper_ξ::Vector{Float64} = spzeros(num_ξ) # upper bound of variables 'ξ'

    a::Matrix{Float64} = zeros(num_ξcons, num_x) # coefficients of x in constraints with uncertainty
    d::Matrix{Float64} = zeros(num_ξcons, num_y) # coefficients of y in constraints with uncertainty
    b::Vector{Float64} = zeros(num_ξcons) # RHS in constraints with uncertainty

    Abar::Array{Float64, 3} = zeros(num_ξcons, num_ξ, num_x) # coefficients of (xξ) in constraints with uncertainty
    Dbar::Array{Float64, 3} = zeros(num_ξcons, num_ξ, num_y) # coefficients of (yξ) in constraints with uncertainty
    bbar::Matrix{Float64} = zeros(num_ξcons, num_ξ) # coefficients of ξ in constraints with uncertainty

    cost_x::Vector{Float64} = zeros(num_x) # cost vector for x
    cost_y::Vector{Float64} = zeros(num_y) # cost vector for y

    W::Matrix{Float64} = zeros(num_ξset, num_ξ) # coefficients of ξ in uncertainty set
    U::Matrix{Float64} = zeros(num_ξset, num_x) # coefficients of x in uncertainty set
    v::Vector{Float64} = zeros(num_ξset) # RHS in uncertainty set
end

@kwdef mutable struct ReformulationSolutionInfo
    status = nothing
    objective::Union{Float64, Nothing} = nothing
    bound::Union{Float64, Nothing} = nothing
    gap::Union{Float64, Nothing} = nothing
    solvetime::Union{Float64, Nothing} = nothing
    x_sol = nothing
    y_sol = nothing
    num_variables_cont::Union{Int64, Nothing} = nothing
    num_variables_bin::Union{Int64, Nothing} = nothing
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
    num_variables_cont::Int64 = 0
    num_variables_bin::Int64 = 0
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
    num_variables_cont::Int64 = 0
    num_variables_bin::Int64 = 0
    num_constraints::Int64 = 0
    num_quad_constraints::Int64 = 0
end