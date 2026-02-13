using Pkg
Pkg.activate(".")
Pkg.resolve() # resolves incompatible julia versions on MSI
Pkg.instantiate()

using NetworkInvestment
using XLSX, Random, SparseArrays
using Graphs
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

instance = 1
instances = 1:8

problem_properties = Dict("1" => [20, 1e2],
    "2" => [20, 5e2],  
    "3" => [20, 1e3], 
    "4" => [30, 1e2], 
    "5" => [30, 5e2],  
    "6" => [30, 1e3],
    "7" => [40, 1e2],
    "8" => [40, 5e2],  
    "9" => [40, 1e3],   
    "10" => [50, 1e2], 
    "11" => [50, 5e2],
    "12" => [50, 1e3],
    "13" => [80, 1e2],
    "14" => [80, 5e2],
    "15" => [80, 1e3],
)

# specify problem's size
# num_nodes = Int(problem_properties[ARGS[1]][1]) # number of nodes in the graph
num_nodes = 80 # number of nodes in the graph
α = 0.6 # 100(1-α)% of longest edges are removed

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 3600.0
GAP = 0.001
ITERS_MAX = 50
# BIG_M = problem_properties[ARGS[1]][2]
BIG_M = 1e3
CONSTRAINT_TOL = 0.0
MULTI_CUT = true

# seeds for random instance generation
seeds = [12345, 45321, 23456, 65432, 76543, 45678, 14532, 23451, 78695, 68579]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
create_spreadsheet("CCG")

# for instance in instances
    # generate random instance for the mulitknapsack problem
    NIParams = data_generator(num_nodes, α, seeds[instance])

    # solve the reformulation model
    solvetime_reform = @elapsed ReformSol = reformulation(NIParams, TIME_LIMIT, GAP, BIG_M)

    # solve CCG and save results across iterations
    solvetime_ccg = @elapsed CCGSol = CCG(NIParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, solvetime_reform, instance)
    ccg_spreadsheet(CCGSol, solvetime_ccg, instance)
# end