# assess years of record for "missing" gages from altered list

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


# Load Data ---------------------------------------------------------------

# vector of all gages that returned NA
miss_gages <- read_lines("output/usgs_ffcs_gages_alt_missing_data.txt")
miss_gages_df <- tibble(ID=miss_gages)

# join back with usgs dataset?
gages_alt <- read_rds("data/usgs_gages_altered.rds")
# make ID col without T
gages_alt <- gages_alt %>%
  mutate(ID=gsub("T", "", ID))

miss_gages_df <- inner_join(miss_gages_df, gages_alt, by="ID")

# make spatial
miss_gages_df <- miss_gages_df %>%
  sf::st_as_sf(coords=c("LONGITUDE","LATITUDE"), crs=4269, remove=FALSE)

# get list of ref gages
# ref_gages_df <- read_rds("output/ffm_combined_tidy.rds")
# ref_gages <- ref_gages_df %>% distinct(gage_id) %>% pull()
# write_lines(ref_gages, file = "output/ffcs_usgs_reference_gages.txt")
ref_gages <- read_lines("output/usgs_ffcs_gages_ref.txt")

# gages2 data
load("data/gages2AttrPlus.rda")
gages2 <- gages2AttrPlus %>% filter(STATE=="CA")

# how many ref in gages2?
gages2 %>% filter(STAID %in% ref_gages) %>% count()

# how many alt in gages2?
gages2 %>% filter(STAID %in% gages_alt$ID) %>% count()


# Get USGS Metadata -------------------------------------------------------

# RUN ONCE

# paramCd <- "00060" # discharge (cfs) (temperature=00010, stage=00065)
# dataInterval <- "dv" # daily interval, feed via "service" argument
#
# # get all raw FLOW gages
# ca_usgs <- dataRetrieval::whatNWISdata(stateCd="CA", service=dataInterval, parameterCd=paramCd, statCd="00003")
#
# # filter to CA dv
# ca_usgs <- ca_usgs %>% # filter to distinct, "dv"=daily values, and "00003"
#   filter(parm_cd == paramCd,
#          data_type_cd %in% c("dv"),
#          stat_cd == "00003")
#
# # this yields n=2391
#
# # see how many total usgs gages
# ca_usgs %>% distinct(site_no, .keep_all = TRUE) %>% count() # n=2381
#
# # check stats
# table(ca_usgs$data_type_cd)
# table(ca_usgs$stat_cd)
#
# # so where are duplicates?
# ca_usgs %>% group_by(site_no) %>% tally() %>% filter(n>1)
#
# # most of these all appear to be same gages, but record is split in two. A few are duplicates
#
# # TIDY
# ca_tidy <- ca_usgs %>%
#   # rename cols
#   dplyr::rename(interval=data_type_cd, lat = dec_lat_va, lon=dec_long_va,
#                 huc8=huc_cd, site_id=site_no, date_begin=begin_date,
#                 date_end=end_date, datum=dec_coord_datum_cd, elev_m=alt_va) %>%
#   # drop cols
#   select(-(loc_web_ds:access_cd)) %>%
#   # filter missing vals
#   dplyr::filter(!is.na(lon)) %>% # this is a pond out of Mt Shasta
#   sf::st_as_sf(coords=c("lon","lat"), crs=4269, remove=FALSE)
#
# # save out
# #write_rds(ca_tidy, file = "output/usgs_ca_all_dv_gages.rds")


# CROSS CHECK USGS W GAGES2 & REF/ALT -----------------------------------------------

# how many ref in usgs?
ca_tidy %>% filter(site_id %in% ref_gages) %>%
  distinct(site_id) %>% count()
# only 221 in this list from USGS list?

# what 2 are not in this list?
tibble(ref_id=ref_gages) %>% filter(!ref_id %in% ca_tidy$site_id)
# 11299000=NEW MELONES DAM!? 1927 to present?
# 11446220=AMERICAN RIVER BLW FOLSOM, only continuous for TEMPERATURE?

# how many alt are NOT in usgs?
tibble(alt_id=miss_gages) %>% filter(!alt_id %in% ca_tidy$site_id)
# only one 10293050=E WALKER RV BLW SWEETWATER CK NR BRIDGEPORT (only 2011-2015 avail)

# how many gages2 in usgs set?
ca_tidy %>% filter(site_id %in% gages2$STAID) %>%
  distinct(site_id) %>% count()
# only 805...what's missing?
gages2 %>% filter(!STAID %in% ca_tidy$site_id) %>% pull(STAID)
# "10339400" = MARTIS C NR TRUCKEE, Peak streamflow and field measurements only
# "11161300" = CARBONERA C A SCOTTS VALLEY CA, Peak streamflow and field measurements only
# "11206800" = MARBLE FORK KAWEAH R AB TOKOPAH FALLS, Peak streamflow and field measurements only
# "11383730" = SACRAMENTO R A VINA BRIDGE NR VINA, Peak streamflow and field measurements only
# "11383800" = SACRAMENTO R NR HAMILTON CITY CA, Peak streamflow and field measurements, daily continuous data only for sediment and temperature


