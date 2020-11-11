# run FFC for altered USGS gage list
# list includes 814 gages
# stored here: https://github.com/ryanpeek/ffm_comparison/blob/main/data/usgs_gages_altered.rds


# Libraries ---------------------------------------------------------------

# main ffc package
library(ffcAPIClient)

# set/get the token for using the FFC
ffctoken <- set_token(Sys.getenv("EFLOWS", ""))

# clean up
ffcAPIClient::clean_account(ffctoken)

# packages
options(tidyverse.quiet = TRUE)
library(tidyverse) # load quietly
library(conflicted) # deals with conflicting functions
conflict_prefer("filter", "dplyr")
library(glue) # good for pasting things together
library(tictoc) # timing stuff
options(scipen = 100) # to print full string instead of sci notation


# Load Functions ----------------------------------------------------------

# these functions written by R. Peek 2020 to facilitate iteration

# this uses the purrr package to loop through and pull ffc data for each gage
source("R/f_iterate_ffc.R")

# this takes these data and saves them all into a single file/s
source("R/f_ffc_collapse.R")


# Import Gage List --------------------------------------------------------

usgs_alt <- read_rds("data/usgs_gages_altered.rds") # n=814

# check for duplicates (look at distinct records):
usgs_alt %>% group_by(ID) %>% n_distinct()

# make a simple list of gage_id & comid
gages <- usgs_alt %>% select(ID, NHDV2_COMID) %>%
  # fix the "T" and remove
  mutate(ID=gsub("T", "", ID))


# Setup Iteration ---------------------------------------------------------

# set start date to start WY 1980
st_date <- "1979-10-01"


# RUN! --------------------------------------------------------------------

# chunk 100 at a time:
g100 <- gages %>% slice(1:100)

tic() # start time
ffcs <- gages %>%
  pluck("ID") %>%
  map(., ~ffc_possible(.x, startDate = st_date, save=TRUE)) %>%
  # add names to list
  set_names(x = ., nm=gages$ID)
toc() # end time

# see names
names(ffcs)

# identify missing:
ffcs %>% keep(is.na(.)) %>% length()

# make a list of gages
miss_gages<-ffcs %>% keep(is.na(.)) %>% names()

# save out missing
write_lines(miss_gages, file = "output/ffcs_usgs_altered_missing_data.txt")

# save out FFC
save(ffcs, file = "output/ffcs_usgs_altered_raw.rda")

# Follow Up Test for Missing ----------------------------------------------

# see this one 10264675

tst <-miss_gages[1]

# RUN SETUP
fftst <- FFCProcessor$new()  # make a new object we can use to run the commands
fftst$warn_years_data
fftst$fail_years_data = 7
fftst$fail_years_data
fftst$gage_start_date = "1979-10-01" # start_date and end_date are passed straight through to readNWISdv - "" means "retrieve all". Override values should be of the form YYYY-MM-DD
fftst$gage_start_date
fftst$timeseries_max_missing_days
fftst$set_up(gage_id=tst, token = ffctoken)

# then run
fftst$run()


# Read in and Collapse ----------------------------------------------------

datatype="ffc_results"
fdir="output/ffc/"

source("R/f_ffc_collapse.R")

# IT WORKS!
df_ffc <- ffc_collapse(datatype, fdir)

# pivot longer
df_long <- df_ffc %>%
  #filter(gageid==11394500) %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="api",
         year=as.character(year))
