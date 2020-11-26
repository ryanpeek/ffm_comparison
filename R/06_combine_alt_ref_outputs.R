# Combine FFC alt and ref
# take ffc combined data from alt and ref and bind together into single file
# useful for broad analysis across ref/alt gages

# Libraries ---------------------------------------------------------------

options(tidyverse.quiet = TRUE)
library(tidyverse) # load quietly
library(conflicted) # deals with conflicting functions
conflict_prefer("filter", "dplyr")
library(glue) # good for pasting things together
library(fs)
library(lubridate)

# Setup Directory ---------------------------------------------------------

# get dir
ffc_dir <- glue("output/ffc_combined")
ffc_files <- dir_ls(ffc_dir, type = "file", regexp = "*.csv")


# Function To Combine -----------------------------------------------------

# function to read and combine the data
ffc_combine_alt_ref <- function(datatype, fdir){
  datatype = datatype
  ffc_files = dir_ls(path = fdir, type = "file", regexp = "*.csv")
  csv_list = ffc_files[grepl(glue("(alt|ref)_{datatype}_run*"), ffc_files)]
  # read in all
  df <- purrr::map(csv_list, ~read_csv(.x)) %>%
    # check and fix char vs. num
    map(~mutate_at(.x, 'gageid', as.character)) %>%
    bind_rows()
  # write out
  write_csv(df, file = glue("{fdir}/usgs_combined_{datatype}.csv"))
  write_rds(df, file = glue("{fdir}/usgs_combined_{datatype}.rds"), compress = "gz")

  return(df)
}

# Combine FFC: predicted_percentiles --------------------------------------

# set the data type:
datatype <- "predicted_percentiles"

# combine
df_ffc <- ffc_combine_alt_ref(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()

# how many records per gage?
df_ffc %>% group_by(gageid) %>%
  tally() #%>% View()


# Combine FFC: alteration -------------------------------------------------

# set the data type:
datatype <- "alteration"

# combine
df_ffc <- ffc_combine_alt_ref(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% filter(n>23) %>% View() # view

# Combine FFC: ffc_percentiles --------------------------------------------

# set the data type:
datatype <- "ffc_percentiles"

# combine
df_ffc <- ffc_combine_alt_ref(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many records per gage?
df_ffc %>% group_by(gageid) %>% tally()

# Combine FFC: ffc_results ------------------------------------------------

# set the data type:
datatype <- "ffc_results"

# combine
df_ffc <- ffc_combine_alt_ref(datatype, fdir = ffc_dir)

# view how many USGS gages
df_ffc %>% distinct(gageid) %>% count()
# how many years per gage?
df_ffc %>% group_by(gageid) %>% tally() #%>% View()

# FOR ffc_results: Pivot Longer
df_ffc_long <- df_ffc %>%
  pivot_longer(cols=!c(Year,gageid),
               names_to="ffm_name",
               values_to="value") %>%
  rename(year=Year) %>%
  mutate(ffc_version="v1.1_api") %>%
  filter(!is.na(value))

# save it
write_csv(df_ffc_long, file = glue("{fdir}/usgs_combined_{datatype}_long.csv"))
write_rds(df_ffc_long, file = glue("{fdir}/usgs_combined_{datatype}_long.rds"), compress = "gz")


