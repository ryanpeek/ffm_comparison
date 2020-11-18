# 05: Combine FFC outputs


# Libraries ---------------------------------------------------------------

options(tidyverse.quiet = TRUE)
library(tidyverse) # load quietly
library(conflicted) # deals with conflicting functions
conflict_prefer("filter", "dplyr")
library(glue) # good for pasting things together
library(tictoc) # timing stuff


# Load Function -----------------------------------------------------------

source("R/f_ffc_collapse.R")


# Get Raw FFC Output --------------------------------------------------

# # this is the raw ffc output
# (rawfile <- fs::dir_ls(path="output", type = "file", regexp = "usgs_ffcs_altered_raw_run*"))
# # extract just the run dates:
# runDate <- stringr::str_extract(rawfile, pattern = "[0-9-]+")
# # take most recent date
# max(lubridate::ymd(runDate))
# # load data
# load(rawfile)

# look at modification time:
fs::file_info("output/ffc/09423350_alteration.csv")[[5]] %>% as.Date()

# Combine FFC: predicted_percentiles --------------------------------------

# dateRun
runDate <- "2020-11-17"

# set the data type:
datatype <- "predicted_percentiles"
fdir <- glue("{here::here()}/output/ffc/")
df_ffc <- ffc_collapse(datatype, fdir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# create output location:
fs::dir_create("output/ffc_combined")

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.rds"), compress = "gz")


# Combine FFC: alteration -------------------------------------------------

# set the data type:
datatype <- "alteration"
fdir <- glue("{here::here()}/output/ffc/")
df_ffc <- ffc_collapse(datatype, fdir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.rds"), compress = "gz")


# Combine FFC: ffc_percentiles --------------------------------------------

# set the data type:
datatype <- "ffc_percentiles"
fdir <- glue("{here::here()}/output/ffc/")
df_ffc <- ffc_collapse(datatype, fdir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally()

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.rds"), compress = "gz")


# Combine FFC: ffc_results ------------------------------------------------

# set the data type:
datatype <- "ffc_results"
fdir <- glue("{here::here()}/output/ffc/")
df_ffc <- ffc_collapse(datatype, fdir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many years per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% View()

# save it
write_csv(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/ffc_combined/usgs_alt_{datatype}_run_{runDate}.rds"), compress = "gz")

# FOR ffc_results: Pivot Longer
df_ffc_long <- df_ffc %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="v1.1_api") %>%
  filter(!is.na(value))

# save it
write_csv(df_ffc_long, file = glue("output/ffc_combined/usgs_alt_{datatype}_long_run_{runDate}.csv"))
write_rds(df_ffc_long, file = glue("output/ffc_combined/usgs_alt_{datatype}_long_run_{runDate}.rds"), compress = "gz")


