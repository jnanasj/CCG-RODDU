# using Pkg
# Pkg.activate(".")
# Pkg.resolve() # resolves incompatible julia versions on MSI
# Pkg.instantiate()

using DesignForFlexibility
using XLSX, Random, SparseArrays
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

# data files
process_data = "./data/data_process.xlsx"
price_data = "./data/data_ercot_2023.xlsx"

# Specs
TIME_LIMIT = 100.0
MP_TIME_LIMIT = 100.0
GAP = 0.005
ITERS_MAX = 2
BIG_M = 1e3
CONSTRAINT_TOL = 0.0
MULTI_CUT = true

problem_properties = Dict("1" => [1, 1, 12],
    "2" => [2, 2, 12],
    "3" => [3, 1, 24],
    "4" => [4, 2, 24],
    "5" => [5, 4, 12],
    "6" => [6, 4, 24]
)

# S = Int(problem_properties[ARGS[1]][2]) # number of seasons
# T = Int(problem_properties[ARGS[1]][3]) # number of hours

S = 1 # number of seasons
T = 12 # number of hours


# data for the compressor train case study
DFFParams, ModelParams = data_generator(process_data, price_data, S, T)

# solve the reformulation model
# solvetime_reform = @elapsed ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

# solve CCG and save results across iterations
solvetime_ccg = @elapsed CCGSol = CCG(ModelParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

# save the results
# results(ReformSol, solvetime_reform, CCGSol, solvetime_ccg, Int(problem_properties[ARGS[1]][1]))