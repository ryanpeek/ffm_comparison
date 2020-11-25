# run FFC for altered USGS gage list

# Libraries ---------------------------------------------------------------

# main ffc package
#devtools::install_github('ceff-tech/ffc_api_client/ffcAPIClient')
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
library(sf)

# Load Functions ----------------------------------------------------------

# these functions written by R. Peek 2020 to facilitate iteration

# this uses the purrr package to loop through and pull ffc data for each gage
source("R/f_iterate_ffc.R")

# this takes these data and saves them all into a single file/s
source("R/f_ffc_collapse.R")

# Import Expanded USGS Gage List ------------------------------------------

# the updated expanded list w gages w +10 yrs data
usgs_alt <- read_rds("output/usgs_alt_gages_10yrs_1980_comids.rds") # n=935

# make a simple list of gage_id & gageIDName
gages <- usgs_alt %>%
  mutate(site_id_name = paste0("T",site_id)) %>%
  select(site_id, site_id_name, comid)

# Setup Iteration ---------------------------------------------------------

# set start date to start WY 1980
st_date <- "1979-10-01"

# RUN! --------------------------------------------------------------------

# chunk a set number at a time (and drop sf)
gagelist <- gages %>% st_drop_geometry() %>% slice(1:5)

tic() # start time
ffcs <- gagelist %>%
  select(site_id, comid) %>% # pull just ID column
  pmap(.l = ., .f = ~ffc_possible(.x, startDate = st_date, ffctoken=ffctoken, comid=.y, dirToSave="output/ffc_run_alt", save=TRUE)) %>%
  # add names to list
  set_names(x = ., nm=gagelist$site_id_name)
toc() # end time

# for 800+ =
## 3946 s (66 min)

# for 935 gages (748 with data!)
## 7047 s (117 min)

# see names
names(ffcs)

# a timestamp: format(Sys.time(), "%Y-%m-%d_%H%M")
(file_ts <- format(Sys.time(), "%Y%m%d_%H%M"))

# identify missing:
ffcs %>% keep(is.na(.)) %>% length() # missing 187

# make a list of gages
miss_gages<-ffcs %>% keep(is.na(.)) %>% names()

# save out missing
write_lines(miss_gages, file = glue("output/usgs_ffm_alt_missing_gages_{file_ts}.txt"))

# save out FFC R6 object (only if save=FALSE)
#save(ffcs, file = glue("output/usgs_ffm_ref_R6_full_{file_ts}.rda"))

# Follow Up for Missing ----------------------------------------------

# just look at missing gages here?

# test
(tst <-miss_gages[100])

# get comid if you don't know it for a gage
gage <- ffcAPIClient::USGSGage$new()
gage$id <- tst
gage$get_data()
gage$get_comid()
(comid <- gage$comid)

# RUN SETUP
fftst <- FFCProcessor$new()  # make a new object we can use to run the commands
fftst$fail_years_data = 9
fftst$gage_start_date = "1979-10-01"

# if you have comid, add via original usgs_alt dataset
fftst$set_up(gage_id=tst, comid = comid, token = ffctoken)
#fftst$set_up(gage_id="09423350", token = ffctoken)

# then run
fftst$run()

