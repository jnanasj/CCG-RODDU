using Pkg
Pkg.activate(".")
Pkg.resolve() # resolves incompatible julia versions on MSI
Pkg.instantiate()

using RobustFacilityLocation
using XLSX, Random
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

instances = 1:10

problem_properties = Dict("1" => [10, 5, 0.01],
    "2" => [10, 10, 0.01],
    "3" => [20, 10, 0.01],
    "4" => [30, 15, 0.01],
    "5" => [40, 15, 0.01],
    "6" => [40, 25, 0.01],
    "7" => [50, 25, 0.01],
)

# specify robust facility location problem's size and properties
# I = Int(problem_properties[ARGS[1]][1]) # number of customers
# J = Int(problem_properties[ARGS[1]][2]) # number of potential sites
# α = problem_properties[ARGS[1]][3] # tightness parameter

I = 60 # number of customers
J = 30 # number of potential sites
α = 0.01 # tightness parameter

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 1000.0
GAP = 0.001
ITERS_MAX = 50
BIG_M = 1e3
CONSTRAINT_TOL = 0.0
MULTI_CUT = true

# seeds for random instance generation
seeds = [15432, 23456, 65432, 34567, 76543, 45678, 87654, 56789, 9876]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    RFLParams, ModelParams = data_generator(I, J, α, seeds[instance])

    # solve the reformulation model
    solvetime_reform = @elapsed ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)
    
    # solve CCG and save results across iterations
    solvetime_ccg = @elapsed CCGSol = CCG(ModelParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    reformulation_spreadsheet(ReformSol, solvetime_reform, instance)
    ccg_spreadsheet(CCGSol, solvetime_ccg, instance)
end