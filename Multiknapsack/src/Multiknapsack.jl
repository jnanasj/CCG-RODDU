module Multiknapsack

using JuMP, Gurobi

include("data_structures.jl")
include("reformulation.jl")
include("master_problem.jl")
include("subproblem.jl")
include("CCG_algorithm.jl")

export MultiknapsackParameters, 
    GeneralModelParameters, 
    reformulation, 
    CCG,
    CCGSolutionInfo,
    ReformulationSolutionInfo
end