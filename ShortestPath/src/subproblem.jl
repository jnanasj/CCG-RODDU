# subproblems in CCG algorithm
function subproblems(multi_cut::Bool, params::ShortestPathParams, MPSol::MPSolutionInfo, iter::Int64, constraint_tol::Float64=1e-5)
    bases_constraints = Dict()
    bases_variables = Dict()
    objective = 0.0
    worst_objective = 0.0

    # define subproblems
    # subproblems have the same feasible region for a given master problem solution
    # therefore, only the objective function needs to be changed across all subproblems in an iteration
    subproblem = Model(Gurobi.Optimizer)
    set_optimizer_attribute(subproblem, MOI.Silent(), true)

    @variable(subproblem, ξ[1:params.num_edges])
    @constraint(subproblem, uncertainty_set, params.W * ξ .<= params.v + params.U * MPSol.x_sol)

    # check if uncertainty set is bounded and compact
    optimize!(subproblem)
    status = termination_status(subproblem)

    if status == MOI.OPTIMAL
        cut_id = 1
        for n in 1:1
            @objective(subproblem, Max, -MPSol.y_sol[end] + sum(params.cost*MPSol.x_sol[e]+params.distances[e][2]*MPSol.y_sol[e]*(1+ξ[e]) for e in 1:params.num_edges))

            optimize!(subproblem)

            objective_constraint_n = round(objective_value(subproblem), digits = 5)
            if (objective_constraint_n - objective) > constraint_tol # finds worst constraint violation
                basis_constraints = []
                basis_variables = []
                # find constraints in basis
                for i in 1:params.num_ξset
                    if Int(MOI.get(subproblem, MOI.ConstraintBasisStatus(), uncertainty_set[i])) != 0
                        push!(basis_constraints, i)
                    end
                end
                # find nonbasic variables
                for j in 1:params.num_edges
                    if Int(MOI.get(subproblem, MOI.VariableBasisStatus(), ξ[j])) == 0
                        push!(basis_variables, j)
                    end
                end
                # update worst constraint violation
                if cut_id > 1 && bases_constraints[[iter, cut_id-1]] != basis_constraints
                    bases_constraints[[iter, cut_id]] = basis_constraints
                    bases_variables[[iter, cut_id]] = basis_variables
                    if multi_cut
                        cut_id += 1
                        (objective_constraint_n - worst_objective) > constraint_tol ? worst_objective = objective_constraint_n : worst_objective = worst_objective
                    else
                        objective = objective_constraint_n
                        worst_objective = objective_constraint_n
                    end
                elseif cut_id == 1
                    bases_constraints[[iter, cut_id]] = basis_constraints
                    bases_variables[[iter, cut_id]] = basis_variables
                    if multi_cut
                        cut_id += 1
                        (objective_constraint_n - worst_objective) > constraint_tol ? worst_objective = objective_constraint_n : worst_objective = worst_objective
                    else
                        objective = objective_constraint_n
                        worst_objective = objective_constraint_n
                    end
                end
            end
        end
        # TODO: add error messages for infeasible or unbounded uncertainty set scenarios
    end
    return SPSolutionInfo(status, worst_objective, bases_constraints, bases_variables)
end