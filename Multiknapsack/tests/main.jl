using Multiknapsack
# include("C:/Users/jagan024/Desktop/CCG-RODDU/Multiknapsack/src/Multiknapsack.jl")
using XLSX, Random
import LinearAlgebra

include("data.jl")
include("results.jl")

# specify mulitknapsack problem's size and propoerties
M = 5 # number of constraints/knapsacks
N = 10 # number of decision variables/items
T = 5 # if T == 0, fixed recourse; if T > 0, random recourse
α = 0.25 # tightness parameter

# Specs
TIME_LIMIT = 3600
MP_TIME_LIMIT = 1000
GAP = 0.01

# seeds for random instance generation
instances = 1:10
seeds = [12345, 12346, 12347, 12348, 12349, 123410,123411,123412, 123413, 123414]

# empty spreadsheets to save results
create_spreadsheet("reformulation")
# create_spreadsheet("CCG")

for instance in instances
    # generate random instance for the mulitknapsack problem
    ModelParams = data_generator(M, N, T, α, seeds[instance])

    # solve the reformulation model
    ReformSol = reformulation(ModelParams, TIME_LIMIT, GAP)

    # solve CCG and save results across iterations 

    # save the results
    reformulation_spreadsheet(ReformSol, instance)
end