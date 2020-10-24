
# Compare Data ------------------------------------------------------------
# focus on wet season timing, wet season baseflow (50th, 10th), dry season baseflow (50th, 90th), and fall pulse magnitude and timing (within different stream classes).  These are the metrics that will be most affected by a change in wet season timing

# Load Data ---------------------------------------------------------------

combine_data <- function(){

  if(!fs::file_exists(glue("{here()}/output/ffm_combined_tidy.fst"))){
    # get paths
    base_data_dir <- glue("{here()}/output/")
    rda_files <- dir(path = base_data_dir, pattern='*.rda$', recursive = T, full.names = T)
    # load data
    map(rda_files, ~load(.x, envir = .GlobalEnv))

    # Bind into Single Dataset ------------------------------------------------

    # makes plotting easier
    df_all <- bind_rows(v2019, v2020) %>%
      mutate(ffc_version=factor(version)) %>% select(-version)

    # save out
    #save(df_all, file = glue("{base_data_dir}/ffm_combined_tidy.rda"))
    write_fst(x = df_all, path = glue("{base_data_dir}/ffm_combined_tidy.fst"), compress = 100)
    return(df_all)
  }
  else{
    print("Already exists!")
    dat <- read_fst(path = glue("{here::here()}/output/ffm_combined_tidy.fst"))
    print("Data loaded into local environment")
    assign(x = "df_all", value = dat, envir = .GlobalEnv)
    }
}

