# using Pkg
# Pkg.activate(".")
# Pkg.instantiate()

using Multiknapsack
using XLSX, Random
import LinearAlgebra

include("data.jl")
include("results.jl")

# instance = ARGS[1]
instances = 1:10

# problem_properties_fixed = Dict("1" => [20, 50, 0, 0.25],
#     "2" => [20, 50, 0, 0.50],
#     "3" => [20, 50, 0, 0.75],
#     "4" => [20, 100, 0, 0.25],
#     "5" => [20, 100, 0, 0.50],
#     "6" => [20, 100, 0, 0.75],
#     "7" => [50, 200, 0, 0.25],
#     "8" => [50, 200, 0, 0.50],
#     "9" => [50, 200, 0, 0.75],
#     "10" => [100, 200, 0, 0.25],
#     "11" => [100, 200, 0, 0.50],
#     "12" => [100, 200, 0, 0.75],
#     "13" => [200, 400, 0, 0.25],
#     "14" => [200, 400, 0, 0.50],
#     "15" => [200, 400, 0, 0.75],
# )

# problem_properties = Dict("1" => [200, 400, 0, 0.25],
#     "2" => [200, 400, 0, 0.50],
#     "3" => [200, 400, 0, 0.75],
#     "4" => [200, 400, 0, 0.25],
#     "5" => [200, 400, 0, 0.50],
#     "6" => [200, 400, 0, 0.75],
# )

problem_properties = Dict("1" => [5, 10, 1, 0.25],
    "2" => [5, 10, 1, 0.50],
    "3" => [5, 10, 1, 0.75],
    "4" => [10, 20, 1, 0.25],
    "5" => [10, 20, 1, 0.50],
    "6" => [10, 20, 1, 0.75],
    "7" => [10, 40, 1, 0.25],
    "8" => [10, 40, 1, 0.50],
    "9" => [10, 40, 1, 0.75],
    "10" => [20, 40, 1, 0.25],
    "11" => [20, 40, 1, 0.50],
    "12" => [20, 40, 1, 0.75],
    # "13" => [20, 40, 10, 0.25],
    # "14" => [20, 40, 10, 0.50],
    # "15" => [20, 40, 10, 0.75],
    # "16" => [20, 40, 20, 0.25],
    # "17" => [20, 40, 20, 0.50],
    # "18" => [20, 40, 20, 0.75],
)

# problem_properties = Dict("1" => [5, 10, 1, 0.25],
#     "2" => [5, 10, 1, 0.50],
#     "3" => [5, 10, 1, 0.75],
#     "4" => [5, 10, 5, 0.25],
#     "5" => [5, 10, 5, 0.50],
#     "6" => [5, 10, 5, 0.75],
#     "7" => [5, 20, 5, 0.25],
#     "8" => [5, 20, 5, 0.50],
#     "9" => [5, 20, 5, 0.75],
#     "10" => [10, 20, 10, 0.25],
#     "11" => [10, 20, 10, 0.50],
#     "12" => [10, 20, 10, 0.75],
#     "13" => [20, 40, 10, 0.25],
#     "14" => [20, 40, 10, 0.50],
#     "15" => [20, 40, 10, 0.75],
#     "16" => [20, 40, 20, 0.25],
#     "17" => [20, 40, 20, 0.50],
#     "18" => [20, 40, 20, 0.75],
# )

# specify mulitknapsack problem's size and properties
# M = Int(problem_properties[ARGS[1]][1]) # number of constraints/knapsacks
# N = Int(problem_properties[ARGS[1]][2]) # number of decision variables/items
# T = Int(problem_properties[ARGS[1]][3]) # if T == 0, fixed recourse; if T > 0, random recourse
# α = problem_properties[ARGS[1]][4] # tightness parameter

M = 20 # number of constraints/knapsacks
N = 100 # number of decision variables/items
T = 1 # if T == 0, fixed recourse; if T > 0, random recourse
α = 0.50 # tightness parameter

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000.0
GAP = 0.001
ITERS_MAX = 50
BIG_M = 5e3
CONSTRAINT_TOL = 0.0

# seeds for random instance generation
seeds = [12345, 54321, 23456, 65432, 34567, 76543, 45678, 87654, 56789, 98765]

# empty spreadsheets to save results
create_spreadsheet("reformulation", M, N, T, α)
create_spreadsheet("CCG", M, N, T, α)

for instance in instances
    # generate random instance for the mulitknapsack problem
    ModelParams = data_generator(M, N, T, α, seeds[instance])

    # solve the reformulation model
    solvetime_reform = @elapsed ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations
    solvetime_ccg = @elapsed CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, solvetime_reform, instance, M, N, T, α)
    ccg_spreadsheet(CCGSol, solvetime_ccg, instance, M, N, T, α)
end