module ShortestPath

using JuMP, Gurobi, SparseArrays

include("data_structures.jl")
include("reformulation.jl")
include("master_problem.jl")
include("subproblem.jl")
include("CCG_algorithm.jl")

export ShortestPathParams, 
    GeneralModelParameters, 
    reformulation, 
    CCG,
    CCGSolutionInfo,
    ReformulationSolutionInfo
end