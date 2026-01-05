# Write results from reformulation and CCG to XLSX files

function create_spreadsheet(method, M, N, T, α)
    if method == "reformulation"
        filename = string("M", M, "_N", N, "_T", T, "_a", Int(100*α), "_reformulation.xlsx")
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
        filename = string("M", M, "_N", N, "_T", T, "_a", Int(100*α), "_ccg.xlsx")
        XLSX.openxlsx(filename, mode = "w") do xf
            sheet = xf[1]

            # column headings
            sheet["A1"] = "instance"
            sheet["B1"] = "objective"
            sheet["C1"] = "solve time"
            sheet["D1"] = "Iters"
            sheet["E1"] = "Status"
            sheet["F1"] = "num variables"
            sheet["G1"] = "num cons"
            sheet["H1"] = "num quad cons"

            for instance_number in 1:10
                XLSX.addsheet!(xf, "$(instance_number)")
                sheet = xf[instance_number+1]
                # instance results
                sheet["A1"] = "iteration"
                sheet["B1"] = "MP objective"
                sheet["C1"] = "MP gap"
                sheet["D1"] = "Worst violation"
            end
        end
    end
end

function reformulation_spreadsheet(ReformSol::ReformulationSolutionInfo, solvetime_reform, instance_number, M, N, T, α)
    filename = string("M", M, "_N", N, "_T", T, "_a", Int(100*α), "_reformulation.xlsx")
    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # summary sheet
        sheet["A$(1+instance_number)"] = instance_number
        sheet["B$(1+instance_number)"] = ReformSol.objective
        sheet["C$(1+instance_number)"] = ReformSol.gap
        # sheet["D$(1+instance_number)"] = ReformSol.solvetime
        sheet["D$(1+instance_number)"] = solvetime_reform
        sheet["E$(1+instance_number)"] = string(ReformSol.status)
        sheet["F$(1+instance_number)"] = ReformSol.num_variables
        sheet["G$(1+instance_number)"] = ReformSol.num_constraints
        sheet["H$(1+instance_number)"] = ReformSol.num_quad_constraints
    end
end

function ccg_spreadsheet(CCGSol::CCGSolutionInfo, solvetime_ccg, instance_number, M, N, T, α)
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
        sheet["F$(1+instance_number)"] = CCGSol.num_variables
        sheet["G$(1+instance_number)"] = CCGSol.num_constraints
        sheet["H$(1+instance_number)"] = CCGSol.num_quad_constraints

        sheet = xf[instance_number+1]
        # instance results

        for i in 1:CCGSol.num_iters
            sheet["A$(1+i)"] = i
            sheet["B$(i+1)"] = CCGSol.objective[i]
            sheet["C$(i+1)"] = CCGSol.gap[i]
            sheet["D$(i+1)"] = CCGSol.worst_constraint_violation[i]
        end
    end
end