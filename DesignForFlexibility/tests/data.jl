# generates a random instance of the robust facility location problem and returns the general model form
function data_generator(process_data_file, price_data_file)
    # read data files
    process_data = XLSX.readxlsx(process_data_file)
    price_data = XLSX.readxlsx(price_data_file)

    # compressor train data
    DFFParams = DesignForFlexibilityParams(I=process_data["Design parameters"]["C2"], J=process_data["Design parameters"]["B2"], S=1, T=12, β=1e4)

    # DFFParams.β = 1e4

    DFFParams.tank_cost[1] = process_data["Design parameters"]["E13"]
    DFFParams.tank_cost[2] = process_data["Design parameters"]["G13"]

    DFFParams.compressor_cost[1] = process_data["Design parameters"]["M13"]
    DFFParams.compressor_cost[2] = process_data["Design parameters"]["O13"]

    DFFParams.tank_min[1] = process_data["Design parameters"]["D2"]
    DFFParams.tank_max[1] = process_data["Design parameters"]["E2"]
    DFFParams.tank_min[2] = process_data["Design parameters"]["F2"]
    DFFParams.tank_max[2] = process_data["Design parameters"]["G2"]

    DFFParams.tank_min[3] = process_data["Design parameters"]["H2"]
    DFFParams.tank_max[3] = process_data["Design parameters"]["I2"]

    DFFParams.compressor_min[1] = process_data["Design parameters"]["L2"]
    DFFParams.compressor_max[1] = process_data["Design parameters"]["M2"]
    DFFParams.compressor_min[2] = process_data["Design parameters"]["N2"]
    DFFParams.compressor_max[2] = process_data["Design parameters"]["O2"]

    for s in 1:DFFParams.S, t in 1:DFFParams.T
        DFFParams.power_price[(s-1)*DFFParams.T+t] = (price_data["Scheduling horizon 1"]["D$(24*(s-1)+2*t)"] + price_data["Scheduling horizon 1"]["D$(24*(s-1)+2*t+1)"]) / 2
        DFFParams.load_price[(s-1)*DFFParams.T+t] = (price_data["Scheduling horizon 1"]["E$(24*(s-1)+2*t)"] + price_data["Scheduling horizon 1"]["E$(24*(s-1)+2*t+1)"]) / 2
    end

    DFFParams.power_compressor[1] = process_data["Scheduling parameters"]["C2"]
    DFFParams.power_compressor[2] = process_data["Scheduling parameters"]["E2"]

    DFFParams.demand[1, 1:DFFParams.S*DFFParams.T] .= -process_data["Stream data"]["B15"]
    for t in process_data["Stream data"]["B16"]:process_data["Stream data"]["B16"]:DFFParams.S*DFFParams.T
        DFFParams.demand[3, t] = process_data["Stream data"]["B16"] * process_data["Stream data"]["B15"]
    end
    DFFParams.bigM = 1 * sum(DFFParams.demand[3, t] for t in 1:DFFParams.S*DFFParams.T)

    DFFParams.load_max = 500.0
    DFFParams.load_min = 0.0

    # Convert robust facility location problem to general model
    ModelParams = GeneralModelParameters(
        num_x=DFFParams.S * DFFParams.T,
        num_y=1 + DFFParams.J + DFFParams.I + (2 + DFFParams.I) * DFFParams.S * DFFParams.T + sum(t for t in 1:DFFParams.T) * DFFParams.S * DFFParams.I,
        num_y_bin=DFFParams.S * DFFParams.T,
        num_ξ=DFFParams.S * DFFParams.T,
        num_cons=DFFParams.S * (DFFParams.T - 1) + DFFParams.S * DFFParams.T,
        num_ξcons=(2 * DFFParams.I + 2 * DFFParams.J + 1) * DFFParams.S * DFFParams.T + 1,
        num_ξset=3 * DFFParams.S * DFFParams.T
    )

    # scaling_factor = 1
    scaling_factor = maximum(DFFParams.compressor_max)
    scaling_factor_obj = 365/DFFParams.S
    ζ = 10

    # objective function
    ModelParams.cost_x = -DFFParams.β * DFFParams.load_price / (scaling_factor*scaling_factor_obj)

    ModelParams.cost_y[1] = DFFParams.T*(365 / DFFParams.S)/scaling_factor_obj
    ModelParams.cost_y[2:1+DFFParams.J] = DFFParams.tank_cost/scaling_factor_obj
    ModelParams.cost_y[2+DFFParams.J:1+DFFParams.J+DFFParams.I] = DFFParams.compressor_cost/scaling_factor_obj

    # bounds
    ModelParams.lower_x .= DFFParams.Γ_min
    for s in 1:DFFParams.S, t in 1:DFFParams.T
        ModelParams.upper_x[(s-1)*DFFParams.T+t] = t
    end

    ModelParams.lower_y[1] = -Inf
    ModelParams.upper_y[1] = Inf
    ModelParams.lower_y[2:1+DFFParams.J] = DFFParams.tank_min / scaling_factor
    ModelParams.upper_y[2:1+DFFParams.J] = DFFParams.tank_max / scaling_factor
    ModelParams.lower_y[2+DFFParams.J:1+DFFParams.J+DFFParams.I] = DFFParams.compressor_min / scaling_factor
    ModelParams.upper_y[2+DFFParams.J:1+DFFParams.J+DFFParams.I] = DFFParams.compressor_max / scaling_factor
    ModelParams.lower_y[2+DFFParams.J+DFFParams.I:1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T] .= DFFParams.load_min / scaling_factor
    ModelParams.upper_y[2+DFFParams.J+DFFParams.I:1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T] .= DFFParams.load_max / scaling_factor
    ModelParams.upper_y[2+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T:1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T] .= DFFParams.bigM
    ModelParams.lower_y[2+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T:1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T+sum(t for t in 1:DFFParams.T)*DFFParams.S*DFFParams.I] .= -DFFParams.bigM
    ModelParams.upper_y[2+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T:1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T+sum(t for t in 1:DFFParams.T)*DFFParams.S*DFFParams.I] .= DFFParams.bigM
    ModelParams.upper_y[2+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T+sum(t for t in 1:DFFParams.T)*DFFParams.S*DFFParams.I:ModelParams.num_y] .= 1

    ModelParams.lower_ξ .= 0.0
    ModelParams.upper_ξ .= 1.0

    # constraints without uncertainty
    for s in 1:DFFParams.S, t in 1:(DFFParams.T-1)
        ModelParams.Atilde[(s-1)*(DFFParams.T-1)+t, (s-1)*DFFParams.T+t] = 1
        ModelParams.Atilde[(s-1)*(DFFParams.T-1)+t, (s-1)*DFFParams.T+t+1] = -1
    end
    for s in 1:DFFParams.S, t in 1:DFFParams.T
        ModelParams.Dtilde[DFFParams.S*(DFFParams.T-1)+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+(s-1)*DFFParams.T+t] = 1
        ModelParams.Dtilde[DFFParams.S*(DFFParams.T-1)+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+sum(st for st in 1:DFFParams.T)*DFFParams.S*DFFParams.I+(s-1)*DFFParams.T+t] = -DFFParams.load_max / scaling_factor
    end

    # constraints with uncertainty
    # epigraph reformulation
    ModelParams.d[ModelParams.num_ξcons, 1] = -1
    for i in DFFParams.I, s in 1:DFFParams.S, t in 1:DFFParams.T
        ModelParams.d[ModelParams.num_ξcons, 1+DFFParams.J+DFFParams.I+(s-1)*DFFParams.T+t] = -DFFParams.load_price[(s-1)*DFFParams.T+t]/DFFParams.T
        ModelParams.d[ModelParams.num_ξcons, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = DFFParams.power_price[(s-1)*DFFParams.T+t] * DFFParams.power_compressor[i]/DFFParams.T
        for tt in max(1, t-ζ):t
        # for tt in 1:t
            ModelParams.Dbar[ModelParams.num_ξcons][(s-1)*DFFParams.T+tt, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+DFFParams.I*DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*sum(st for st in 1:DFFParams.T)+(s-1)*sum(st for st in 1:DFFParams.T)+sum(st for st in 1:(t-1); init=0)+tt] = DFFParams.power_price[(s-1)*DFFParams.T+t] * DFFParams.power_compressor[i]/DFFParams.T
        end
    end

    # flowrates
    for i in 1:DFFParams.I, s in 1:DFFParams.S, t in 1:DFFParams.T
        # 0.4*Psize ≤ P_{ist}
        ModelParams.d[(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+i] = (24 / DFFParams.T) * DFFParams.compressor_flexibility
        ModelParams.d[(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = -1
        for tt in max(1, t-ζ):t
        # for tt in 1:t
            ModelParams.Dbar[(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+tt, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(i-1)*sum(st for st in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(st for st in 1:DFFParams.T)+sum(st for st in 1:(t-1); init=0)+tt] = -1
        end

        # Psize ≥ P_{ist}
        ModelParams.d[DFFParams.I*DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+i] = -(24 / DFFParams.T)
        ModelParams.d[DFFParams.I*DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = 1
        for tt in max(1, t-ζ):t
        # for tt in 1:t
            ModelParams.Dbar[DFFParams.I*DFFParams.S*DFFParams.T+(i-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+tt, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(i-1)*sum(st for st in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(st for st in 1:DFFParams.T)+sum(st for st in 1:(t-1); init=0)+tt] = 1
        end
    end

    # 0 ≤ Q_{jst} ≤ Qsize_j: assuming zero initial inventory
    for j in 1:DFFParams.J, s in 1:DFFParams.S, t in 1:DFFParams.T
        ModelParams.b[2*DFFParams.I*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = -sum(DFFParams.demand[j, (s-1)*DFFParams.T+tt] for tt in 1:t) / scaling_factor
        for tt in 1:t
            if j > 1
                ModelParams.d[2*DFFParams.I*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(j-2)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+tt] = -1
                # for st in 1:tt
                for st in max(1, tt-ζ):tt
                    ModelParams.Dbar[2*DFFParams.I*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+st, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(j-2)*sum(stt for stt in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(stt for stt in 1:DFFParams.T)+sum(stt for stt in 1:(tt-1); init=0)+st] = -1
                end
            end
            if j < 3
                ModelParams.d[2*DFFParams.I*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+tt] = 1
                # for st in 1:tt
                for st in max(1, tt-ζ):tt
                    ModelParams.Dbar[2*DFFParams.I*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+st, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(j-1)*sum(stt for stt in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(stt for stt in 1:DFFParams.T)+sum(stt for stt in 1:(tt-1); init=0)+st] = 1
                end
            end
        end


        ModelParams.d[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+j] = -1
        ModelParams.b[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = sum(DFFParams.demand[j, (s-1)*DFFParams.T+tt] for tt in 1:t) / scaling_factor
        for tt in max(1, t-ζ):t
        # for tt in 1:t
            if j > 1
                ModelParams.d[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(j-2)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+tt] = 1
                for st in 1:tt
                    ModelParams.Dbar[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+st, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(j-2)*sum(stt for stt in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(stt for stt in 1:DFFParams.T)+sum(stt for stt in 1:(tt-1); init=0)+st] = 1
                end
            end
            if j < 3
                ModelParams.d[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+tt] = -1
                for st in 1:tt
                    ModelParams.Dbar[(2*DFFParams.I+DFFParams.J)*DFFParams.S*DFFParams.T+(j-1)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+st, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(j-1)*sum(stt for stt in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(stt for stt in 1:DFFParams.T)+sum(stt for stt in 1:(tt-1); init=0)+st] = -1
                end
            end
        end
    end

    # satisfy load reduction readuested
    for s in 1:DFFParams.S, t in 1:DFFParams.T
        ModelParams.Dbar[(2*DFFParams.I+2*DFFParams.J)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+(s-1)*DFFParams.T+t] = 1
        ModelParams.d[(2*DFFParams.I+2*DFFParams.J)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+DFFParams.I*sum(st for st in 1:DFFParams.T)*DFFParams.S+(s-1)*DFFParams.T+t] = DFFParams.bigM
        ModelParams.b[(2*DFFParams.I+2*DFFParams.J)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t] = DFFParams.bigM

        for tt in 1:t, i in 1:DFFParams.I
            ModelParams.Dbar[(2*DFFParams.I+2*DFFParams.J)*DFFParams.S*DFFParams.T+(s-1)*DFFParams.T+t][(s-1)*DFFParams.T+tt, 1+DFFParams.J+DFFParams.I+(1+DFFParams.I)*DFFParams.S*DFFParams.T+(i-1)*sum(st for st in 1:DFFParams.T)*DFFParams.S+(s-1)*sum(st for st in 1:DFFParams.T)+sum(st for st in 1:(t-1); init=0)+tt] = DFFParams.power_compressor[i]
        end
    end

    # uncertainty set
    # w_st >= 0
    ModelParams.W[1:ModelParams.num_ξ, 1:ModelParams.num_ξ] = -LinearAlgebra.I(ModelParams.num_ξ)

    # w_st <= 1
    ModelParams.W[ModelParams.num_ξ+1:2*ModelParams.num_ξ, 1:ModelParams.num_ξ] = LinearAlgebra.I(ModelParams.num_ξ)
    ModelParams.v[ModelParams.num_ξ+1:2*ModelParams.num_ξ] .= 1.0

    # \sum_t' w_st <= Γ_st
    for s in 1:DFFParams.S, t in 1:DFFParams.T, tt in 1:t
        ModelParams.W[2*ModelParams.num_ξ+(s-1)*DFFParams.T+t, (s-1)*DFFParams.T+tt] = 1
        ModelParams.U[2*ModelParams.num_ξ+(s-1)*DFFParams.T+t, (s-1)*DFFParams.T+t] = 1
    end

    return DFFParams, ModelParams
end
