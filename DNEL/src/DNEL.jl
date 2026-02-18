module DNEL

using JuMP, Gurobi, SparseArrays

include("data_structures.jl")
include("reformulation.jl")
include("master_problem.jl")
include("subproblem.jl")
include("CCG_algorithm.jl")
include("master_problem_projection.jl")
include("CCG_algorithm_projection.jl")

export DNELParameters, 
    GeneralModelParameters, 
    reformulation, 
    CCG,
    CCG_projection,
    CCGSolutionInfo,
    ReformulationSolutionInfo
end