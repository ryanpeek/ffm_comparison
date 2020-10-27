# Manual Pipeline ---------------------------------------------------------

# GET PACKAGES
source("R/packages.R")


# 1. Unzip Data -----------------------------------------------------------

# function to unzip folders
source("R/data_unzip.R")

data_unzip(ffc_zip = 2019)
data_unzip(ffc_zip = 2020)


# 2. Combine all csvs for a single version into a single file -----------------

# collapses all individual csvs from each stream class into single file
# retains pertinent stream class/version info
source("R/data_raw_combine.R")
v2020 <- data_raw_combine(ffc_version = 2020)
v2019 <- data_raw_combine(ffc_version = 2019)


# 3. Merge both versions into single file (and tidy) ----------------------

source("R/data_merge.R")

df_merge <- data_merge(ffc_v1 = "2019", ffc_v2 = "2020")


# 4. Visualize & Summarize ------------------------------------------------

# can specify by stream class and flow characteristics
# "Timing"         "Magnitude"      "Duration"       "Rate of change" "Frequency"
source("R/data_plot_summarize.R")

# view by stream class and flow component/characteristic
plot_flow_chx(data=df_merge, stream_class = "Class-1", flow_characteristic = "Magnitude", save = FALSE)
plot_flow_chx(data=df_merge, stream_class = "Class-2", flow_characteristic = "Duration", save = TRUE)

# get table of values
flow_chx_dt(data = df_merge, flow_characteristic = "Magnitude")
