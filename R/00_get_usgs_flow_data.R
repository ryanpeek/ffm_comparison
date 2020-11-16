# pull data

# MFF: 11394500
# MER: 11264500

# Pull raw flow data from USGS --------------------------------------------

library(dataRetrieval)
library(tidyverse)

mff <- dataRetrieval::readNWISdv("11394500", startDate = "1979-10-01", parameterCd = "00060") %>%
  dataRetrieval::addWaterYear() %>%
  dataRetrieval::renameNWISColumns()

plot(mff$Date, mff$Flow, type="l")

mer <- dataRetrieval::readNWISdv("11394500", startDate = "1979-10-01", parameterCd = "00060") %>%
  dataRetrieval::addWaterYear() %>%
  dataRetrieval::renameNWISColumns()

plot(mff$Date, mff$Flow, type="l")