# GET EXPANDED LIST -------------------------------------------------------

## GET GAGE LIST OF ALT TO RUN IN ADDITION TO ORIGINAL ALT LIST
usgs_alt <- read_rds("data/usgs_gages_altered.rds") # n=814

# make a simple list of gage_id & comid
gages <- usgs_alt %>% select(ID, NHDV2_COMID) %>%
  # fix the "T" and remove
  mutate(ID=gsub("T", "", ID))

# make list of additional gages to run
alt_gages_rev <- ca_tidy %>%
  # drop orig n=814 alt list
  filter(!site_id %in% gages$ID) %>%
  # drop ref gages (n=223)
  filter(!site_id %in% ref_gages)

# n=1386 (not including orig n=814)
# n=2169 (including any gages from n=814 that are in this list)

# save this out
write_rds(alt_gages_rev, file = "output/usgs_alt_gages_expanded_full.rds")
write_csv(alt_gages_rev, file = "output/usgs_alt_gages_expanded_full.csv")

# save trimmed list (excluding 814)
write_rds(alt_gages_rev, file = "output/usgs_alt_gages_expanded_trim.rds")
write_csv(alt_gages_rev, file = "output/usgs_alt_gages_expanded_trim.csv")

mapview(alt_gages_rev)

# Map Together ------------------------------------------------------------

ca_tidy <- read_rds("output/usgs_ca_all_dv_gages.rds")

# bind ref_gages with ca_tidy
ca_ref <- filter(ca_tidy, site_id %in% ref_gages)

mapview(ca_tidy, col.regions="gray", cex=0.5, layer.name="ALL USGS") +
  mapview(miss_gages_df, col.regions="maroon", layer.name="Miss Altered") +
  mapview(ca_ref, col.regions="skyblue", layer.name="Ref")


# Make some Plots ---------------------------------------------------------

miss_gages_df2 <- left_join(miss_gages_df, st_drop_geometry(ca_tidy), by=c("ID"="site_id")) %>%
  # drop dups using ts_id: 10865 and 10127
  filter(!ts_id %in% c(10865, 10127),
         !is.na(date_begin))

# check for dups
miss_gages_df2[duplicated(miss_gages_df2$ID),]

## add a years duration col
miss_gages_df2 <- miss_gages_df2 %>%
  mutate(total_yrs = year(date_end)-year(date_begin),
         total_post1980 = year(date_end)-1980)

# PLOT ALL MISSING ALT GAGES
ggplot() +
  geom_linerange(data=miss_gages_df2 %>% filter(total_post1980>0),
                 aes(x=ID, ymin=date_begin, ymax=date_end, color=total_post1980),
                 show.legend = T, size=1) +
  geom_hline(yintercept = ymd("1979-10-01"), color="maroon", lty=2, lwd=1.2)+
  coord_flip() +
  scale_color_viridis_c("Total Years\n post-1980")+
  ggdark::dark_theme_classic() +
  labs(x="", y="", subtitle="FFC Altered Gages that didn't run (due to missing data/gaps), but have data post 1980 (n=133)",
       caption="From original altered list (n=814)")

#save
ggsave(filename = "figures/ffc_altered_missing_but_data_post1980.png",
       width = 10, height = 8, dpi = 300, units = "in")

# find gages with less than 10 years of data
miss_10 <- miss_gages_df2 %>%
  filter(total_yrs<10 |
         total_post1980<10)

#mapview(miss_10, zcol="total_yrs")

miss_g10 <- miss_gages_df2 %>% filter(total_yrs>9 & total_post1980>9)

#mapview(miss_g10, zcol="total_post1980")

# replot only gages with 10 or more years after 1980
ggplot() +
  geom_linerange(data=miss_g10,
                 aes(x=ID, ymin=date_begin, ymax=date_end, color=total_post1980),
                 show.legend = T, size=1) +
  #geom_text(data=miss_g10, aes(x=ID, label=ID, y=date_begin), size=2.5) +
  geom_hline(yintercept = ymd("1979-10-01"), color="maroon")+
  coord_flip() +
  #ylim(c(ymd("1979-10-01"),ymd("2020-10-01")))+
  scale_color_viridis_c("Total Years\n post-1980")+
  ggdark::dark_theme_classic() +
  labs(x="", y="", subtitle="FFC Altered Gages that didn't run with 9> years data after 1980",
       caption="From original altered list (n=814)")

ggsave(filename = "figures/ffc_altered_gages_w+10yrs_post1980.png", width = 11, height = 8.5, units = "in", dpi=300)
