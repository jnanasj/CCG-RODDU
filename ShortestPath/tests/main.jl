# using Pkg
# Pkg.instantiate()

using ShortestPath
using XLSX, Random
using Graphs, SimpleGraphs
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

# instance = 1
instances = 1:1

# specify shortest path problem's size
num_nodes = 50 # number of nodes in the graph
α = 0.6 # 100(1-α)% of longest edges are removed

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000.0
GAP = 0.001
ITERS_MAX = 50
BIG_M = 5e3
CONSTRAINT_TOL = 0.0

# seeds for random instance generation
seeds = [141199, 70496, 51275, 120269, 170799, 50999, 261199, 123499, 432199, 99123]
num_nodes_list = [250]

# empty spreadsheets to save results
# create_spreadsheet("reformulation")
create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    ModelParams = data_generator(num_nodes_list[instance], α, seeds[1])

    # solve the reformulation model
    # ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations
    CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    # reformulation_spreadsheet(ReformSol, instance)
    ccg_spreadsheet(CCGSol, instance)
end