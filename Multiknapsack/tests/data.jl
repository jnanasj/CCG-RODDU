# generates a random instance of the mulitknapsack problem and returns the general model form
function data_generator(M::Int64, N::Int64, T::Int64, α::Float64, seed)
    rng = Xoshiro(seed)

    # Generate random instance of the multiknapsack problem
    MKParams = MultiknapsackParameters(M=M, N=N, T=T, α=α)
    MKParams.weight_factor = rand(rng, M, N)
    MKParams.weight_limit = α*vec(sum(MKParams.weight_factor, dims=2))
    MKParams.price = vec(5*rand(rng, N) + sum(MKParams.weight_factor, dims=1)'/2)

    # Convert multiknapsack problem to general model
    if T == 0 # fixed recourse
        ModelParams = GeneralModelParameters(num_x = N, num_ξ = M, num_ξcons = M, num_ξset = 2*M+1)

        # constraints
        ModelParams.a = MKParams.weight_factor
        ModelParams.b = MKParams.weight_limit
        ModelParams.bbar = LinearAlgebra.Diagonal(MKParams.weight_limit)

        # objective function: minimize
        ModelParams.cost_x = -MKParams.price

        # uncertainty set
        # ξ_m >= 0
        ModelParams.W[1:M, :] = -LinearAlgebra.I(M) 
        # ξ_m <= 1/M ∑_n x_n
        ModelParams.W[M+1:2*M, :] = LinearAlgebra.I(M)
        ModelParams.U[M+1:2*M, :] .= 1/M
        # ∑_m ξ_m <= (M/αN) ∑_n x_n
        ModelParams.W[2*M+1, :] .= 1
        ModelParams.U[2*M+1, :] .= M/(α*N)

    else # random recourse
        ModelParams = GeneralModelParameters(num_x = N, num_ξ = M*N, num_ξcons = M, num_ξset = 2*M*N+N)

        # constraints
        ModelParams.a = MKParams.weight_factor
        ModelParams.b = MKParams.weight_limit
        for (m, n) in ((m, n) for m in 1:M, n in 1:N if abs(m-n) <= T)
            ModelParams.Abar[m, (m-1)*N+m, n] = MKParams.weight_factor[m, n]
        end

        # objective function: minimize
        ModelParams.cost_x = -MKParams.price
        
        # uncertainty set
        # ξ_mn >= 0
        ModelParams.W[1:M*N, :] = -LinearAlgebra.I(ModelParams.num_ξ)
        # ξ_mn <= 2*x_n if |m-n| <= T
        ModelParams.W[M*N+1:2*M*N, :] = LinearAlgebra.I(ModelParams.num_ξ)
        for (m, n) in ((m, n) for m in 1:M, n in 1:N if abs(m-n) <= T)
            ModelParams.U[M*N + (m-1)*N+m, n] = 2
        end
        # ∑_m ξ_mn <= (M/5)x_n
        ModelParams.U[2*M*N+1:2*M*N+N, :] .= (M/5)*LinearAlgebra.I(N)
        for m in 1:M, n in 1:N
            ModelParams.W[2*M*N+n, (m-1)*N+n] = 1
        end
    end
    return ModelParams
end