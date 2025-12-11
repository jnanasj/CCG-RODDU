# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(I::Int64, J::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the robust facility location problem
    RFLParams = RobustFacilityLocationParams(I=I, J=J, α=α)

    RFLParams.fixed_cost = 100 * rand(rng, J)
    RFLParams.variable_cost = 10 * rand(rng, J) .+ 10
    RFLParams.transport_cost = 2 * rand(rng, I, J) .+ 2
    RFLParams.price = 5 * rand(rng, I) .+ 5

    RFLParams.capacity_min = rand(rng, J) .+ 1
    RFLParams.capacity_max = 10 * rand(rng, J) .+ 4

    RFLParams.demand_nominal = rand(rng, I)
    RFLParams.demand_min_deviation = 0.02 * ones(I, J)
    RFLParams.demand_max_deviation = 0.04 * ones(I, J)

    # Convert mulitknapsack problem to general model
    ModelParams = GeneralModelParameters(num_x=2 * J, num_x_bin=J, num_y=I * J + 1, num_ξ=2 * I, num_cons=(3 * J + 1), num_ξcons=I, num_ξset=(5 * I + 1))

    # objective function
    ModelParams.cost_x[1:J] = RFLParams.fixed_cost
    ModelParams.cost_x[J+1:2*J] = RFLParams.variable_cost
    ModelParams.cost_y[ModelParams.num_y] = 1

    # constraints without uncertainty
    # construction capacity limits
    ModelParams.Atilde[1:J, 1:J] = LinearAlgebra.Diagonal(RFLParams.capacity_min)
    ModelParams.Atilde[1:J, J+1:2*J] = -LinearAlgebra.I(J)

    ModelParams.Atilde[J+1:2*J, 1:J] = -LinearAlgebra.Diagonal(RFLParams.capacity_max)
    ModelParams.Atilde[J+1:2*J, J+1:2*J] = LinearAlgebra.I(J)

    # capacity limit on demand
    ModelParams.Atilde[2*J+1:3*J, J+1:2*J] = -LinearAlgebra.I(J)
    ModelParams.Dtilde[2*J+1:3*J, 1:I*J] = [mod(k, J) == j-1 ? 1 : 0 for j in 1:J, k in 1:I*J] # ∑_i y_{ij}

    # epigraph reformulation
    ModelParams.Dtilde[ModelParams.num_cons, ModelParams.num_y] = -1
    for i in 1:I, j in 1:J
        ModelParams.Dtilde[ModelParams.num_cons, (i-1)*J+j] = RFLParams.transport_cost[i, j] - RFLParams.price[i]
    end

    # constraints with uncertainty
    # demand satisfaction
    ModelParams.d[1:I, 1:I*J] = [((i - 1) * J < k && k <= i * J) ? -1 : 0 for i in 1:I, k in 1:I*J] # -∑_j y_{ij}
    ModelParams.b[1:I] = -RFLParams.demand_nominal
    ModelParams.bbar[1:I, 1:I] = -LinearAlgebra.Diagonal(RFLParams.demand_nominal)

    # uncertainty set
    # ξ_i >= \sum_j ()
    ModelParams.W[1:I, 1:I] = -LinearAlgebra.I(I)
    ModelParams.U[1:I, 1:J] = -RFLParams.demand_min_deviation

    # ξ_i <= \sum_j ()
    ModelParams.W[I+1:2*I, 1:I] = LinearAlgebra.I(I)
    ModelParams.U[I+1:2*I, 1:J] = RFLParams.demand_max_deviation

    # |ξ_i - 0.5* \sum_j()| <= d_i
    ModelParams.W[2*I+1:3*I, 1:I] = -LinearAlgebra.I(I)
    ModelParams.W[2*I+1:3*I, I+1:2*I] = -LinearAlgebra.I(I)
    ModelParams.U[2*I+1:3*I, 1:J] = -0.5 * (RFLParams.demand_min_deviation + RFLParams.demand_max_deviation)

    ModelParams.W[3*I+1:4*I, 1:I] = LinearAlgebra.I(I)
    ModelParams.W[3*I+1:4*I, I+1:2*I] = -LinearAlgebra.I(I)
    ModelParams.U[3*I+1:4*I, 1:J] = 0.5 * (RFLParams.demand_min_deviation + RFLParams.demand_max_deviation)

    # d_i >= 0
    ModelParams.W[4*I+1:5*I, I+1:2*I] = -LinearAlgebra.I(I)

    # \sum_i d_i <= 
    ModelParams.W[5*I+1, I+1:2*I] .= 1.0
    ModelParams.U[5*I+1, J+1:2*J] .= RFLParams.α / sum(RFLParams.demand_nominal)

    return ModelParams
end
