# run FFC for altered USGS gage list
# list includes 814 gages
# stored here: https://github.com/ryanpeek/ffm_comparison/blob/main/data/usgs_gages_altered.rds

# Libraries ---------------------------------------------------------------

# main ffc package
#devtools::install_github('ceff-tech/ffc_api_client/ffcAPIClient')
library(ffcAPIClient)

# set/get the token for using the FFC
ffctoken <- set_token(Sys.getenv("EFLOWS", ""))

# clean up
#ffcAPIClient::clean_account(ffctoken)

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

# chunk a set number at a time:
# gages2 <- gages %>% slice(1:100)

# or use all
gages2 <- gages

tic() # start time
ffcs <- gages2 %>%
  pluck("ID") %>% # pull just ID column
  map(., ~ffc_possible(.x, startDate = st_date, save=TRUE)) %>%
  # add names to list
  set_names(x = ., nm=gages2$ID)
toc() # end time
# for 800+ =
## 4164 s (79 min)
## 3946 s (66 min)

# see names
names(ffcs)

# identify missing:
ffcs %>% keep(is.na(.)) %>% length()

# make a list of gages
miss_gages<-ffcs %>% keep(is.na(.)) %>% names()

# save out missing
write_lines(miss_gages, file = "output/usgs_ffcs_gages_alt_missing_data.txt")

# save out FFC
save(ffcs, file = glue("output/usgs_ffcs_altered_raw_run_{Sys.Date()}.rda"))

# Follow Up Test for Missing ----------------------------------------------

# test
(tst <-miss_gages[1]) # 10259540

# get comid if you don't know it for a gage
gage <- ffcAPIClient::USGSGage$new()
gage$id <- tst
gage$get_data()
gage$get_comid()
(comid <- gage$comid)


# RUN SETUP
fftst <- FFCProcessor$new()  # make a new object we can use to run the commands
fftst$warn_years_data
fftst$fail_years_data = 9
fftst$fail_years_data
fftst$gage_start_date = "1979-10-01" # start_date and end_date are passed straight through to readNWISdv - "" means "retrieve all". Override values should be of the form YYYY-MM-DD
fftst$gage_start_date
fftst$timeseries_max_missing_days

# if you have comid, add via original usgs_alt dataset
fftst$set_up(gage_id=tst, comid = 22680750, token = ffctoken)

# then run
fftst$run()


# Import Raw Data Tidy and Write Out ------------------------------------------

(rawfile <- fs::dir_ls(path="output", type = "file", regexp = "usgs_ffcs_altered_raw_run*"))
# extract just run date:
runDate <- str_extract(rawfile, pattern = "[0-9-]+")

# load data
load(rawfile)

# set the data type:
datatype="predicted_wyt_percentiles"

# options:
## alteration
## ffc_percentiles
## ffc_results
## predicted_percentiles

# set directory where raw csvs live
fdir="output/ffc/"

# run it!
df_ffc <- ffc_collapse(datatype, fdir)

# view how many records
df_ffc %>% distinct(gageid) %>% count()
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# save it
write_csv(df_ffc, file = glue("output/usgs_alt_{datatype}_run_{runDate}.csv"))
write_rds(df_ffc, file = glue("output/usgs_alt_{datatype}_run_{runDate}.rds"))

# FOR ffc_results: Pivot Longer
df_ffc_long <- df_ffc %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="v1.1_api",
         year=as.character(year))

write_csv(df_ffc_long, file = glue("output/usgs_alt_{datatype}_run_{runDate}.csv"))
save(df_ffc_long, file = glue("output/usgs_alt_{datatype}_run_{runDate}.rda"))
