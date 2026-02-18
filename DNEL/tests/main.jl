using Pkg
Pkg.activate(".")
Pkg.resolve() # resolves incompatible julia versions on MSI
Pkg.instantiate()

using DNEL
using XLSX, Random, SparseArrays
import LinearAlgebra

include("data.jl")
include("results.jl")

# problem details
instances = 1:3
N = [5, 39, 118]

# Specs
TIME_LIMIT = 3600.0
MP_TIME_LIMIT = 3600.0
GAP = 0.001
ITERS_MAX = 50
BIG_M = 5e3
CONSTRAINT_TOL = 0.0
MULTI_CUT = false

for instance in instances
    # data
    data_file = string("data/data_", N[instance], "_bus.xlsx")
    DNELParams, ModelParams = data_generator(N[instance], data_file)

    # solve the reformulation model
    solvetime_reform = @elapsed ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations
    solvetime_ccg = @elapsed CCGSol = CCG(ModelParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)
    solvetime_ccg_proj = @elapsed CCGSol_proj = CCG_projection(ModelParams, ITERS_MAX, MULTI_CUT, TIME_LIMIT, MP_TIME_LIMIT, GAP, BIG_M, CONSTRAINT_TOL)

    # save the results
    results(ReformSol, solvetime_reform, CCGSol, solvetime_ccg, CCGSol_proj, solvetime_ccg_proj, instance, MULTI_CUT)
end