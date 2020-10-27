# pull FFC API


# The FFC R Package -------------------------------------------------------

#devtools::install_github('ceff-tech/ffc_api_client/ffcAPIClient')
library(ffcAPIClient)

# set/get the token for using the FFC
ffctoken <- set_token(Sys.getenv("EFLOWS_TOKEN", ""))

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

ffc <- FFCProcessor$new()  # make a new object we can use to run the commands
ffc$set_up(gage_id=11427000, token = ffctoken)

# we'll stop processing if we have this many years or fewer after filtering
ffc$fail_years_data
# we'll warn people if we have this many years or fewer after filtering
ffc$warn_years_data
#ffc$warn_years_data = 10 # default is 15

# should we run the timeseries filtering? Stays TRUE internally, but flag here
ffc$timeseries_enable_filtering
ffc$timeseries_max_missing_days = 7
ffc$timeseries_max_consecutive_missing_days = 1
ffc$timeseries_fill_gaps
#ffc$timeseries_fill_gaps = "yes" # is this only up to 7 days but not more?
ffc$timeseries_enable_filtering
ffc$gage_start_date = "1979-10-01" # start_date and end_date are passed straight through to readNWISdv - "" means "retrieve all". Override values should be of the form YYYY-MM-DD
ffc$gage_end_date = ""
ffc$SERVER_URL = 'https://eflows.ucdavis.edu/api/'

# then run?
ffc$run()

# MFF: 11394500
# MER: 11264500
# NFA: 11427000
