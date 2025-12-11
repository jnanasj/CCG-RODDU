function reformulation(params::GeneralModelParameters, timelimit, gap)
    reformulation = Model(Gurobi.Optimizer)
    set_optimizer_attribute(reformulation, "TimeLimit", timelimit)
    set_optimizer_attribute(reformulation, "MIPGap", gap)
    # set_optimizer_attribute(reformulation, MOI.Silent(), true)

    # model variables
    @variables(reformulation, begin
        x[1:params.num_x] >= 0
        y[1:params.num_y]
    end)
    # specific to robust facility location
    set_binary.(x[1:params.num_x_bin])
    set_lower_bound.(y[1:(params.num_y-1)], 0.0)

    # dual variables
    δ = Dict(n => @variable(reformulation, [1:params.num_ξset], lower_bound = 0.0) for n = 1:params.num_ξcons)

    @constraints(
        reformulation,
        begin
            # constraints without uncertainty
            params.Atilde * x + params.Dtilde * y .<= params.btilde

            #constraints with uncertainty
            [n in 1:params.num_ξcons], params.W'δ[n] .>= (params.Abar[n, :, :] * x + params.Dbar[n, :, :] * y - params.bbar[n, :])

            # Constraints with bilinear terms
            [n in 1:params.num_ξcons], (params.v + params.U * x)'δ[n] <= params.b[n] - params.a[n, :]'x - params.d[n, :]'y
        end
    )

    @objective(reformulation, Min, params.cost_x'x + params.cost_y'y)
    optimize!(reformulation)

    # SOLUTION INFO
    reformulation_solution = ReformulationSolutionInfo()
    reformulation_solution.status = termination_status(reformulation)
    reformulation_solution.solvetime = solve_time(reformulation)
    reformulation_solution.num_variables = num_variables(reformulation)
    reformulation_solution.num_constraints = num_constraints(reformulation; count_variable_in_set_constraints=false)
    reformulation_solution.num_quad_constraints = num_constraints(reformulation, JuMP.QuadExpr, MOI.LessThan{Float64})

    if reformulation_solution.status == MOI.OPTIMAL || reformulation_solution.status == MOI.TIME_LIMIT
        reformulation_solution.objective = objective_value(reformulation)
        reformulation_solution.bound = objective_bound(reformulation)
        reformulation_solution.gap = 100 * abs(reformulation_solution.objective - reformulation_solution.bound) / ((1e-10) + abs(reformulation_solution.objective))
        reformulation_solution.x_sol = value.(x)
        reformulation_solution.y_sol = value.(y)
    end
    return reformulation_solution
end