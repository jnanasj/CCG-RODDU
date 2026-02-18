# generates a random instance of the mulitknapsack problem and returns the general model form
function data_generator(N::Int64, data_file)
    # read IEEE bus data file
    data = XLSX.readxlsx(data_file)

    DNELParams = DNELParameters(N=N) # initialize parameters for N-node bus system

    # generators data
    DNELParams.I = length(data["generators"]["A"])-1 # number of generators (not including renewables)
    for i in 1:DNELParams.I
        DNELParams.generators[i] = [
            data["generators"]["F$(i+1)"], # node
            data["generators"]["E$(i+1)"], # reference dispatch,
            data["generators"]["D$(i+1)"], # reserve,
            data["generators"]["B$(i+1)"], # min capacity,
            data["generators"]["C$(i+1)"], # max capacity
        ]
    end

    # transmission lines data
    DNELParams.L = length(data["system"]["A"])-1 # number of transmission lines
    for l in 1:DNELParams.L
        DNELParams.lines[l] = [
            data["system"]["B$(l+1)"], # from node
            data["system"]["A$(l+1)"], # to node
            data["system"]["C$(l+1)"], # line flow distribution
            data["system"]["D$(l+1)"] # transmission limit
        ]
    end

    # load data
    if N == 118
        DNELParams.K = length(data["load"]["A"])-1 # number of loads
        for k in 1:DNELParams.K
            DNELParams.loads[k] = [
                data["load"]["A$(k+1)"], # node
                data["load"]["B$(k+1)"] # load
            ]
        end
    else
        for l in 1:DNELParams.L
            if data["system"]["E$(l+1)"] > 0
                DNELParams.K+=1
                DNELParams.loads[DNELParams.K] = [
                    data["system"]["A$(l+1)"], # node
                    data["system"]["E$(l+1)"], # load
                ]
            end
        end
    end

    # renewables data
    DNELParams.J = length(data["renewables"]["A"])-1 # number of wind power plants
    for j in 1:DNELParams.J
        DNELParams.renewables[j] = [
            data["renewables"]["B$(j+1)"], # node 
            data["renewables"]["C$(j+1)"], # contribution factor
            data["renewables"]["D$(j+1)"], # nominal capacity
            data["renewables"]["E$(j+1)"], # min capacity
            data["renewables"]["F$(j+1)"], # max capacity
        ]
    end

    ModelParams = GeneralModelParameters(num_x = 2*DNELParams.J, num_y = DNELParams.I*DNELParams.J, num_ξ = DNELParams.J, num_ξcons = 4*DNELParams.I+2*DNELParams.L+2, num_ξset = 2*DNELParams.J)

    # scaling_factor = 1
    scaling_factor = maximum(DNELParams.generators[i][2] for i in 1:DNELParams.I)
    DNELParams.scaling_factor = scaling_factor

    for j in 1:DNELParams.J
        ModelParams.lower_x[j] = DNELParams.renewables[j][4]/scaling_factor
        ModelParams.lower_x[DNELParams.J + j] = DNELParams.renewables[j][3]/scaling_factor

        ModelParams.upper_x[j] = DNELParams.renewables[j][3]/scaling_factor
        ModelParams.upper_x[DNELParams.J + j] = DNELParams.renewables[j][5]/scaling_factor

        ModelParams.lower_ξ[j] = DNELParams.renewables[j][4]/scaling_factor
        ModelParams.upper_ξ[j] = DNELParams.renewables[j][5]/scaling_factor
    end

    ModelParams.upper_y .= 10

    # objective
    for j in 1:DNELParams.J
        ModelParams.cost_x[j] = DNELParams.renewables[j][2]*scaling_factor
        ModelParams.cost_x[DNELParams.J + j] = -DNELParams.renewables[j][2]*scaling_factor
    end

    # generator capacity limits
    for i in 1:DNELParams.I
        ModelParams.b[i] = (DNELParams.generators[i][2] - DNELParams.generators[i][4])/scaling_factor # lower
        ModelParams.b[DNELParams.I+i] = (DNELParams.generators[i][5] - DNELParams.generators[i][2])/scaling_factor # upper
    end
    for i in 1:DNELParams.I, j in 1:DNELParams.J
        ModelParams.d[i, (i-1)*DNELParams.J+j] = -DNELParams.renewables[j][3]/scaling_factor # lower
        ModelParams.Dbar[i, j, (i-1)*DNELParams.J+j] = 1 # lower

        ModelParams.d[DNELParams.I+i, (i-1)*DNELParams.J+j] = DNELParams.renewables[j][3]/scaling_factor # upper
        ModelParams.Dbar[DNELParams.I+i, j, (i-1)*DNELParams.J+j] = -1 # upper
    end

    # reserve limits
    for i in 1:DNELParams.I
        ModelParams.b[2*DNELParams.I+i] = DNELParams.generators[i][3]/scaling_factor # lower
        ModelParams.b[3*DNELParams.I+i] = DNELParams.generators[i][3]/scaling_factor # upper
    end
    for i in 1:DNELParams.I, j in 1:DNELParams.J
        ModelParams.d[2*DNELParams.I+i, (i-1)*DNELParams.J+j] = -DNELParams.renewables[j][3]/scaling_factor # lower
        ModelParams.Dbar[2*DNELParams.I+i, j, (i-1)*DNELParams.J+j] = 1 # lower

        ModelParams.d[3*DNELParams.I+i, (i-1)*DNELParams.J+j] = DNELParams.renewables[j][3]/scaling_factor # upper
        ModelParams.Dbar[3*DNELParams.I+i, j, (i-1)*DNELParams.J+j] = -1 # upper
    end

    # transmission limits: <= 
    for l in 1:DNELParams.L
        ModelParams.b[4*DNELParams.I+l] = DNELParams.lines[l][4]/scaling_factor

        for i in DNELParams.I, j in 1:DNELParams.J
            if DNELParams.lines[l][1] == DNELParams.generators[i][1]
                ModelParams.b[4*DNELParams.I+l] = ModelParams.b[4*DNELParams.I+l] - DNELParams.generators[i][2]*DNELParams.lines[l][3]/scaling_factor

                ModelParams.d[4*DNELParams.I+l, (i-1)*DNELParams.J+j] = DNELParams.renewables[j][3]*DNELParams.lines[l][3]/scaling_factor
                ModelParams.Dbar[4*DNELParams.I+l, j, (i-1)*DNELParams.J+j] = -DNELParams.lines[l][3]
            end
            if DNELParams.lines[l][1] == DNELParams.renewables[j][1]
                ModelParams.bbar[4*DNELParams.I+l, j] = -DNELParams.lines[l][3]
            end
        end

        for k in 1:DNELParams.K
            if DNELParams.lines[l][1] == DNELParams.loads[k][1]
                ModelParams.b[4*DNELParams.I+l] = ModelParams.b[4*DNELParams.I+l] + DNELParams.loads[k][2]*DNELParams.lines[l][3]/scaling_factor
            end
        end
    end

    # transmission limits: >= 
    for l in 1:DNELParams.L
        ModelParams.b[4*DNELParams.I+DNELParams.L+l] = DNELParams.lines[l][4]/scaling_factor

        for i in DNELParams.I, j in 1:DNELParams.J
            if DNELParams.lines[l][1] == DNELParams.generators[i][1]
                ModelParams.b[4*DNELParams.I+DNELParams.L+l] = ModelParams.b[4*DNELParams.I+l] + DNELParams.generators[i][2]*DNELParams.lines[l][3]/scaling_factor

                ModelParams.d[4*DNELParams.I+DNELParams.L+l, (i-1)*DNELParams.J+j] = -DNELParams.renewables[j][3]*DNELParams.lines[l][3]/scaling_factor
                ModelParams.Dbar[4*DNELParams.I+DNELParams.L+l, j, (i-1)*DNELParams.J+j] = DNELParams.lines[l][3]
            end
            if DNELParams.lines[l][1] == DNELParams.renewables[j][1]
                ModelParams.bbar[4*DNELParams.I+DNELParams.L+l, j] = DNELParams.lines[l][3]
            end
        end

        for k in 1:DNELParams.K
            if DNELParams.lines[l][1] == DNELParams.loads[k][1]
                ModelParams.b[4*DNELParams.I+DNELParams.L+l] = ModelParams.b[4*DNELParams.I+l] - DNELParams.loads[k][2]*DNELParams.lines[l][3]/scaling_factor
            end
        end
    end

    # power balance <=
    ModelParams.b[ModelParams.num_ξset-1] = (sum(DNELParams.loads[k][2] for k in 1:DNELParams.K) - sum(DNELParams.generators[i][2] for i in 1:DNELParams.I))/scaling_factor
    ModelParams.bbar[ModelParams.num_ξset-1, :] .= -1

    for i in 1:DNELParams.I, j in 1:DNELParams.J
        ModelParams.d[ModelParams.num_ξset-1, (i-1)*DNELParams.J+j] = DNELParams.renewables[j][3]/scaling_factor
        ModelParams.Dbar[ModelParams.num_ξset-1, j, (i-1)*DNELParams.J+j] = -1
    end

    # power balance >=
    ModelParams.b[ModelParams.num_ξset] = (-sum(DNELParams.loads[k][2] for k in 1:DNELParams.K) + sum(DNELParams.generators[i][2] for i in 1:DNELParams.I))/scaling_factor
    ModelParams.bbar[ModelParams.num_ξset, :] .= 1

    for i in 1:DNELParams.I, j in 1:DNELParams.J
        ModelParams.d[ModelParams.num_ξset, (i-1)*DNELParams.J+j] = -DNELParams.renewables[j][3]/scaling_factor
        ModelParams.Dbar[ModelParams.num_ξset, j, (i-1)*DNELParams.J+j] = 1
    end

    # uncertainty set
    ModelParams.W[1:DNELParams.J, 1:DNELParams.J] = -LinearAlgebra.I(DNELParams.J)
    ModelParams.U[1:DNELParams.J, 1:DNELParams.J] = -LinearAlgebra.I(DNELParams.J)

    ModelParams.W[DNELParams.J+1:2*DNELParams.J, 1:DNELParams.J] = LinearAlgebra.I(DNELParams.J)
    ModelParams.U[DNELParams.J+1:2*DNELParams.J, DNELParams.J+1:2*DNELParams.J] = LinearAlgebra.I(DNELParams.J)

    return DNELParams, ModelParams
end