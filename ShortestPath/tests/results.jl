# Write results from reformulation and CCG to XLSX files

function create_spreadsheet(method)
    if method == "reformulation"
        filename = string("results/I", num_nodes, "_reformulation.xlsx")
        XLSX.openxlsx(filename, mode = "w") do xf
            sheet = xf[1]

            # column headings
            sheet["A1"] = "instance"
            sheet["B1"] = "objective"
            sheet["C1"] = "gap"
            sheet["D1"] = "solve time"
            sheet["E1"] = "Status"
            sheet["F1"] = "num variables"
            sheet["G1"] = "num cons"
            sheet["H1"] = "num quad cons"
        end
    end 
    if method == "CCG"
        filename = string("results/I", num_nodes, "_ccg.xlsx")
        XLSX.openxlsx(filename, mode = "w") do xf
            sheet = xf[1]

            # column headings
            sheet["A1"] = "instance"
            sheet["B1"] = "objective"
            sheet["C1"] = "solve time"
            sheet["D1"] = "Iters"
            sheet["E1"] = "Status"
            sheet["F1"] = "num cuts"
            sheet["G1"] = "num variables"
            sheet["H1"] = "num cons"
            sheet["I1"] = "num quad cons"

            for instance_number in 1:10
                XLSX.addsheet!(xf, "$(instance_number)")
                sheet = xf[instance_number+1]
                # instance results
                sheet["A1"] = "iteration"
                sheet["B1"] = "MP objective"
                sheet["C1"] = "MP gap"
                sheet["D1"] = "MP solve time"
                sheet["E1"] = "Worst violation"
            end
        end
    end
end

function reformulation_spreadsheet(ReformSol::ReformulationSolutionInfo, solvetime_reform, instance_number)
    filename = string("results/I", num_nodes, "_reformulation.xlsx")
    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet
        sheet["A$(1+instance_number)"] = instance_number
        sheet["B$(1+instance_number)"] = ReformSol.objective
        sheet["C$(1+instance_number)"] = ReformSol.gap
        sheet["D$(1+instance_number)"] = solvetime_reform
        sheet["E$(1+instance_number)"] = string(ReformSol.status)
        sheet["F$(1+instance_number)"] = ReformSol.num_variables
        sheet["G$(1+instance_number)"] = ReformSol.num_constraints
        sheet["H$(1+instance_number)"] = ReformSol.num_quad_constraints
    end
end

function ccg_spreadsheet(CCGSol::CCGSolutionInfo, solvetime_ccg, instance_number)
    filename = string("results/I", num_nodes, "_ccg.xlsx")
    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet
        sheet["A$(1+instance_number)"] = instance_number
        sheet["B$(1+instance_number)"] = CCGSol.objective[end]
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