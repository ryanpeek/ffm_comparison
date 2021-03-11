# pull FFC API


# The FFC R Package -------------------------------------------------------

#devtools::install_github('ceff-tech/ffc_api_client/ffcAPIClient')
library(ffcAPIClient)

#library(usethis)
#edit_r_environ() # and add API token

# set/get the token for using the FFC
ffctoken <- set_token(Sys.getenv("EFLOWS", ""))

ffcAPIClient::clean_account(ffctoken)

# Supporting Packages -----------------------------------------------------

options(tidyverse.quiet = TRUE)
library(conflicted)
library(tidyverse)
library(glue)
conflict_prefer("filter", "dplyr")
library(tictoc) # timing stuff
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


# Run Steps ---------------------------------------------------------------

# RUN SETUP
ffc$set_up(gage_id="11427000", token = ffctoken)

# then run
ffc$run()

# then pull metrics
ffc$alteration
ffc$doh_data
ffc$ffc_percentiles
ffc$ffc_results
ffc$predicted_percentiles
ffc$predicted_wyt_percentiles

# steps
ffc$step_one_functional_flow_results(gage_id = 11264500, token = ffctoken, output_folder = "output/ffc")
ffc$step_two_explore_ecological_flow_criteria()
ffc$step_three_assess_alteration()



# Pass Timeseries ---------------------------------------------------------


# pass your own timeseries with "timeseries"
tst <- dataRetrieval::readNWISdv(11264500,parameterCd = "00060")
tst <- tst %>% dataRetrieval::renameNWISColumns() %>% janitor::clean_names()

ffc <- FFCProcessor$new()
ffc$date_field <- "date"
ffc$flow_field <- "flow"
ffc$date_format_string <- "%Y-%m-%d"
ffc$set_up(token = ffctoken,
           timeseries=tst, comid=21609533)

# run
ffc$run()

# get comid if you don't know it for a gage
gage <- ffcAPIClient::USGSGage$new()
gage$id <- 11264500 # 10339419
gage$get_data()
gage$get_comid()
(comid <- gage$comid)

# Iteration ---------------------------------------------------------------

gages <- tibble("name"=c("MFF", "Merced", "NFA"), id=c(11394500, 11264500, 11427000))

source("R/f_iterate_ffc.R")

# for altered can start: "1979-10-01"

# iterate with purrr::map()
tic()
ffcs <- map(gages$id, ~ffc_possible(.x, startDate = "", ffctoken=ffctoken, save=FALSE)) %>%
  # add names to list
  set_names(., nm=gages$name)
toc()
# 66.22

# see names
names(ffcs)

# identify missing:
ffcs %>% keep(is.na(.))


# Read in and Collapse ----------------------------------------------------

datatype="ffc_results"
fdir="output/ffc/"

source("R/f_ffc_collapse.R")

# IT WORKS!
df_ffc <- ffc_collapse(datatype, fdir)

# pivot longer
tst <- df_ffc %>% filter(gageid==11394500) %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="api",
         year=as.character(year))


# Compare gages with v2020 ---------------------------------------------------


df_all <- read_rds("output/ffm_combined_tidy.rds")

df_filt <- df_all %>%
  filter(gage_id == 11394500, ffc_version=="2020") %>%
  select(ffc_version, gage_id:flow_metric_name)
# what is year range?
range(df_filt$year)
unique(df_filt$ffm)


# match year range with tst
tst <- tst %>% filter(year %in% df_filt$year, !ffm %in% c("Peak_Tim_10", "Peak_Tim_5", "Peak_Tim_2"))
range(tst$year)
unique(tst$ffm)


# combine
df_combine <- bind_rows(df_filt, tst)

# plot
ggplot() +
  geom_boxplot(data=df_combine,
               aes(x = ffm, y=value, fill=ffc_version, group=ffm),
               alpha=0.9, show.legend = FALSE, outlier.alpha = 0.3)+
  coord_flip() + labs(x="", y="Value", subtitle = glue("FF Metrics")) +
  scale_fill_brewer(type = "qual") +
  theme_classic() +
  facet_wrap(~ffc_version)
ggsave(filename = "figures/comparison_mffeather_11394500.png", width = 11, height = 8, dpi=300)
