


#devtools::install_github("markwh/streamstats")## I have heard it is rude to leave an install commands in script, sorry

library(streamstats)
library(sf)
library(leaflet)

McKee <- delineateWatershed(xlocation = -123.924, ylocation = 39.993, crs = 4326,
                            includeparameters = "true", includefeatures = "true")
McKee$parameters

# make a map
leafletWatershed(McKee) #%>%
  setView(lng = -123.924, 39.993, zoom = 12)

# see what features are avail
# streamstats::availFeatures(McKee$workspaceID)

# pull just features
feats <- getFeatures(McKee$workspaceID, rcode = "CA", crs = 4326)

# get just table of parameters
df <- computeChars(McKee$workspaceID, rcode = "CA")
df$parameters

# download GIS
downloadGIS(workspaceID = McKee$workspaceID, file = "data/tst_gdb.zip",  format = "geodatabase")
#downloadGIS(workspaceID = McKee$workspaceID, file = "data/tst_shp.zip",  format = "shapefile")


# unzip
unzip("data/tst_gdb.zip", exdir = "data/tst_gdb")

# path to gdb
filep <- "data/tst_gdb/CA20201106162904151000/CA20201106162904151000.gdb"

st_layers(filep)

pt <- read_sf(filep, layer = "GlobalWatershedPoint")
shed <- read_sf(filep, layer = "GlobalWatershed")


library(mapview)
mapview(pt) + mapview(shed, col.regions="green", alpha.regions=.2)


# Using Geoknife ----------------------------------------------------------


library(geoknife)

## STENCIL

# set up stencil with point
stencil <- simplegeom(c(-123.924, 39.993))

# setup a default stencil by using webgeom and not supplying any arguments
default_stencil <- webgeom()

# now determine what geoms are available with the default
(default_geoms <- query(default_stencil, "geoms"))
stencil_huc <- webgeom('HUC8::18010107')


## FABRIC

# see what data is avail for fabric:
all_webdata <- query("webdata")
all_titles <- title(all_webdata)
which_titles <- grep("evapotranspiration", all_titles)
evap_titles <- all_titles[which_titles]
head(evap_titles)
all_abstracts <- abstract(all_webdata)
which_abstracts <- grep("evapotranspiration", all_abstracts)
evap_abstracts <- all_abstracts[which_abstracts]
evap_abstracts[1]

# pick one
evap_fabric <- webdata(all_webdata["Yearly Conterminous U.S. actual evapotranspiration data"])
class(evap_fabric)

# find variables in fabric
query(evap_fabric, "variables")
variables(evap_fabric) <- "et"
variables(evap_fabric)
query(evap_fabric, "times")



## KNIFE

# setup a default knife by using webprocess and not supplying any arguments
default_knife <- webprocess()

# now determine what web processing algorithms are available with the default
(default_algorithms <- query(default_knife, 'algorithms'))

# change the algorithm to OPeNDAP's subset
# algorithm(default_knife) <- default_algorithms['OPeNDAP Subset']


# SETUP JOB

# create fabric
evap_fabric_info <- list(times = as.POSIXct(c("2013-10-01", "2020-10-01")),
                         variables = "et",
                         url = evap_fabric@url)
evap_fabric <- webdata(evap_fabric_info)

# have stencil already

# create knife (which defaults to weighted)
evap_knife <- webprocess()

# find unweighted algorithm
all_algorithms <- query(evap_knife, 'algorithms')
unw_algorithm <- all_algorithms[grep('unweighted', names(all_algorithms))]
# set knife algorithm to unweighted
algorithm(evap_knife) <- unw_algorithm

# create the geojob
evap_geojob <- geoknife(stencil_huc, evap_fabric, evap_knife)
check(evap_geojob)

evap_data <- result(evap_geojob)
nrow(evap_data)
head(evap_data)

# GET PRECIP
#Create the process
precip_knife <- webprocess() # accept defaults for weighted average

# First find and initiate the fabric
all_webdata <- query("webdata")
all_titles <- title(all_webdata)
which_titles <- grep("Precipitation", all_titles)
(precip_titles <- all_titles[which_titles])
precip_fabric <- webdata(all_webdata["Historical, CCSM4 downscaled with QDM trained with PRISM AN81d v. D1 - Daily Precipitation"])

# Now find/add variables (there is only one)
query(precip_fabric, 'variables')
variables(precip_fabric) <- "pr"
query(precip_fabric, 'times')

# Add times to complete fabric
times(precip_fabric) <- c('1988-10-01', '2002-10-01')

# Create geojob + get results
precip_geojob <- geoknife(stencil_huc, precip_fabric, precip_knife)
wait(precip_geojob, sleep.time = 10) # add `wait` when running scripts
precip_data <- result(precip_geojob)
head(precip_data)



