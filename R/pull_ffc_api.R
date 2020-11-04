# pull FFC API


# The FFC R Package -------------------------------------------------------

#devtools::install_github('ceff-tech/ffc_api_client/ffcAPIClient')
library(ffcAPIClient)

library(usethis)
#edit_r_environ() # and add API token

# set/get the token for using the FFC
ffctoken <- set_token(Sys.getenv("EFLOWS", ""))

# Supporting Packages -----------------------------------------------------
options(tidyverse.quiet = TRUE)
library(conflicted)
library(tidyverse)
library(glue)
conflict_prefer("filter", "dplyr")
#conflict_prefer("pivot_longer", "tidyr")
#library(sf)
library(tictoc) # timing stuff
library(furrr) # parallel processing for mapping functions/loops (purrr)
#library(tidylog) # good for logging what happens
options(scipen = 100)


# Set up the R6 processor -------------------------------------------------

# MFF: 11394500
# MER: 11264500
# NFA: 11427000

ffc <- FFCProcessor$new()  # make a new object we can use to run the commands
ffc$gage_start_date = "1979-10-01" # start_date and end_date are passed straight through to readNWISdv - "" means "retrieve all". Override values should be of the form YYYY-MM-DD

# should we run the timeseries filtering? Stays TRUE internally, but flag here
#ffc$timeseries_enable_filtering
#ffc$timeseries_max_missing_days = 7
#ffc$timeseries_max_consecutive_missing_days = 1
#ffc$timeseries_fill_gaps
#ffc$timeseries_fill_gaps = "yes" # is this only up to 7 days but not more?
#ffc$timeseries_enable_filtering
#ffc$SERVER_URL = 'https://eflows.ucdavis.edu/api/'

# we'll stop processing if we have this many years or fewer after filtering
#ffc$fail_years_data
#ffc$warn_years_data
#ffc$warn_years_data = 10 # default is 15

# RUN SETUP
ffc$set_up(gage_id=11264500, token = ffctoken)

# then run
ffc$run()

# then pull metrics
ffc$alteration
ffc$doh_data
ffc$ffc_percentiles
ffc$ffc_results
ffc$predicted_percentiles
ffc$predicted_wyt_percentiles


# Iteration ---------------------------------------------------------------

gages <- tibble("name"=c("MFF", "Merced", "NFA"), id=c(11394500, 11264500, 11427000))

# write a function to pull the data
ffc_iter <- function(id, startDate, save=TRUE){
  if(save==TRUE){
    # start ffc processor
    ffc <- FFCProcessor$new()
    # setup
    ffc$gage_start_date = startDate
    ffc$set_up(gage_id = id, token=ffctoken)
    ffc$run()
    # write out
    write_csv(ffc$alteration, file = glue::glue("output/ffc/{id}_alteration.csv"))
    write_csv(ffc$ffc_results, file = glue::glue("output/ffc/{id}_ffc_results.csv"))
    write_csv(ffc$ffc_percentiles, file=glue::glue("output/ffc/{id}_ffc_percentiles.csv"))
    write_csv(ffc$predicted_percentiles, file=glue::glue("output/ffc/{id}_predicted_percentiles.csv"))
  } else {
    return(ffc)
  }
}

# wrap in possibly to permit error catching
# see helpful post here: https://aosmith.rbind.io/2020/08/31/handling-errors/
ffc_possible <- possibly(.f = ffc_iter, otherwise = NA_character_)

# iterate
ffcs <- map(gages$id, ~ffc_possible(.x, startDate = "1979-10-01", save=TRUE)) %>%
  # add names to list
  set_names(., nm=gages$name)

# see names
names(ffcs)

# identify missing:
ffcs %>% keep(is.na(.))


# Read in and Collapse ----------------------------------------------------

datatype="ffc_percentiles"
fdir="output/ffc/"

# need function to read in and collapse different ffc outputs
ffc_collapse <- function(datatype, fdir){
  datatype = datatype
  csv_list = fs::dir_ls(path = fdir, regexp = datatype)
  csv_names = fs::path_file(csv_list) %>% fs::path_ext_remove()
  gage_ids = str_extract(csv_names, '([0-9])+')
  # read in all
  df <- purrr::map(csv_list, ~read_csv(.x)) %>%
    map2_df(gage_ids, ~mutate(.x,gageid=.y))

}

# IT WORKS!
tst <- ffc_collapse(datatype, fdir)
