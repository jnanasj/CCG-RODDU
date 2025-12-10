module Multiknapsack

using JuMP, Gurobi

include("data_structures.jl")
include("reformulation.jl")

export MultiknapsackParameters, 
    GeneralModelParameters, 
    reformulation, 
    ReformulationSolutionInfo
end