# assess years of record for "missing" gages from list

# packages
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


# Load ALT GAGES ---------------------------------------------------------------

# this is the altered list from Sam et al (n=814)
gages_alt <- read_rds("data/usgs_gages_alt_814.rds") %>%
  # make ID col without T
  mutate(ID=gsub("T", "", ID))

# make spatial
gages_alt_sf <- gages_alt %>%
  sf::st_as_sf(coords=c("LONGITUDE","LATITUDE"), crs=4269, remove=FALSE)

# Load REF GAGES ---------------------------------------------------------------

# get list of ref gages from Noelle's outputs (n=223)
# ref_gages_df <- read_rds("output/ffm_ref_combined_tidy.rds")
# ref_gages <- ref_gages_df %>% distinct(gage_id) %>% pull()
# write_lines(ref_gages, file = "data/usgs_gages_ref_ffcs.txt")
ref_gages <- read_lines("data/usgs_gages_ref_223.txt") # just a vector


# Load GAGES2 Data --------------------------------------------------------

# gages2 data (n=9322)
load("data/gages2AttrPlus.rda")
gages2 <- gages2AttrPlus %>% filter(STATE=="CA") # only CA=810

# how many ref in gages2? (n=191)
gages2 %>% filter(STAID %in% ref_gages) %>% count()

# how many alt in gages2? (n=517)
gages2 %>% filter(STAID %in% gages_alt$ID) %>% count()

# Get All USGS CA Gages ---------------------------------------------------

# RUN ONCE: part of {dataRetrieval} package

paramCd <- "00060" # discharge (cfs) (temperature=00010, stage=00065)
dataInterval <- "dv" # daily interval, feed via "service" argument
site_type <- "ST" # only streams (instead of ST-CA=stream canal, etc: https://maps.waterdata.usgs.gov/mapper/help/sitetype.html)


# get all raw FLOW gages
ca_usgs <- dataRetrieval::whatNWISdata(stateCd="CA", service=dataInterval, parameterCd=paramCd, statCd="00003", siteType=site_type) # n=2366

# double check parameters are clean
table(ca_usgs$site_tp_cd) # some extra ST-DCH and ST-CA types
table(ca_usgs$parm_cd)
table(ca_usgs$stat_cd)

# filter out any STREAM CANALS or STREAM DITCHES
ca_usgs <- ca_usgs %>%
  filter(site_tp_cd==site_type) # n=2322

# see how many total UNIQUE usgs gages
ca_usgs %>% distinct(site_no, .keep_all = TRUE) %>% count() # n=2313

# so where are duplicates?
ca_usgs %>% group_by(site_no) %>% tally() %>% filter(n>1)

# most of these all appear to be same gages, but record is split in two. A few are duplicates
# 09429210 split across two records, both valid: ts_id=5428, 217607, keep both
# 09429500 has 3 records, 2 are duplicates: ts_id=213060, 5437 dups, keep larger number
# 11218700 ts_id=213628, 9319 dups, keep larger number
# 11253500 ts_id=214005, 9442 dups, keep larger number
# 11363930 ts_id=217015, 10127 dups, keep larger number
# 11374305 ts_id=217513, 10191 dups, keep larger
# 11429500 ts_id=225039, 10865 dups, keep larger

# TIDY and cleanup
ca_dv <- ca_usgs %>%
  # rename cols
  dplyr::rename(interval=data_type_cd, lat = dec_lat_va, lon=dec_long_va,
                huc8=huc_cd, site_id=site_no, date_begin=begin_date,
                date_end=end_date, datum=dec_coord_datum_cd, elev_m=alt_va) %>%
  # drop unneeded cols
  select(-(loc_web_ds:access_cd)) %>%
  # filter out the duplicates from above:
  filter(!ts_id %in% c(5437, 9319, 9442, 10127, 10191, 10865)) %>%
  # make spatial
  sf::st_as_sf(coords=c("lon","lat"), crs=4269, remove=FALSE)

# how many distinct? (n=2313)
ca_dv %>% distinct(site_id) %>% count()

# save out
write_rds(ca_dv, file = "data/usgs_ca_all_dv_gages.rds")

# Load All USGS Daily Flow Gages in CA ------------------------------------

ca_dv <- read_rds("data/usgs_ca_all_dv_gages.rds")

# CROSS CHECK USGS W GAGES2 & REF/ALT -------------------------------------

# how many ref in this usgs DV list?
ca_dv %>% filter(site_id %in% ref_gages) %>%
  distinct(site_id) %>% count()
# only 221 in this list from USGS list?

# what 2 are not in this list?
tibble(ref_id=ref_gages) %>% filter(!ref_id %in% ca_dv$site_id)
# 11299000=NEW MELONES DAM 1927 to present?
# 11446220=AMERICAN RIVER BLW FOLSOM, only continuous for TEMPERATURE?

