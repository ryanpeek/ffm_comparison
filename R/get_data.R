# read in data

# put with targets?
# https://github.com/wlandau/targets-tutorial

# LIBRARIES ---------------------------------------------------------------

#source("R/packages.R")

# SETUP DATA PATHS --------------------------------------------------------

# pick the old or new version (2019 or 2020)
#ffc_version <- 2019

get_data <- function(ffc_version, returndata=FALSE) {

  # ls zip files
  zips <- fs::dir_ls("data", type = "file", glob = "*.zip")

  # set basefolder name
  basefolder <- path_ext_remove(zips[grepl(pattern = ffc_version, zips)])

  # unzip
  if(!fs::dir_exists(basefolder)){
    unzip(zipfile = glue("{basefolder}.zip"), exdir = "data", overwrite = FALSE)
  } else{ print("Already unzipped")}

  # list all files
  csv_files <- dir(path = basefolder, pattern='*.csv$', recursive = T)

  # READ IN AND CONVERT TO LONG FORMAT
  if(!fs::file_exists(glue("output/{fs::path_file(basefolder)}_tidy_df.fst")) | !fs::file_exists(glue("output/{fs::path_file(basefolder)}_tidy_df.rda"))){

    # create a dataframe to map data into
    dat_long <- tibble(filename = csv_files, version=ffc_version) %>%
      mutate(file_contents = map(filename,
                                 ~ read_csv(file.path(basefolder, .x))),
             dat_long = map(file_contents, ~pivot_longer(.x, cols=!Year, names_to="year", values_to="value"))
      ) %>%
      # here we drop the raw data and unlist everything
      unnest(cols=c(dat_long)) %>% select(-file_contents) %>%
      rename(ffm=Year) # fix funky matrix remnant name

    # quick tidying here to pull out class and gage as independent cols
    df_tidy <- dat_long %>%
      separate(filename, into=c("class","gage"), sep="/", remove=F) %>%
      # clean up last bit of filename from gage
      separate(gage, into=c("gageID"), sep="_", remove=TRUE)

    # Tidy FFM Name and Components ----------------------------------------------

    # get 24 flow component names
    ff_defs <- readxl::read_xlsx("data/Functional_Flow_Metrics_List_and_Definitions_final.xlsx", range = "A1:F25", .name_repair = "universal", trim_ws = TRUE)

    # check names that match, should be 24
    sum(unique(df_tidy$ffm) %in% ff_defs$Flow.Metric.Code)

    # join with the data
    df_trim <- inner_join(df_tidy, ff_defs, by=c("ffm"="Flow.Metric.Code")) %>%
      # fix names
      janitor::clean_names() %>%
      mutate(flow_component = factor(flow_component,
                                     levels = c("Fall pulse flow", "Wet-season baseflow",
                                                "Peak flow", "Spring recession flow",
                                                "Dry-season baseflow")))

    # SAVE IT OUT -------------------------------------------------------------

    # fix name
    assign(x = glue("v{ffc_version}"), value = df_trim, envir = .GlobalEnv)

    # write a compressed and zipped csv
    #write_csv(df_trim, file = glue("{here::here()}/output/{fs::path_file(basefolder)}_tidy_df.csv.gz"))

    # write a compressed .RData version
    save(list = glue("v{ffc_version}"), file = glue("{here::here()}/output/{fs::path_file(basefolder)}_tidy_df.rda"))
    # write a compressed .fst version
    fst::write_fst(x=get(glue("v{ffc_version}")), path = glue("{here::here()}/output/{fs::path_file(basefolder)}_tidy_df.fst"), compress=100)

    # return
    print("Data loaded into local environment")
  }
  else{
    print("Already updated")
    if(returndata==TRUE){
      # with fst
      dat <- fst::read_fst(path = glue("{here::here()}/output/{fs::path_file(basefolder)}_tidy_df.fst"))
      # with rda
      #load(file = glue("{here::here()}/output/{fs::path_file(basefolder)}_tidy_df.rda"))
      print("Data loaded into local environment")
      assign(x = glue("v{ffc_version}"), value = dat, envir = .GlobalEnv)
      #assign(x = glue("v{ffc_version}"), value = get(glue("v{ffc_version}")), envir = .GlobalEnv)
    }
  }
}


# # Work old data:
# v2019 <- get_data(2019)
# v2020 <- get_data(2020)
