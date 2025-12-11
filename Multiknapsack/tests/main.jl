using Multiknapsack
# include("C:/Users/jagan024/Desktop/CCG-RODDU/Multiknapsack/src/Multiknapsack.jl")
using XLSX, Random
import LinearAlgebra

include("data.jl")
include("results.jl")

# instance = ARGS[1]
instances = 1:10

# specify mulitknapsack problem's size and properties
M = 1 # number of constraints/knapsacks
N = 5 # number of decision variables/items
T = 6 # if T == 0, fixed recourse; if T > 0, random recourse
α = 0.25 # tightness parameter

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000
GAP = 0.001
ITERS_MAX = 4
BIG_M = 1e3
CONSTRAINT_TOL = 0.0

# seeds for random instance generation
seeds = [141199, 70496, 51275, 120269, 170799, 50999, 261199, 123499, 432199, 99123]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    ModelParams = data_generator(M, N, T, α, seeds[instance])

    # solve the reformulation model
    ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations
    CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, instance)
    ccg_spreadsheet(CCGSol, instance)
end