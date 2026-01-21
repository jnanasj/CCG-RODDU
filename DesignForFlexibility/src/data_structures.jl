@kwdef mutable struct DesignForFlexibilityParams
    I::Int64 # number of compressors
    J::Int64 # number of products/storage tanks
    S::Int64 # number of seasons
    T::Int64 # number of time periods in a scheduling horizon

    β::Float64 # risk preference

    tank_cost::Vector{Float64} = zeros(J) # variable cost of storage tank j
    compressor_cost::Vector{Float64} = zeros(I) # variable cost of compressor i

    tank_min::Vector{Float64} = zeros(J) # minimum storage tank size
    tank_max::Vector{Float64} = zeros(J) # maximum storage tank size
    compressor_min::Vector{Float64} = zeros(I) # minimum compressor size
    compressor_max::Vector{Float64} = zeros(I) # maximum compressor size

    power_price::Vector{Float64} = zeros(S*T) # electricity price
    load_price::Vector{Float64} = zeros(S*T) # interruptible load price

    power_compressor::Vector{Float64} = zeros(I) # variable electricity consumption for compressor i
    compressor_flexibility::Float64 = 0.4 # (minimum compressor flowrate)/(compressor size)
    demand::Matrix{Float64} = zeros(J, S*T)
    bigM::Float64 = 0.0 # recourse coefficient limits

    load_min::Float64 = 0.0
    load_max::Float64 = 0.0
    Γ_min::Float64 = 1.0 # minimum value of Γ_st
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

    lower_x::Vector{Float64} = spzeros(num_x) # lower bound of variables 'x'
    upper_x::Vector{Float64} = spzeros(num_x) # upper bound of variables 'x'
    lower_y::Vector{Float64} = spzeros(num_y) # lower bound of variables 'y'
    upper_y::Vector{Float64} = spzeros(num_y) # upper bound of variables 'y'
    lower_ξ::Vector{Float64} = spzeros(num_ξ) # lower bound of variables 'ξ'
    upper_ξ::Vector{Float64} = spzeros(num_ξ) # upper bound of variables 'ξ'

    Atilde::Matrix{Float64} = spzeros(num_cons, num_x) # coefficients of x in constraints without uncertainty
    Dtilde::Matrix{Float64} = spzeros(num_cons, num_y) # coefficients of y in constraints without uncertainty
    btilde::Vector{Float64} = spzeros(num_cons) # RHS in constraints without uncertainty

    a::Matrix{Float64} = spzeros(num_ξcons, num_x) # coefficients of x in constraints with uncertainty
    d::Matrix{Float64} = spzeros(num_ξcons, num_y) # coefficients of y in constraints with uncertainty
    b::Vector{Float64} = spzeros(num_ξcons) # RHS in constraints with uncertainty

    Abar = Dict(i => spzeros(num_ξ, num_x) for i in 1:num_ξcons) # coefficients of (xξ) in constraints with uncertainty
    Dbar = Dict(i => spzeros( num_ξ, num_y) for i in 1:num_ξcons) # coefficients of (yξ) in constraints with uncertainty
    bbar::Matrix{Float64} = spzeros(num_ξcons, num_ξ) # coefficients of ξ in constraints with uncertainty

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