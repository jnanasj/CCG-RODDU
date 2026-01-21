# using Pkg
# Pkg.instantiate()

using ShortestPath
using XLSX, Random
using Graphs, SimpleGraphs
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

instance = 1
# instances = 1:5

# specify shortest path problem's size
num_nodes = 100 # number of nodes in the graph
α = 0.7 # 100(1-α)% of longest edges are removed

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000.0
GAP = 0.001
ITERS_MAX = 100
BIG_M = 1e3
CONSTRAINT_TOL = 0.0

# seeds for random instance generation
seeds = [12345, 54321, 23456, 65432, 34567, 76543, 45678, 87654, 56789, 98765]
num_nodes_list = [100]

# # empty spreadsheets to save results
# create_spreadsheet("reformulation")
# create_spreadsheet("CCG")

# for instance in instances
# generate random instance for the mulitknapsack problem
ModelParams = data_generator(num_nodes_list[1], α, seeds[instance])

# solve the reformulation model
ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

# solve CCG and save results across iterations
CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

# # save the results
# reformulation_spreadsheet(ReformSol, instance)
# ccg_spreadsheet(CCGSol, instance)
# end