# master problem in CCG algorithm
function master_problem(params::GeneralModelParameters, sol::CCGSolutionInfo, iter::Int64, timelimit, gap, big_M)
    masterproblem = Model(Gurobi.Optimizer)
    set_optimizer_attribute(masterproblem, "MIPGap", gap)
    set_optimizer_attribute(masterproblem, "TimeLimit", timelimit)
    # set_optimizer_attribute(masterproblem, MOI.Silent(), true)

    @variables(masterproblem, begin
        x[1:params.num_x] >= 0
        y[1:params.num_y]
    end)
    # specific to robust facility location
    set_binary.(x[1:params.num_x_bin])
    set_lower_bound.(y[1:(params.num_y-1)], 0.0)

    # uncertain parameters from active constraints
    ξbases = Dict(i => @variable(masterproblem, [1:params.num_ξ]) for i in eachindex(sol.bases_constraints))

    # uncertain parameter projections onto uncertainty set
    ξbases_proj = Dict(i => @variable(masterproblem, [1:params.num_ξ], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))

    # projection distances
    tbases = Dict(i => @variable(masterproblem, [1:params.num_ξ], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))

    # dual variables from projection problem
    λplus = Dict(i => @variable(masterproblem, [1:params.num_ξ], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))
    λnegative = Dict(i => @variable(masterproblem, [1:params.num_ξ], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))
    μ = Dict(i => @variable(masterproblem, [1:params.num_ξset], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))

    # binary variables for big-M reformulation of complementarity conditions in projection problem
    zλplus = Dict(i => @variable(masterproblem, [1:params.num_ξ], Bin) for i in eachindex(sol.bases_constraints))
    zλnegative = Dict(i => @variable(masterproblem, [1:params.num_ξ], Bin) for i in eachindex(sol.bases_constraints))
    zμ = Dict(i => @variable(masterproblem, [1:params.num_ξset], Bin) for i in eachindex(sol.bases_constraints))

    # constraints without uncertainty
    @constraint(masterproblem, params.Atilde * x + params.Dtilde * y .<= params.btilde)

    # constraints with uncertainty
    if params.Abar == zeros(params.num_ξcons, params.num_ξ, params.num_x) && params.Dbar == zeros(params.num_ξcons, params.num_ξ, params.num_y)
        @constraint(masterproblem, [k in eachindex(sol.bases_constraints), n in 1:params.num_ξcons], params.a[n, :]'x + params.d[n, :]'y <= params.b[n] + ξbases_proj[k]'params.bbar[n, :])
    else
        @constraint(masterproblem, [k in eachindex(sol.bases_constraints), n in 1:params.num_ξcons], params.a[n, :]'x + ξbases_proj[k]'params.Abar[n, :, :] * x + params.d[n, :]'y + ξbases_proj[k]'params.Dbar[n, :, :] * y <= params.b[n] + ξbases_proj[k]'params.bbar[n, :])
    end

    @constraints(masterproblem, begin
        # active constraints
        [k in eachindex(sol.bases_constraints)], params.W[sol.bases_constraints[k], sol.bases_variables[k]] * ξbases[k][sol.bases_variables[k]] .== params.v[sol.bases_constraints[k]] + params.U[sol.bases_constraints[k], :] * x

        # primal feasibility constraints from projection problem
        [k in eachindex(sol.bases_constraints)], -tbases[k] + ξbases_proj[k] <= ξbases[k]
        [k in eachindex(sol.bases_constraints)], -tbases[k] - ξbases_proj[k] <= -ξbases[k]
        [k in eachindex(sol.bases_constraints)], params.W * ξbases_proj[k] <= params.v + params.U * x

        # stationarity constraints from projection problem
        [k in eachindex(sol.bases_constraints)], -λplus[k] - λnegative[k] .+ 1.0 .== 0
        [k in eachindex(sol.bases_constraints)], λplus[k] - λnegative[k] + params.W'μ[k] .== 0

        # complementarity conditions from projection problem
        [k in eachindex(sol.bases_constraints), j in 1:params.num_ξ], λplus[k][j] <= big_M * zλplus[k][j]
        [k in eachindex(sol.bases_constraints), j in 1:params.num_ξ], (-tbases[k][j] + ξbases_proj[k][j] - ξbases[k][j]) >= -big_M * (1 - zλplus[k][j])

        [k in eachindex(sol.bases_constraints), j in 1:params.num_ξ], λnegative[k][j] <= big_M * zλnegative[k][j]
        [k in eachindex(sol.bases_constraints), j in 1:params.num_ξ], (-tbases[k][j] - ξbases_proj[k][j] + ξbases[k][j]) >= -big_M * (1 - zλnegative[k][j])

        [k in eachindex(sol.bases_constraints), i in 1:params.num_ξset], μ[k][i] <= big_M * zμ[k][i]
        [k in eachindex(sol.bases_constraints), i in 1:params.num_ξset], (params.W[i, :]'ξbases_proj[k] - params.v[i] - params.U[i, :]'x) >= -big_M * (1 - zμ[k][i])
    end)

    @objective(masterproblem, Min, params.cost_x'x + params.cost_y'y)

    if iter > 1
        set_start_value.(x, sol.x_sol)
    end

    optimize!(masterproblem)

    write_to_file(masterproblem, "mp.lp")

    status = termination_status(masterproblem)
    if status == MOI.OPTIMAL || status == MOI.TIME_LIMIT
        objective = objective_value(masterproblem)
        bound = objective_bound(masterproblem)
        gap = 100 * abs(objective - bound) / (1e-10 + abs(objective))
        x_sol = value.(x)
        y_sol = value.(y)

        # TODO: add error messages for infeasible or unbounded master problem; in case of unbounded, one resolution could be to add a vertex in the first iteration
    end
    solvetime = solve_time(masterproblem)
    num_variables = JuMP.num_variables(masterproblem)
    num_constraints = JuMP.num_constraints(masterproblem; count_variable_in_set_constraints=false)
    num_quad_constraints = JuMP.num_constraints(masterproblem, JuMP.QuadExpr, MOI.LessThan{Float64})

    return MPSolutionInfo(status, objective, bound, gap, solvetime, x_sol, y_sol, num_variables, num_constraints, num_quad_constraints)
end