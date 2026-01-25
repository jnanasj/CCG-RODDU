# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(I::Int64, J::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the robust facility location problem
    RFLParams = RobustFacilityLocationParams(I=I, J=J, α=α)

    RFLParams.J_i = Dict(i => randperm(Xoshiro(seed+i), J)[1:rand(Xoshiro(seed+2*i), 1:(J-1))] for i in 1:I)

    RFLParams.fixed_cost = 100 * rand(rng, J) .+ 100
    RFLParams.variable_cost = 15 * rand(rng, J) .+ 15
    RFLParams.transport_cost = 5 * rand(rng, I, J) .+ 5
    for i in 1:I, j in RFLParams.J_i[i]
        RFLParams.transport_cost[i, j] = RFLParams.transport_cost[i, j] - 3
    end
    RFLParams.price = 20 * rand(rng, I) .+ 10

    RFLParams.capacity_min = 5*rand(rng, J) .+ 5
    RFLParams.capacity_max = 10 * rand(rng, J) .+ 50

    RFLParams.demand_nominal = rand(rng, I) .+ 1
    RFLParams.demand_min_deviation = 0.01 * ones(I, J)
    RFLParams.demand_max_deviation = 0.02 * ones(I, J)

    # Convert robust facility location problem to general model
    ModelParams = GeneralModelParameters(num_x=J, num_y=I * J + J + 1, num_y_bin = J, num_ξ=I, num_cons=(3 * J + I + 1), num_ξcons=I, num_ξset=(2 * I + 1))

    # objective function
    ModelParams.cost_x[1:J] = RFLParams.variable_cost
    ModelParams.cost_y[I*J+1:I*J+J] = RFLParams.fixed_cost
    ModelParams.cost_y[ModelParams.num_y] = 1

    # constraints without uncertainty
    # construction capacity limits
    ModelParams.Dtilde[1:J, I*J+1:I*J+J] = LinearAlgebra.Diagonal(RFLParams.capacity_min)
    ModelParams.Atilde[1:J, 1:J] = -LinearAlgebra.I(J)

    ModelParams.Dtilde[J+1:2*J, I*J+1:I*J+J] = -LinearAlgebra.Diagonal(RFLParams.capacity_max)
    ModelParams.Atilde[J+1:2*J, 1:J] = LinearAlgebra.I(J)

    # capacity limit on demand
    ModelParams.Atilde[2*J+1:3*J, 1:J] = -LinearAlgebra.I(J)
    ModelParams.Dtilde[2*J+1:3*J, 1:I*J] = [mod(k, J) == j-1 ? 1 : 0 for j in 1:J, k in 1:I*J] # ∑_i y_{ij}

    # satisfy nominal demand
    ModelParams.Dtilde[3*J+1:3*J+I, 1:I*J] = [((i - 1) * J < k && k <= i * J) ? -1 : 0 for i in 1:I, k in 1:I*J] # -∑_j y_{ij}
    ModelParams.btilde[3*J+1:3*J+I] = -RFLParams.demand_nominal

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
    for i in 1:I, j in RFLParams.J_i[i]
        ModelParams.U[i, j] = -RFLParams.demand_min_deviation[i, j]
    end

    # ξ_i <= \sum_j ()
    ModelParams.W[I+1:2*I, 1:I] = LinearAlgebra.I(I)
    for i in 1:I, j in RFLParams.J_i[i]
        ModelParams.U[I+i, j] = RFLParams.demand_max_deviation[i, j]
    end

    # \sum_i \xi_i >= 
    ModelParams.W[2*I+1, 1:I] .= -1.0
    ModelParams.U[2*I+1, 1:J] .= -RFLParams.α

    return RFLParams, ModelParams
end
