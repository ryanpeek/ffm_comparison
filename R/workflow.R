# workflow!

# PACKAGES
source("R/packages.R")

# FUNCTION TO GET DATA FROM RAW SOURCE AND TIDY
source("R/get_data.R")

# use get data for version and return if you want to see data
get_data(2019, returndata = FALSE)
get_data(2020, returndata = FALSE)


# FUNCTION TO COMBINE VERSIONS (2019 and 2020) INTO SINGLE DATAFRAME
source("R/combine_data.R") # automatically loads data


# VISUALIZE
source("R/plot_summarize.R")

# view by stream class and flow component/characteristic
plot_flow_chx("Class-1","Magnitude")
plot_flow_chx("Class-2","Magnitude")
plot_flow_chx("Class-1","Timing")

# get table of values
flow_chx_dt("Magnitude")
