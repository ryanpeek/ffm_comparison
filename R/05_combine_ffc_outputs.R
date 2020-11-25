# 05: Combine FFC outputs


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

# Combine FFC: alteration -------------------------------------------------

# set the data type:
datatype <- "alteration"
df_ffc <- ffc_collapse(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.rds"), compress = "gz")

# Combine FFC: ffc_percentiles --------------------------------------------

# set the data type:
datatype <- "ffc_percentiles"
df_ffc <- ffc_collapse(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally()

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.rds"), compress = "gz")

# Combine FFC: ffc_results ------------------------------------------------

# set the data type:
datatype <- "ffc_results"
df_ffc <- ffc_collapse(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many years per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% View()

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_{type}_{datatype}_run_{runDate}.rds"), compress = "gz")

# FOR ffc_results: Pivot Longer
df_ffc_long <- df_ffc %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="v1.1_api") %>%
  filter(!is.na(value))

# save it
write_csv(df_ffc_long, file = glue("output/ffc_combined/usgs_{type}_{datatype}_long_run_{runDate}.csv"))
write_rds(df_ffc_long, file = glue("output/ffc_combined/usgs_{type}_{datatype}_long_run_{runDate}.rds"), compress = "gz")


