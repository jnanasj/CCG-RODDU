# Write results from reformulation and CCG to XLSX files

function results(ReformSol::ReformulationSolutionInfo, solvetime_reform, CCGSol::CCGSolutionInfo, solvetime_ccg, instance_number)
    filename = string("results/results_low_beta.xlsx")

    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet: reformulation
        sheet["G$(instance_number+2)"] = solvetime_reform
        sheet["E$(instance_number+2)"] = ReformSol.objective
        sheet["K$(instance_number+2)"] = string(ReformSol.status)

        # summary sheet: PCP with projection
        sheet["H$(3*instance_number)"] = solvetime_ccg
        sheet["F$(3*instance_number)"] = CCGSol.objective[end]
        sheet["I$(3*instance_number)"] = CCGSol.num_iters
        sheet["J$(3*instance_number)"] = length(CCGSol.bases_constraints)
        sheet["L$(3*instance_number)"] = string(CCGSol.status)
    end
end