
# This function converts a multidimensional array into a 2D dataframe.
# Credit for this function and model go to Professor Michael Davidson (UCSD) and Professor Jesse Jenkins (Princeton)
# They are the ones who developed the course that this project embellishes.

function value_to_df_2dim(var)
    solution = DataFrame(var.data, :auto)
    ax1 = var.axes[1]
    ax2 = var.axes[2]
    cols = names(solution)
    insertcols!(solution, 1, :r_id => ax1)
    solution = stack(solution, Not(:r_id), variable_name=:hour)
    solution.hour = foldl(replace, [cols[i] => ax2[i] for i in 1:length(ax2)], init=solution.hour)
    rename!(solution, :value => :gen)
    solution.hour = convert.(Int64,solution.hour)
    return solution
end

# The following is the model to solve a simple unit commitment problem, which include less resources, shorter time horizons, and less commitment 
# decisions. See project paper for general form of the unit commitment model. 
# This model follows the structure of the GitHub course that inspired me to make this. It has been tweaked to make adjustments 
# for my changes I've made to the model.

function unit_commitment_simple(gen_df, loads, gen_variable, mip_gap)
    UC = Model(HiGHS.Optimizer)
    set_optimizer_attribute(UC, "mip_rel_gap", mip_gap)

    # SETS

        # Thermal resources with unit commitment constraints
    G_thermal = gen_df[gen_df[!,:up_time] .> 0,:r_id] 

        # Non-thermal resources without unit commitment constraints
    G_nonthermal = gen_df[gen_df[!,:up_time] .== 0,:r_id]

        # Variable renewable resources
    G_var = gen_df[gen_df[!,:is_variable] .== true,:r_id]

        # Non-variable resources
    G_nonvar = gen_df[gen_df[!,:is_variable] .== false,:r_id]

        # Non-variable and non-thermal resources
    G_nt_nonvar = intersect(G_nonvar, G_nonthermal)

        # Set of all generators (above are all subsets of this)
    G = gen_df.r_id

        # All time periods (hours) over which we are optimizing
    T = loads.hour

        # A subset of time periods that excludes the last time period
    T_red = loads.hour[1:end-1]  # reduced time periods without last one

    # Generator capacity factor time series 
    gen_var_cf = innerjoin(gen_variable, 
                    gen_df[gen_df.is_variable .== 1 , 
                        [:r_id, :gen_full, :existing_cap_mw]], 
                    on = :gen_full)
        
    # VARIABLES
    @variables(UC, begin
            # Continuous decision variables
        GEN[G, T]  >= 0     # Generation of generator g in time period t (MW)
            # Discrete binary variables
        COMMIT[G_thermal, T], Bin # commitment status
        START[G_thermal, T], Bin  # startup decision
        SHUT[G_thermal, T], Bin   # shutdown decision
    end)
                
    # Objective function
        # Sum of variable costs + start-up costs for all generators and time periods
    @objective(UC, Min, 
        # Variable cost of variable resources ($) 
        # VarCost = variable cost of ops and maintenance ($) +  (heat rate (mmBTU/MWh) * fuel cost ($)) 
        sum( (gen_df[gen_df.r_id .== i,:heat_rate_mmbtu_per_mwh][1] * gen_df[gen_df.r_id .== i,:fuel_cost][1] +
            gen_df[gen_df.r_id .== i,:var_om_cost_per_mwh][1]) * GEN[i,t] 
                        for i in G_nonvar for t in T) + 
        # Variable cost for non-variable resources ($)
        sum(gen_df[gen_df.r_id .== i,:var_om_cost_per_mwh][1] * GEN[i,t] 
                        for i in G_var for t in T)  + 
        # Startup cost ($) depending on startup decision
        sum(gen_df[gen_df.r_id .== i,:start_cost_per_mw][1] * 
            gen_df[gen_df.r_id .== i,:existing_cap_mw][1] *
            START[i,t] 
                        for i in G_thermal for t in T)
    )
    
    # Demand constraint (MW) ; supply must equal demand
    # GEN = cDemand for all t in T
    @constraint(UC, cDemand[t in T], 
        sum(GEN[i,t] for i in G) == loads[loads.hour .== t,:demand][1])

    # Capacity constraints (MW)
      # Thermal generators requiring commitment
      # Cap_thermal_min <= GEN <+ Cap_thermal_max for all i in G_thermal, t in T 
      # Generation of thermal generators must be within operating bounds (contingent upon unit commitment status)
    @constraint(UC, Cap_thermal_min[i in G_thermal, t in T], 
        GEN[i,t] >= COMMIT[i, t] * gen_df[gen_df.r_id .== i,:existing_cap_mw][1] *
                        gen_df[gen_df.r_id .== i,:min_power][1])
    @constraint(UC, Cap_thermal_max[i in G_thermal, t in T], 
        GEN[i,t] <= COMMIT[i, t] * gen_df[gen_df.r_id .== i,:existing_cap_mw][1])

      # Non-variable generation not requiring commitment
      # GEN <= Cap_nt_nonvar for all i in G_nt_nonvar, t in T
      # Non-thermal non-variable resources max operating bounds
    @constraint(UC, Cap_nt_nonvar[i in G_nt_nonvar, t in T], 
        GEN[i,t] <= gen_df[gen_df.r_id .== i,:existing_cap_mw][1])
    
      # Variable generation, accounting for hourly capacity factor
    @constraint(UC, Cap_var[i in 1:nrow(gen_var_cf)], 
            GEN[gen_var_cf[i,:r_id], gen_var_cf[i,:hour] ] <= 
                        gen_var_cf[i,:cf] *
                        gen_var_cf[i,:existing_cap_mw])
    
    # Unit commitment constraints
      # Minimum up time of generator g
      # COMMIT >= sum(START) [for t' > t - minumum uptime] for all i in G_thermal, t in T
      # Commitment status must exceed the sum of startup decisions for all generators in all time periods
    @constraint(UC, Startup[i in G_thermal, t in T],
        COMMIT[i, t] >= sum(START[i, tt] 
                        for tt in intersect(T,
                            (t-gen_df[gen_df.r_id .== i,:up_time][1]):t)))

      # Minimum down time
      # This is just the inverse of the minumum uptime constraint
    @constraint(UC, Shutdown[i in G_thermal, t in T],
        1-COMMIT[i, t] >= sum(SHUT[i, tt] 
                        for tt in intersect(T,
                            (t-gen_df[gen_df.r_id .== i,:down_time][1]):t)))
 
      # Commitment status
      # This constraint enforces the logic that the change in commitment status in next time period must match 
      # operating decision of starting/stopping in the current time period.
      # For example, if START = 1 and STOP = 0 in time period t+1, that indicates that generator i is started.
      # This means that the generator i must be committed in period t+1, as it is not in period t.
    @constraint(UC, CommitmentStatus[i in G_thermal, t in T_red],
        COMMIT[i,t+1] - COMMIT[i,t] == START[i,t+1] - SHUT[i,t+1])

    
    
    # Solve statement 
    optimize!(UC)

    # Generation solution and convert to data frame 
    # with our helper function defined above
    gen = value_to_df_2dim(value.(GEN))

    # Commitment status solution and convert to data frame
    commit = value_to_df_2dim(value.(COMMIT))

    # Calculate curtailment = available wind and/or solar output that 
    # had to be wasted due to operating constraints
    curtail = innerjoin(gen_var_cf, gen, on = [:r_id, :hour])
    curtail.curt = curtail.cf .* curtail.existing_cap_mw - curtail.gen
    
    # Return the solution parameters and objective
    return (
        gen,
        commit,
        curtail,
        cost = objective_value(UC),
        status = termination_status(UC)
    )

end