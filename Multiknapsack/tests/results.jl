# Write results from reformulation and CCG to XLSX files

function create_spreadsheet(method)
    if method == "reformulation"
        filename = string("M", M, "_N", N, "_T", T, "_a", α, "_reformulation.xlsx")
        XLSX.openxlsx(filename, mode = "w") do xf
            sheet = xf[1]

            # column headings
            sheet["A1"] = "instance"
            sheet["B1"] = "objective"
            sheet["C1"] = "gap"
            sheet["D1"] = "solve time"
            sheet["F1"] = "num variables"
            sheet["G1"] = "num cons"
            sheet["H1"] = "num quad cons"
        end
    end 
end

function reformulation_spreadsheet(ReformSol::ReformulationSolutionInfo, instance_number)
    filename = string("M", M, "_N", N, "_T", T, "_a", α, "_reformulation.xlsx")
    XLSX.openxlsx(filename, mode = "rw") do xf
        sheet = xf[1]

        # instance results
        sheet["A$(1+instance_number)"] = instance_number
        sheet["B$(1+instance_number)"] = ReformSol.objective
        sheet["C$(1+instance_number)"] = ReformSol.gap
        sheet["D$(1+instance_number)"] = ReformSol.solvetime
        sheet["F$(1+instance_number)"] = ReformSol.num_variables
        sheet["G$(1+instance_number)"] = ReformSol.num_constraints
        sheet["H$(1+instance_number)"] = ReformSol.num_quad_constraints
    end
end