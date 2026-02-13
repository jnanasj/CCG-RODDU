module NetworkInvestment

using JuMP, Gurobi, SparseArrays, Graphs

include("data_structures.jl")
include("reformulation.jl")
include("master_problem.jl")
include("subproblem.jl")
include("CCG_algorithm.jl")

export NetworkInvestmentParams, 
    GeneralModelParameters, 
    reformulation, 
    CCG,
    CCGSolutionInfo,
    ReformulationSolutionInfo
end