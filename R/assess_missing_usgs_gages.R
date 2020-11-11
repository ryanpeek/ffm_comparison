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
library(sf)
library(mapview)
library(lubridate)


# Load Data ---------------------------------------------------------------

# vector of all gages that returned NA
miss_gages <- read_lines("output/ffcs_usgs_altered_missing_data.txt")
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

# Map ---------------------------------------------------------------------

#mapview(miss_gages_df, col.regions="maroon")

# Get USGS Metadata -------------------------------------------------------

paramCD <- "00060" # discharge (cfs) (temperature=00010, stage=00065)
dataInterval <- "dv" # daily interval, feed via "service" argument

# get all raw FLOW gages
ca_usgs <- dataRetrieval::whatNWISdata(stateCd="CA", service="dv") #%>%

ca_usgs <- ca_usgs %>% # filter to distinct, "dv"=daily values, and "00003"
  filter(parm_cd == paramCD,
         data_type_cd %in% c("dv"),
         stat_cd == "00003")

# see how many total
ca_usgs %>% distinct(site_no, .keep_all = TRUE) %>% count() # n=2381

# check stats
table(ca_usgs$data_type_cd)
table(ca_usgs$stat_cd)

# so where are duplicates?
ca_usgs %>% group_by(site_no) %>% tally() %>% filter(n>1)

# most of these all appear to be same gages, but record is split in two. A few are duplicates

# TIDY --------------------------------------------------------------------

ca_tidy <- ca_usgs %>%
  # rename cols
  dplyr::rename(interval=data_type_cd, lat = dec_lat_va, lon=dec_long_va,
                huc8=huc_cd, site_id=site_no, date_begin=begin_date,
                date_end=end_date, datum=dec_coord_datum_cd, elev_m=alt_va) %>%
  # drop cols
  select(-(loc_web_ds:access_cd)) %>%
  # filter missing vals
  dplyr::filter(!is.na(lon)) %>% # this is a pond out of Mt Shasta
  sf::st_as_sf(coords=c("lon","lat"), crs=4269, remove=FALSE)

# save out
write_rds(ca_tidy, file = "output/usgs_ca_all_dv_gages.rds")


# Map Together ------------------------------------------------------------

ca_tidy <- read_rds("output/usgs_ca_all_dv_gages.rds")

mapview(ca_tidy) + mapview(miss_gages_df, col.regions="maroon")



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

# basic plot
ggplot() +
  geom_linerange(data=miss_gages_df2 %>% filter(total_post1980>0),
                 aes(x=ID, ymin=date_begin, ymax=date_end, color=total_post1980),
                 show.legend = T, size=1) +
  geom_hline(yintercept = ymd("1979-10-01"), color="maroon", lty=2, lwd=1.2)+
  #geom_text(data=miss_gages_df2, aes(x=ID, label=ID, y=date_begin), size=2) +
  coord_flip() +
  scale_color_viridis_c("Total Years\n post-1980")+
  ggdark::dark_theme_classic() +
  labs(x="", y="")

# find gages with less than 10 years of data
miss_10 <- miss_gages_df2 %>%
  filter(total_yrs<10 |
         total_post1980<10)

mapview(miss_10, zcol="total_yrs")

miss_g10 <- miss_gages_df2 %>% filter(total_post1980>9)

mapview(miss_g10, zcol="total_post1980")


# replot
ggplot() +
  geom_linerange(data=miss_g10,
                 aes(x=ID, ymin=date_begin, ymax=date_end, color=total_post1980),
                 show.legend = T, size=1) +
  geom_text(data=miss_g10, aes(x=ID, label=ID, y=date_begin), size=2.5) +
  geom_hline(yintercept = ymd("1979-10-01"), color="maroon")+
  coord_flip() +
  scale_color_viridis_c()+
  ggdark::dark_theme_classic() +
  labs(x="", y="")

