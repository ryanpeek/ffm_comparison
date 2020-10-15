# workflow!

# PACKAGES
source("R/packages.R")

# FUNCTION TO GET DATA FROM RAW SOURCE AND TIDY
source("R/get_data.R")

get_data(2019, returndata = TRUE)
get_data(2020, returndata = FALSE)


# FUNCTION TO COMBINE VERSIONS (2019 and 2020) INTO SINGLE DATAFRAME
source("R/combine_data.R") # automatically loads data

# DOC
# see the Rmd
