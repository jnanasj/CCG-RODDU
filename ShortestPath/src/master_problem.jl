# master problem in CCG algorithm
function master_problem(params::ShortestPathParams, sol::CCGSolutionInfo, iter::Int64, timelimit, gap, big_M)
    masterproblem = Model(Gurobi.Optimizer)
    set_optimizer_attribute(masterproblem, "MIPGap", gap)
    set_optimizer_attribute(masterproblem, "TimeLimit", timelimit)
    # set_optimizer_attribute(masterproblem, MOI.Silent(), true)

    @variables(masterproblem, begin
        0 <= x[1:params.num_edges] <= 1 # specific to shortest path problem
        y[1:params.num_edges+1]
        0 <= ξ[1:params.num_edges] <= 1
    end)
    set_binary.(y[1:params.num_edges])

    # linearization terms for ξ_e y_e
    @variable(masterproblem, Ylin[1:params.num_edges], lower_bound = 0.0, upper_bound = 1.0)
    Ylin_proj = Dict(i => @variable(masterproblem, [1:params.num_edges], lower_bound = 0.0, upper_bound = 1.0) for i in eachindex(sol.bases_constraints))

    # uncertain parameters from active constraints
    ξbases = Dict(i => @variable(masterproblem, [1:params.num_edges]) for i in eachindex(sol.bases_constraints))

    # uncertain parameter projections onto uncertainty set
    ξbases_proj = Dict(i => @variable(masterproblem, [1:params.num_edges], lower_bound = 0.0, upper_bound = 1.0) for i in eachindex(sol.bases_constraints))

    # projection distances
    tbases = Dict(i => @variable(masterproblem, [1:params.num_edges], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))

    # dual variables from projection problem
    λplus = Dict(i => @variable(masterproblem, [1:params.num_edges], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))
    λnegative = Dict(i => @variable(masterproblem, [1:params.num_edges], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))
    μ = Dict(i => @variable(masterproblem, [1:params.num_ξset], lower_bound = 0.0) for i in eachindex(sol.bases_constraints))

    # binary variables for big-M reformulation of complementarity conditions in projection problem
    zλplus = Dict(i => @variable(masterproblem, [1:params.num_edges], Bin) for i in eachindex(sol.bases_constraints))
    zλnegative = Dict(i => @variable(masterproblem, [1:params.num_edges], Bin) for i in eachindex(sol.bases_constraints))
    zμ = Dict(i => @variable(masterproblem, [1:params.num_ξset], Bin) for i in eachindex(sol.bases_constraints))

    # constraints without uncertainty
    @constraints(masterproblem, begin
        [n in 1:params.num_nodes; (n!=params.source && n!=params.sink)], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 0
        [n in [params.source]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == -1
        [n in [params.sink]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 1
    end)
    # constraints with linearized y_e ξ_e
    @constraints(masterproblem, begin
        y[end] >= sum(params.cost*x[e]+params.distances[e][2]*(y[e]+Ylin[e]) for e in 1:params.num_edges)
        Ylin <= ξ
        Ylin >= ξ - (1 .- y[1:params.num_edges])
        Ylin <= y[1:params.num_edges]
    end)

    @constraints(masterproblem, begin
        # constraints with uncertainty
        # constraints with linearized y_e ξ_e
        [k in eachindex(sol.bases_constraints)], y[end] >= sum(0.01*x[e]+params.distances[e][2]*(y[e]+Ylin_proj[k][e]) for e in 1:params.num_edges)
        [k in eachindex(sol.bases_constraints)], Ylin_proj[k] <= ξbases_proj[k]
        [k in eachindex(sol.bases_constraints)], Ylin_proj[k] >= ξbases_proj[k] - (1 .- y[1:params.num_edges])
        [k in eachindex(sol.bases_constraints)], Ylin_proj[k] <= y[1:params.num_edges]

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
        [k in eachindex(sol.bases_constraints), j in 1:params.num_edges], λplus[k][j] <= big_M * zλplus[k][j]
        [k in eachindex(sol.bases_constraints), j in 1:params.num_edges], (-tbases[k][j] + ξbases_proj[k][j] - ξbases[k][j]) >= -big_M * (1 - zλplus[k][j])

        [k in eachindex(sol.bases_constraints), j in 1:params.num_edges], λnegative[k][j] <= big_M * zλnegative[k][j]
        [k in eachindex(sol.bases_constraints), j in 1:params.num_edges], (-tbases[k][j] - ξbases_proj[k][j] + ξbases[k][j]) >= -big_M * (1 - zλnegative[k][j])

        [k in eachindex(sol.bases_constraints), i in 1:params.num_ξset], μ[k][i] <= big_M * zμ[k][i]
        [k in eachindex(sol.bases_constraints), i in 1:params.num_ξset], (params.W[i, :]'ξbases_proj[k] - params.v[i] - params.U[i, :]'x) >= -big_M * (1 - zμ[k][i])
    end)

    @objective(masterproblem, Min, y[end])

    if iter > 1
        set_start_value.(x, sol.x_sol)
    end

    optimize!(masterproblem)

    status = termination_status(masterproblem)
    if status == MOI.OPTIMAL || status == MOI.TIME_LIMIT
        objective = objective_value(masterproblem)
        bound = objective_bound(masterproblem)
        gap = 100 * abs(objective - bound) / (1e-10 + abs(objective))
        x_sol = value.(x)
        y_sol = value.(y)

    else
        compute_conflict!(masterproblem)
        iis_model, _ = copy_conflict(masterproblem)
        write_to_file(iis_model, "iis.lp")

        # TODO: add error messages for infeasible or unbounded master problem; in case of unbounded, one resolution could be to add a vertex in the first iteration
    end
    solvetime = solve_time(masterproblem)
    num_variables = JuMP.num_variables(masterproblem)
    num_constraints = JuMP.num_constraints(masterproblem; count_variable_in_set_constraints=false)
    num_quad_constraints = JuMP.num_constraints(masterproblem, JuMP.QuadExpr, MOI.LessThan{Float64})

    return MPSolutionInfo(status, objective, bound, gap, solvetime, x_sol, y_sol, num_variables, num_constraints, num_quad_constraints)
end