# how many alt are NOT in usgs dv dataset?
gages_alt %>% filter(!ID %in% ca_dv$site_id)
# only one 10293050=E WALKER RV BLW SWEETWATER CK NR BRIDGEPORT (only 2011-2015 avail)

# how many gages2 in usgs set?
ca_dv %>% filter(site_id %in% gages2$STAID) %>%
  distinct(site_id) %>% count()
# only 805 match (of 810)...what's missing?

# LOOK AT MISSING GAGES FROM GAGES2 (not in CA DV gages)
gages2 %>% filter(!STAID %in% ca_dv$site_id) %>% pull(STAID)

# looking these up on USGS-NWIS website, found following:
# "10339400" = MARTIS C NR TRUCKEE, Peak streamflow and field measurements only
# "11161300" = CARBONERA C A SCOTTS VALLEY CA, Peak streamflow and field measurements only
# "11206800" = MARBLE FORK KAWEAH R AB TOKOPAH FALLS, Peak streamflow and field measurements only
# "11383730" = SACRAMENTO R A VINA BRIDGE NR VINA, Peak streamflow and field measurements only
# "11383800" = SACRAMENTO R NR HAMILTON CITY CA, Peak streamflow and field measurements, daily continuous data only for sediment and temperature

# Save out Ref List -------------------------------------------------------

ca_dv %>% filter(site_id %in% ref_gages) -> ref_gages

# save out ref with info
write_csv(ref_gages, file = "output/usgs_ref_gages_list.csv")
write_rds(ref_gages, file = "output/usgs_ref_gages_list.rds")

# GET EXPANDED LIST -------------------------------------------------------

# now take what we know and add the other USGS DV gages that weren't included
# in the altered list.

# USING original list: gages_alt

# make a simple list of gage_id & comid
alt_gages <- gages_alt %>% select(ID, NHDV2_COMID)

# make list of additional gages to run
alt_gages_ca_dv <- ca_dv %>%
  # drop orig n=814 alt list
  filter(!site_id %in% alt_gages$ID) %>%
  # drop ref gages (n=223)
  filter(!site_id %in% ref_gages)

# n=1314 (not including orig n=814)
# distinct? (n=1311), so some duplicates
alt_gages_ca_dv %>% distinct(site_id) %>% tally()

# make list of ALL alt gages (drop ref gages)
alt_gages_all <- ca_dv %>%
  # drop ref gages (n=223)
  filter(!site_id %in% ref_gages)
# n=2095 (including any gages from n=814 that are in this list)
# n=2092 (distinct)

#mapview(alt_gages_all)



# Make some Plots ---------------------------------------------------------

# check for dups (n=3)
alt_gages_all[duplicated(alt_gages_all$site_id),]

## add a years duration col
alt_gages_all <- alt_gages_all %>%
  mutate(total_yrs = year(date_end)-year(date_begin),
         total_post1980 = year(date_end)-1980)

# save expanded list (including 814)
write_rds(alt_gages_all, file = "output/usgs_alt_gages_list.rds")
write_csv(alt_gages_all, file = "output/usgs_alt_gages_list.csv")

# how many have >=10 yrs data post 1980?
alt_gages_10yrs <- alt_gages_all %>% filter(total_post1980>9 & total_yrs>9) # n=935
mapview(alt_gages_10yrs, zcol="total_post1980")

# save the trimmed list:
write_rds(alt_gages_10yrs, file = "output/usgs_alt_gages_list_10yrs_1980.rds")
write_csv(alt_gages_10yrs, file = "output/usgs_alt_gages_list_10yrs_1980.csv")


# PLOT ALL ALT GAGES
ggplot() +
  geom_linerange(data=alt_gages_10yrs,
                 aes(x=site_id, ymin=date_begin, ymax=date_end, color=total_post1980),
                 show.legend = T, size=0.25) +

  geom_hline(yintercept = ymd("1979-10-01"), color="maroon", lty=2, lwd=1.2)+
  coord_flip() +
  scale_color_viridis_c("Total Years\n post-1980")+
  ggdark::dark_theme_classic() +
  labs(x="", y="", subtitle=glue("USGS Altered Gages with 9+ years data post-1980 (n={nrow(alt_gages_10yrs)})"),
       caption="data: USGS {dataRetrieval} package")

# save
ggsave(filename = "figures/usgs_altered_10plusyrs_post1980.png",
       width = 10, height = 8, dpi = 300, units = "in")

# find gages with less than 10 years of data
miss_10 <- alt_gages_all %>%
  filter(total_yrs<10 |
         total_post1980<10) # n=1160
nrow(miss_10)

#mapview(miss_10, zcol="total_yrs")
