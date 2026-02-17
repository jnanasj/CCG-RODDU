using Pkg
Pkg.activate(".")
Pkg.resolve() # resolves incompatible julia versions on MSI
Pkg.instantiate()

using ShortestPath
using XLSX, Random, SparseArrays
using Graphs
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

instances = 1:10

problem_properties = Dict("1" => [50],
    "2" => [80],
    "3" => [100], 
    "4" => [150],
    "5" => [200],  
    "6" => [250],
    "7" => [300],
)

# specify shortest path problem's size
# num_nodes = Int(problem_properties[ARGS[1]][1]) # number of nodes in the graph
num_nodes = 150 # number of nodes in the graph
α = 0.4 # 100(1-α)% of longest edges are removed

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 3600.0
GAP = 0.001
ITERS_MAX = 50
BIG_M = 1e3
CONSTRAINT_TOL = 0.0
MULTI_CUT = true

# seeds for random instance generation
seeds = [12345, 45321, 23456, 65432, 76543, 45678, 14532, 23451, 78695, 68579]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    SPParams = data_generator(num_nodes, α, seeds[instance])

    # solve the reformulation model
    solvetime_reform = @elapsed ReformSol = reformulation(SPParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations
    solvetime_ccg = @elapsed CCGSol = CCG(SPParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, solvetime_reform, instance)
    ccg_spreadsheet(CCGSol, solvetime_ccg, instance)
end