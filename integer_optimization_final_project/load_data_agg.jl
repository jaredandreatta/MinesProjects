# This is the same as load_data.jl, but it takes in the data with aggregated variables as an input.

# Libraries
using JuMP, HiGHS;
using Plots;
using VegaLite; 
using DataFrames, CSV, PrettyTables;
ENV["COLUMNS"]=176;

# Data
datadir = joinpath("/Users/jayco/Desktop/MEGN688/MEGN688-final-project/data") 
gen_info = CSV.read(joinpath(datadir,"Generators_data.csv"), DataFrame);
fuels = CSV.read(joinpath(datadir,"Fuels_data.csv"), DataFrame);
loads = CSV.read(joinpath(datadir,"Demand.csv"), DataFrame);
gen_variable = CSV.read(joinpath(datadir,"Generators_variability.csv"), DataFrame);

# Rename all columns to lowercase 
for f in [gen_info, fuels, loads, gen_variable]
    rename!(f,lowercase.(names(f)))
end

# Keep columns relevant to our UC model 
select!(gen_info, 1:26) # columns 1:26
gen_df = outerjoin(gen_info,  fuels, on = :fuel) # load in fuel costs and add to data frame
rename!(gen_df, :cost_per_mmbtu => :fuel_cost)   # rename column for fuel cost
gen_df.fuel_cost[ismissing.(gen_df[:,:fuel_cost])] .= 0


# Create "is_variable" column to indicate if this is a variable generation source (e.g. wind, solar):
gen_df[!, :is_variable] .= false
gen_df[in(["onshore_wind_turbine","small_hydroelectric","solar_photovoltaic"]).(gen_df.resource),
    :is_variable] .= true;


gen_df.gen_full = lowercase.(gen_df.region .* "_" .* gen_df.resource .* "_" .* string.(gen_df.cluster) .* ".0");

# VARIABLE ELIMINATION

# Remove generators with no capacity 
# gen_df = gen_df[gen_df.existing_cap_mw .> 0,:];


# Convert from GMT to GMT-8 (This project is based off of the San Diego region)
gen_variable.hour = mod.(gen_variable.hour .- 9, 8760) .+ 1 
sort!(gen_variable, :hour)
loads.hour = mod.(loads.hour .- 9, 8760) .+ 1
sort!(loads, :hour);

# Convert from "wide" to "long" format
gen_variable_long = stack(gen_variable, 
                        Not(:hour), 
                        variable_name=:gen_full,
                        value_name=:cf);