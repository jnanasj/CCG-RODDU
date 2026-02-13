# writing problem-specific reformulation code

function reformulation(params::NetworkInvestmentParams, timelimit, gap, big_M)
    reformulation = Model(Gurobi.Optimizer)
    set_optimizer_attribute(reformulation, "TimeLimit", timelimit)
    set_optimizer_attribute(reformulation, "MIPGap", gap)
    # set_optimizer_attribute(reformulation, "DualReductions", 0)

    # model variables
    @variables(reformulation, begin
        x[1:params.num_edges], Bin
        0 <= y[1:params.num_edges] <= 1
        δ[1:params.num_edges, 1:params.num_edges] >= 0
        μ[1:params.num_edges] >= 0
        δx[1:params.num_edges, 1:params.num_edges] >= 0
        μx[1:params.num_edges, 1:params.num_edges] >= 0
    end)

    @constraints(
        reformulation,
        begin
            # constraints without uncertainty
            params.repair_cost'x <= params.budget

            [n in 1:params.num_nodes; (n!=params.source && n!=params.sink)], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 0
            [n in [params.source]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == -1
            [n in [params.sink]], sum(y[e] for e in 1:params.num_edges if dst(params.distances[e][1])==n) - sum(y[e] for e in 1:params.num_edges if src(params.distances[e][1])==n) == 1

            # constraints with uncertainty
            [e in 1:params.num_edges], y[e] + sum((δ[e, ee] - δx[e, ee]) for ee in 1:params.num_edges) + params.ψ*sum((μ[e] - μx[e, ee]) for ee in 1:params.num_edges) <= 1

            [e in 1:params.num_edges, ee in 1:params.num_edges], δx[e, ee] <= δ[e, ee]
            [e in 1:params.num_edges, ee in 1:params.num_edges], δx[e, ee] >= δ[e, ee] - big_M*(1-x[ee])
            [e in 1:params.num_edges, ee in 1:params.num_edges], δx[e, ee] <= big_M*x[ee]

            [e in 1:params.num_edges, ee in 1:params.num_edges], μx[e, ee] <= μ[e]
            [e in 1:params.num_edges, ee in 1:params.num_edges], μx[e, ee] >= μ[e] - big_M*(1-x[ee])
            [e in 1:params.num_edges, ee in 1:params.num_edges], μx[e, ee] <= big_M*x[ee]

            [e in 1:params.num_edges, ee in 1:params.num_edges], δ[e, ee] + μ[e] >= 0
            [e in 1:params.num_edges], δ[e, e] + μ[e] >= 1
        end
    )

    @objective(reformulation, Min, params.repair_cost'x + params.transport_cost'y)
    optimize!(reformulation)

    status = termination_status(reformulation)
    if status == MOI.OPTIMAL || status == MOI.TIME_LIMIT
        objective = objective_value(reformulation)
        bound = objective_bound(reformulation)
        gap = 100 * abs(objective - bound) / (1e-10 + abs(objective))
        x_sol = value.(x)
        y_sol = value.(y)

        # TODO: add error messages for infeasible or unbounded master problem; in case of unbounded, one resolution could be to add a vertex in the first iteration
    # else
    #     compute_conflict!(reformulation)
    #     iis_model, _ = copy_conflict(reformulation)
    #     write_to_file(iis_model, "iis_r.lp")
    end

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