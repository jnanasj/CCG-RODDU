# Write results from reformulation and CCG to XLSX files

function results(ReformSol::ReformulationSolutionInfo, solvetime_reform, CCGSol::CCGSolutionInfo, solvetime_ccg, CCGSol_proj::CCGSolutionInfo, solvetime_ccg_proj, instance_number, MULTI_CUT)
    if MULTI_CUT
        filename = string("results_multicut.xlsx")
    else
        filename = string("results_singlecut.xlsx")
    end

    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet: reformulation
        sheet["C$(3*instance_number-1)"] = solvetime_reform
        sheet["D$(3*instance_number-1)"] = string("-")
        sheet["E$(3*instance_number-1)"] = ReformSol.num_variables_bin
        sheet["F$(3*instance_number-1)"] = ReformSol.num_variables_cont
        sheet["G$(3*instance_number-1)"] = string(ReformSol.num_constraints, "(", ReformSol.num_quad_constraints, ")")
        sheet["H$(3*instance_number-1)"] = string(ReformSol.status)

        # summary sheet: PCP with projection
        sheet["C$(3*instance_number)"] = solvetime_ccg_proj
        sheet["D$(3*instance_number)"] = string(CCGSol_proj.num_iters, "(", length(CCGSol_proj.bases_constraints), ")")
        sheet["E$(3*instance_number)"] = CCGSol_proj.num_variables_bin
        sheet["F$(3*instance_number)"] = CCGSol_proj.num_variables_cont
        sheet["G$(3*instance_number)"] = string(CCGSol_proj.num_constraints, "(", CCGSol_proj.num_quad_constraints, ")")
        sheet["H$(3*instance_number)"] = string(CCGSol_proj.status)

        # summary sheet: PCP without projection
        sheet["C$(3*instance_number+1)"] = solvetime_ccg
        sheet["D$(3*instance_number+1)"] = string(CCGSol.num_iters, "(", length(CCGSol.bases_constraints), ")")
        sheet["E$(3*instance_number+1)"] = CCGSol.num_variables_bin
        sheet["F$(3*instance_number+1)"] = CCGSol.num_variables_cont
        sheet["G$(3*instance_number+1)"] = string(CCGSol.num_constraints, "(", CCGSol.num_quad_constraints, ")")
        sheet["H$(3*instance_number+1)"] = string(CCGSol.status)


        # instance details
        sheet = xf[instance_number+1]

        # reformulation
        sheet["C1"] = vec(ReformSol.x_sol')
        sheet["C2"] = vec(ReformSol.y_sol')
        sheet["C3"] = ReformSol.objective
        sheet["C4"] = ReformSol.gap

        # PCP with projection
        sheet["C6"] = vec(CCGSol_proj.x_sol')
        sheet["C7"] = vec(CCGSol_proj.y_sol')
        sheet["C8"] = vec(CCGSol_proj.objective')
        sheet["C9"] = vec(CCGSol_proj.gap')
        sheet["C10"] = vec(CCGSol_proj.solvetime')
        sheet["C11"] = vec(CCGSol_proj.worst_constraint_violation')

        # PCP without projection
        sheet["C13"] = vec(CCGSol.x_sol')
        sheet["C14"] = vec(CCGSol.y_sol')
        sheet["C15"] = vec(CCGSol.objective')
        sheet["C16"] = vec(CCGSol.gap')
        sheet["C17"] = vec(CCGSol.solvetime')
        sheet["C18"] = vec(CCGSol.worst_constraint_violation')
    end
end

function ccg_spreadsheet(CCGSol::CCGSolutionInfo, solvetime_ccg, N, MULTI_CUT)
    filename = string("M", M, "_N", N, "_T", T, "_a", Int(100*α), "_ccg.xlsx")
    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet
        sheet["A$(1+instance_number)"] = instance_number
        sheet["B$(1+instance_number)"] = CCGSol.objective[end]
        # sheet["C$(1+instance_number)"] = sum(CCGSol.solvetime)
        sheet["C$(1+instance_number)"] = solvetime_ccg
        sheet["D$(1+instance_number)"] = CCGSol.num_iters
        sheet["E$(1+instance_number)"] = CCGSol.status
        sheet["F$(1+instance_number)"] = length(CCGSol.bases_constraints)
        sheet["G$(1+instance_number)"] = CCGSol.num_variables
        sheet["H$(1+instance_number)"] = CCGSol.num_constraints
        sheet["I$(1+instance_number)"] = CCGSol.num_quad_constraints

        sheet = xf[instance_number+1]
        # instance results
        for i in 1:CCGSol.num_iters
            sheet["A$(1+i)"] = i
            sheet["B$(i+1)"] = CCGSol.objective[i]
            sheet["C$(i+1)"] = CCGSol.gap[i]
            sheet["D$(i+1)"] = CCGSol.solvetime[i]
            sheet["E$(i+1)"] = CCGSol.worst_constraint_violation[i]
        end
    end
end