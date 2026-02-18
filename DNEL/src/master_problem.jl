# master problem in CCG algorithm
function master_problem(params::GeneralModelParameters, sol::CCGSolutionInfo, iter::Int64, timelimit, gap, big_M)
    masterproblem = Model(Gurobi.Optimizer)
    set_optimizer_attribute(masterproblem, "MIPGap", gap)
    set_optimizer_attribute(masterproblem, "TimeLimit", timelimit)
    # set_optimizer_attribute(masterproblem, MOI.Silent(), true)

    @variables(masterproblem, begin
        x[1:params.num_x] >= 0
        y[1:params.num_y] >= 0
        ξ[1:params.num_ξ] >= 0
    end)
    set_lower_bound.(x, params.lower_x)
    set_upper_bound.(x, params.upper_x)
    set_upper_bound.(y, params.upper_y)
    set_lower_bound.(ξ, params.lower_ξ)
    set_upper_bound.(ξ, params.upper_ξ)

    # uncertain parameters from active constraints
    ξbases = Dict(i => @variable(masterproblem, [j=1:params.num_ξ], lower_bound = 0.0, upper_bound=params.upper_ξ[j]) for i in eachindex(sol.bases_constraints))

    @constraints(masterproblem, begin
        # constraints with uncertainty
        [n in 1:params.num_ξcons], params.a[n, :]'x + ξ'params.Abar[n, :, :] * x + params.d[n, :]'y + ξ'params.Dbar[n, :, :] * y <= params.b[n] + ξ'params.bbar[n, :]
        params.W*ξ <= params.v + params.U*x

        [k in eachindex(sol.bases_constraints), n in 1:params.num_ξcons], params.a[n, :]'x + ξbases[k]'params.Abar[n, :, :] * x + params.d[n, :]'y + ξbases[k]'params.Dbar[n, :, :] * y <= params.b[n] + ξbases[k]'params.bbar[n, :]
        # active constraints
        [k in eachindex(sol.bases_constraints)], params.W[sol.bases_constraints[k], sol.bases_variables[k]] * ξbases[k][sol.bases_variables[k]] .== params.v[sol.bases_constraints[k]] + params.U[sol.bases_constraints[k], :] * x
        [k in eachindex(sol.bases_constraints)], params.W * ξbases[k] <= params.v + params.U * x
    end)

    @objective(masterproblem, Min, params.cost_x'x + params.cost_y'y)

    if iter > 1
        set_start_value.(y, sol.y_sol)
    end

    optimize!(masterproblem)

    status = termination_status(masterproblem)
    if status == MOI.OPTIMAL || status == MOI.TIME_LIMIT
        objective = objective_value(masterproblem)
        bound = objective_bound(masterproblem)
        gap = 100 * abs(objective - bound) / (1e-10 + abs(objective))
        x_sol = value.(x)
        y_sol = value.(y)

        # TODO: add error messages for infeasible or unbounded master problem; in case of unbounded, one resolution could be to add a vertex in the first iteration
    else
        compute_conflict!(masterproblem)
        iis_model, _ = copy_conflict(masterproblem)
        write_to_file(iis_model, "iis.lp")
    end
    solvetime = solve_time(masterproblem)
    num_variables_bin = JuMP.num_constraints(masterproblem, VariableRef, MOI.ZeroOne)
    num_variables_cont = JuMP.num_variables(masterproblem)-num_variables_bin
    num_constraints = JuMP.num_constraints(masterproblem; count_variable_in_set_constraints=false)
    num_quad_constraints = JuMP.num_constraints(masterproblem, JuMP.QuadExpr, MOI.LessThan{Float64})

    return MPSolutionInfo(status, objective, bound, gap, solvetime, x_sol, y_sol, num_variables_cont, num_variables_bin, num_constraints, num_quad_constraints)
end