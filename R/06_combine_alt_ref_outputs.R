# Combine FFC alt and ref
# take ffc combined data from alt and ref and bind together into single file
# useful for broad analysis across ref/alt gages

# Libraries ---------------------------------------------------------------

options(tidyverse.quiet = TRUE)
library(tidyverse) # load quietly
library(conflicted) # deals with conflicting functions
conflict_prefer("filter", "dplyr")
library(glue) # good for pasting things together
library(fs)
library(lubridate)

# Load Function -----------------------------------------------------------

source("R/f_ffc_collapse.R")

# Setup Directory ---------------------------------------------------------

# get type
type <- "ref"

# get dir
ffc_dir <- glue("output/ffc_run_{type}/")
ffc_files <- dir_ls(ffc_dir, type = "file", regexp = "*.csv")
ffc_missing <- dir_ls("output", regexp = glue("usgs_ffm_{type}_missing_gages*"))
# extract just date
(runDate <- stringr::str_extract(ffc_missing, pattern = "[0-9]+"))

# look at modification time:
file_info(ffc_files[1])[[5]] %>% floor_date(unit = "day")

# create output location:
fs::dir_create("output/ffc_combined")

# Combine FFC: predicted_percentiles --------------------------------------

# set the data type:
datatype <- "predicted_percentiles"
df_ffc <- ffc_collapse(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.rds"), compress = "gz")
