# using Pkg
# Pkg.activate(".")
# Pkg.instantiate()

using RobustFacilityLocation
using XLSX, Random
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

# instance = ARGS[1]
instances = 1:10

# problem_properties = Dict("1" => [20, 10, 0.1],
#     "2" => [20, 10, 0.5],
#     "3" => [20, 10, 1.0],
#     "4" => [40, 15, 0.1],
#     "5" => [40, 15, 0.5],
#     "6" => [40, 15, 1.0],
#     "7" => [40, 25, 0.1],
#     "8" => [40, 25, 0.5],
#     "9" => [40, 25, 1.0],
#     "10" => [80, 35, 0.1],
#     "11" => [80, 35, 0.5],
#     "12" => [80, 35, 1.0],
#     # "13" => [20, 40, 10, 0.25],
#     # "14" => [20, 40, 10, 0.50],
#     # "15" => [20, 40, 10, 0.75],
#     # "16" => [20, 40, 20, 0.25],
#     # "17" => [20, 40, 20, 0.50],
#     # "18" => [20, 40, 20, 0.75],
# )

# specify robust facility location problem's size and properties
# I = Int(problem_properties[ARGS[1]][1]) # number of customers
# J = Int(problem_properties[ARGS[1]][2]) # number of potential sites
# α = problem_properties[ARGS[1]][3] # tightness parameter

I = 80 # number of customers
J = 30 # number of potential sites
α = 0.1 # tightness parameter

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000.0
GAP = 0.001
ITERS_MAX = 500
BIG_M = 1e3
CONSTRAINT_TOL = 0.0

# seeds for random instance generation
seeds = [12345, 54321, 23456, 65432, 34567, 76543, 45678, 87654, 56789, 98765]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    RFLParams, ModelParams = data_generator(I, J, α, seeds[instance])

    # solve the reformulation model
    ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)
    
    # solve CCG and save results across iterations
    CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, instance)
    ccg_spreadsheet(CCGSol, instance)
end