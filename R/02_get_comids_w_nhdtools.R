# 04 Filter with NHD


# Packages ----------------------------------------------------------------

options(tidyverse.quiet = TRUE)
library(tidyverse) # load quietly
library(conflicted) # deals with conflicting functions
conflict_prefer("filter", "dplyr")
library(glue) # good for pasting things together
library(tictoc) # timing stuff
options(scipen = 100) # to print full string instead of sci notation
library(dataRetrieval)
library(mapview)
library(lubridate)
library(sf)
library(nhdplusTools)


# Data --------------------------------------------------------------------

type <- "alt"

usgs_alt_gages <- read_rds("output/usgs_alt_gages_list.rds")
usgs_ref_gages <- read_rds("output/usgs_ref_gages_list.rds")

# make into simple usgs_list
usgs_list <- usgs_alt_gages

# GET COMIDS --------------------------------------------------------------

# TRANSFORM TO 3310
usgs_list <- usgs_list %>%
  distinct(site_id, .keep_all = TRUE) %>%
  st_transform(crs = 3310) # use CA Teale albs metric

#  Create dataframe for looking up COMIDS
segs <- usgs_list %>%
  select(site_id, lat, lon, geometry) %>%
  mutate(comid=NA)

# use nhdtools to get comids
comids <- segs %>% # test w 10 [c(1:10),]
  group_split(site_id) %>%
  set_names(x = ., nm = segs$site_id) %>%
  map(~discover_nhdplus_id(.x$geometry))

# flatten into single dataframe instead of list
segs_df <- comids %>% flatten_dfc() %>% t() %>%
  as.data.frame() %>%
  rename("comid"=V1) %>% rownames_to_column(var = "site_id")

# check for na?
summary(segs_df)

# how many negatives?
filter(segs_df, comid<0) %>% count()

# save out temp file
write_rds(segs_df, file=glue("output/usgs_{type}_gages_list_comids.rds"))

# clean up
rm(comids, segs)

# join data back to original dataframe
usgs_list_coms <- left_join(usgs_list, segs_df, by=c("site_id"))

# save it back out
write_rds(usgs_list_coms, file = glue("output/usgs_{type}_gages_list_comids.rds"))


# FOR ALT: Add COMID to 10yr Post-1980 List -------------------------------

# usgs_list_coms: full list with coms

alt_1980 <- read_rds("output/usgs_alt_gages_10yrs_1980.rds")

# join alt_1980
usgs_alt_1980 <- left_join(alt_1980, segs_df, by=c("site_id"))

# save
write_rds(usgs_alt_1980, file="output/usgs_alt_gages_10yrs_1980_comids.rds")
write_csv(usgs_alt_1980, file="output/usgs_alt_gages_10yrs_1980_comids.csv")
