function reformulation(params::ShortestPathParams, timelimit, gap)
    reformulation = Model(Gurobi.Optimizer)
    set_optimizer_attribute(reformulation, "TimeLimit", timelimit)
    set_optimizer_attribute(reformulation, "MIPGap", gap)
    # set_optimizer_attribute(reformulation, MOI.Silent(), true)

    # model variables
    @variables(reformulation, begin
        0 <= x[1:params.num_edges] <= 1 # specific to shortest path problem
        y[1:params.num_edges+1]
        δ[1:params.num_ξset] >= 0 # dual variables
    end)
    set_binary.(y[1:params.num_edges])

    @constraints(
        reformulation,
        begin
            # constraints without uncertainty
            [n in 1:params.num_nodes; (n!=params.source && n!=params.sink)], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 0
            [n in [params.source]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == -1
            [n in [params.sink]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 1

            #constraints with uncertainty
            y[end] >= sum(params.cost*x[e] + params.distances[e][2]*y[e] for e in 1:params.num_edges) + (params.v+params.U*x)'δ
            [e in 1:params.num_edges], params.W[:, e]'δ .>= params.distances[e][2]*y[e]
        end
    )

    @objective(reformulation, Min, y[end])
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