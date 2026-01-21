# using Pkg
# Pkg.instantiate()

using DesignForFlexibility
using XLSX, Random, SparseArrays
import LinearAlgebra

include("data.jl") # function to create random instance of the robust facility location problem
include("results.jl") # function to save results to spreadsheets

# data files 
process_data = "./data_process.xlsx"
price_data = "./data_ercot_2023.xlsx"

# Specs
TIME_LIMIT = 9000.0
MP_TIME_LIMIT = 2000.0
GAP = 0.005
ITERS_MAX = 50
BIG_M = 5e3
CONSTRAINT_TOL = 0.0

# empty spreadsheets to save results
# create_spreadsheet("reformulation")
# create_spreadsheet("CCG")

# data for the compressor train case study
DFFParams, ModelParams = data_generator(process_data, price_data)

# solve the reformulation model
ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

# solve CCG and save results across iterations
CCGSol = CCG(ModelParams, ITERS_MAX, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

# # save the results
# reformulation_spreadsheet(ReformSol, instance)
# ccg_spreadsheet(CCGSol, instance)