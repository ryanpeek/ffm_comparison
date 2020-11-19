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

usgs_alt_gages <- read_rds("output/usgs_alt_gages_expanded.rds")

# GET COMIDS --------------------------------------------------------------

library(nhdplusTools)

# TRANSFORM TO 3310
usgs_alt <- usgs_alt_gages %>%
  distinct(site_id, .keep_all = TRUE) %>%
  st_transform(crs = 3310) # use CA Teale albs metric

#  Create dataframe for looking up COMIDS
alt_segs <- usgs_alt %>%
  select(site_id, lat, lon, geometry) %>%
  mutate(comid=NA)

# use nhdtools to get comids
alt_comids <- alt_segs %>% # test w 10 [c(1:10),]
  group_split(site_id) %>%
  set_names(x = ., nm = alt_segs$site_id) %>%
  map(~discover_nhdplus_id(.x$geometry))

# flatten into single dataframe instead of list
alt_segs_df <- alt_comids %>% flatten_dfc() %>% t() %>%
  as.data.frame() %>%
  rename("comid"=V1) %>% rownames_to_column(var = "site_id")

# save out
write_rds(alt_segs_df, file="output/usgs_alt_gages_expanded_comids.rds")

# clean up
rm(alt_comids, alt_segs)

# join data back to original dataframe
usgs_alt_gages_coms <- left_join(usgs_alt_gages, alt_segs_df, by=c("site_id"))

# save it back out
write_rds(usgs_alt_gages_coms, file = "output/usgs_alt_gages_expanded_full_comids.rds")


# DOWNLOAD NHD MAINSTEMS --------------------------------------------

# download the streamline information now
# filter out the bad comids
alt_coms_filt <- filter(usgs_alt_gages_coms, comid>0)

# make a list for nhdtoolsPlus
coms_list <- map(alt_coms_filt$comid, ~list(featureSource = "comid", featureID=.x))

# now feed this com list and get stream segments
mainstemsUS <- map(coms_list, ~navigate_nldi(nldi_feature = .x,
                                             mode="upstreamMain",
                                             distance_km = 10,
                                             data_source = ""))

# check length (for NAs?)
mainstemsUS %>%
  purrr::map_lgl(~ length(.x)>1) %>% table()

# make a single flat layer
mainstems_flat_us <- mainstemsUS %>%
  set_names(., alt_coms_filt$site_id) %>%
  map2(alt_coms_filt$site_id, ~mutate(.x, gageID=.y))

# bind together to single dataframe
mainstems_us <- sf::st_as_sf(data.table::rbindlist(mainstems_flat_us, use.names = TRUE, fill = TRUE))

# view
mapview(mainstems_us) + mapview(alt_coms_filt, col.regions="orange")

# save data
write_rds(mainstems_us, file="output/usgs_alt_mainstems_us.rds")
save(mainstems_us, file="output/usgs_alt_mainstems_us.rda")

# GET NHD ATTRIBS IN GPKG --------------------------------------

# tell it where things are
nhdplus_path(path = "/Volumes/RAP200/nhdplus_seamless/full_db/NHDPlusV21_National_Seamless_Flattened_Lower48.gdb")

# staged data
staged_data <- stage_national_data(output_path = "/Volumes/RAP200/nhdplus_seamless/full_db/staged_national_data")
staged_data

# get flowlines only
flowline <- readRDS(staged_data$flowline)


# filter to gage_comids
alt_flowlines <- flowline %>% filter(COMID %in% alt_coms_filt$comid)
alt_flowlines %>% st_drop_geometry() %>% distinct(COMID) %>% count() # n=1801 comids
alt_coms_filt %>% st_drop_geometry() %>% distinct(comid) %>% count() # n=1801 comids

# find gages that aren't in list above
usgs_alt_gages_coms_filt <- usgs_alt_gages_coms %>% filter(!comid %in% alt_flowlines$COMID)

# check?
mapview(alt_flowlines, lwd=2.5) + mapview(usgs_alt_gages_coms, col.regions="orange") + mapview(usgs_alt_gages_coms_filt, col.regions="yellow")


# INDEX
flowline_indexes <- left_join(data.frame(id = seq_len(nrow(usgs_alt_gages_coms))),
                              get_flowline_index(
                                sf::st_transform(alt_flowlines, 5070), # CONUS ALBERS US
                                sf::st_geometry(sf::st_transform(usgs_alt_gages_coms, 5070)),
                                search_radius = 200), by = "id") %>%
  cbind(., site_id=usgs_alt_gages_coms$site_id)

# summary shows 285 are missing measurements...drop these?

# join info
usgs_alt_indexed <- left_join(usgs_alt_gages_coms, flowline_indexes, by=c("site_id")) %>%
  filter(!is.na(COMID)) %>%
  distinct(site_id, .keep_all = TRUE)

# how many unique comids? # 1774
usgs_alt_indexed %>% distinct(COMID) %>% count()


# add years
usgs_alt_indexed <- usgs_alt_indexed %>%
  mutate(total_yrs = year(date_end)-year(date_begin),
         total_post1980 = year(date_end)-1980)

## SAVE IT!
write_rds(usgs_alt_indexed, file="output/usgs_alt_gages_expanded_indexed_all.rds")

# how many are post 1980?
usgs_alt_indexed %>% filter(total_post1980>10) %>% count()

# map
usgs_alt_indexed %>% filter(total_post1980>10) %>% mapview(zcol="total_post1980")
