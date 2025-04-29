# Including other files, including the aggregated data for efficient formulation
include("load_data.jl")
#include("load_data_agg.jl")
include("model.jl")


# For my project, I will solve the using the simple unit commitment model over a time horizon of 1-7 days. I will then
# implement my efficient formulation methods and evaluate model performance of including the methods. 


# April 10
n = 100
start_hour = n * 24 + 1

# This is a set of time periods ranging from 1 day to 1 week (April 10-April 17)
T_periods = []

# Create a range for each day length from 1 day to 7 days
for day_length in 1:7
    end_hour = start_hour + day_length * 24 - 1
    push!(T_periods, start_hour:end_hour)
end

# This is for checking the individual days instead of elongated time horizons
#T_period_2 = 2496:2520

# High solar case: 3,500 MW
# Testing for high solar capacity 
gen_df_sens = copy(gen_df)
gen_df_sens[gen_df_sens.resource .== "solar_photovoltaic",
    :existing_cap_mw] .= 3500

loads_multi = loads[in.(loads.hour,Ref(T_period_2)),:]
gen_variable_multi = gen_variable_long[in.(gen_variable_long.hour,Ref(T_period_2)),:]

# Solve
solution = unit_commitment_simple(
    gen_df_sens, loads_multi, gen_variable_multi, 0.01); #1% MIP Gap


# Writing the results to a csv file
function write_solution_to_csv(solution, base_filename)
    gen, commit, curtail, cost, status = solution
    CSV.write("$(base_filename)_gen.csv", gen)
    CSV.write("$(base_filename)_commit.csv", commit)
    CSV.write("$(base_filename)_curtail.csv", curtail)
    open("$(base_filename)_info.txt", "w") do io
        write(io, "Cost: $cost\nStatus: $status")
    end
end

write_solution_to_csv(solution, "unit_commitment_day_4")

