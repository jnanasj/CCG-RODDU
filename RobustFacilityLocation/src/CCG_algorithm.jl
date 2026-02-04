# Column and constraint generation algorithm for robust optimization under decision dependent uncertainty
function CCG(params::GeneralModelParameters, iter_max::Int64, multi_cut::Bool, timelimit::Float64, mp_timelimit::Float64, mp_gap::Float64, big_M::Float64, sp_tol::Float64)
    CCGSol = CCGSolutionInfo() # initialization with no vertices
    for iter in 1:iter_max
        # solve master problem
        MPSol = master_problem(params, CCGSol, iter, mp_timelimit, mp_gap, big_M)

        #TODO: check if master problem reached time limit

        # find worst constraint violation in master problem's solution
        sp_solvetime = @elapsed SPSol = subproblems(multi_cut, params, MPSol, iter, sp_tol)

        # update solution info
        push!(CCGSol.objective, MPSol.objective)
        push!(CCGSol.solvetime, MPSol.solvetime + sp_solvetime)
        push!(CCGSol.worst_constraint_violation, SPSol.objective)
        push!(CCGSol.gap, MPSol.gap)
        CCGSol.x_sol = MPSol.x_sol 
        CCGSol.y_sol = MPSol.y_sol # used as initial guess for next iteration

        # check termination criteria
        if SPSol.objective <= sp_tol
            CCGSol.status = "OPTIMAL"
            CCGSol.num_iters = iter
            CCGSol.num_variables = MPSol.num_variables
            CCGSol.num_constraints = MPSol.num_constraints
            CCGSol.num_quad_constraints = MPSol.num_quad_constraints
            break
        elseif iter == iter_max
            CCGSol.status = "MAX ITERS REACHED"
            CCGSol.num_iters = iter
            CCGSol.num_variables = MPSol.num_variables
            CCGSol.num_constraints = MPSol.num_constraints
            CCGSol.num_quad_constraints = MPSol.num_quad_constraints
            CCGSol.bases_constraints[iter] = SPSol.basis_constraints
            CCGSol.bases_variables[iter] = SPSol.basis_variables
        elseif sum(CCGSol.solvetime) >= timelimit
            CCGSol.status = "TIME LIMIT REACHED"
            CCGSol.num_iters = iter
            CCGSol.num_variables = MPSol.num_variables
            CCGSol.num_constraints = MPSol.num_constraints
            CCGSol.num_quad_constraints = MPSol.num_quad_constraints
            break
        else
            CCGSol.bases_constraints = merge(CCGSol.bases_constraints, SPSol.basis_constraints)
            CCGSol.bases_variables = merge(CCGSol.bases_variables, SPSol.basis_variables)
        end
    end
    return CCGSol
end