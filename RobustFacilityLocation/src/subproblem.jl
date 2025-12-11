# subproblems in CCG algorithm
function subproblems(params::GeneralModelParameters, MPSol::MPSolutionInfo, constraint_tol::Float64=1e-5)
    basis_constraints = nothing
    basis_variables = nothing
    objective = 0.0

    # define subproblems
    # subproblems have the same feasible region for a given master problem solution
    # therefore, only the objective function needs to be changed across all subproblems in an iteration
    subproblem = Model(Gurobi.Optimizer)
    set_optimizer_attribute(subproblem, MOI.Silent(), true)

    @variable(subproblem, ξ[1:params.num_ξ])
    @constraint(subproblem, uncertainty_set, params.W * ξ .<= params.v + params.U * MPSol.x_sol)

    # check if uncertainty set is bounded and compact
    optimize!(subproblem)
    status = termination_status(subproblem)

    if status == MOI.OPTIMAL
        for n in 1:params.num_ξcons
            @objective(subproblem, Max, params.a[n, :]'MPSol.x_sol + params.d[n, :]'MPSol.y_sol - params.b[n] + (params.Abar[n, :, :] * MPSol.x_sol + params.Dbar[n, :, :] * MPSol.y_sol - params.bbar[n, :])'ξ)

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
                for j in 1:params.num_ξ
                    if Int(MOI.get(subproblem, MOI.VariableBasisStatus(), ξ[j])) == 0
                        push!(basis_variables, j)
                    end
                end
                # update worst constraint violation
                objective = objective_constraint_n
            end
        end
        # TODO: add error messages for infeasible or unbounded uncertainty set scenarios
    end
    return SPSolutionInfo(status, objective, basis_constraints, basis_variables)
end