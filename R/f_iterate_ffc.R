library(readr)
library(ffcAPIClient)
library(purrr)
library(glue)
library(fs)
library(here)

# write a function to pull the data
ffc_iter <- function(id, startDate, ffctoken=ffctoken, dirToSave="output/ffc", save=TRUE){

  # set save dir
  outDir <- glue::glue("{here()}/{dirToSave}")

  # set special parameters for this run of the FFC
  ffc <- FFCProcessor$new()
  ffc$gage_start_date = startDate
  ffc$warn_years_data = 12
  ffc$fail_years_data = 10
  # run the FFCProcessor's setup code, then run the FFC itself
  ffc$set_up(gage_id = id, token=ffctoken)
  capture.output(ffc$run(), file = glue::glue("{outDir}/{id}_logfile.txt"), append = TRUE)

  if(save==TRUE){
    dir_create(glue("{outDir}"))
    # write out
    write_csv(ffc$alteration, file = glue::glue("{outDir}/{id}_alteration.csv"))
    write_csv(ffc$ffc_results, file = glue::glue("{{outDir}/{id}_ffc_results.csv"))
    write_csv(ffc$ffc_percentiles, file=glue::glue("{outDir}/{id}_ffc_percentiles.csv"))
    write_csv(ffc$predicted_percentiles, file=glue::glue("{outDir}/{id}_predicted_percentiles.csv"))
  } else {
    return(ffc)
  }
}

# wrap in possibly to permit error catching
# see helpful post here: https://aosmith.rbind.io/2020/08/31/handling-errors/
ffc_possible <- possibly(.f = ffc_iter, otherwise = NA_character_)

# iterate
#ffcs <- map(gages$id, ~ffc_possible(.x, startDate = "1979-10-01", save=TRUE)) %>%
  # add names to list
  #set_names(., nm=gages$name)

