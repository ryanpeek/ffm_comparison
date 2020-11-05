library(readr)
library(ffcAPIClient)
library(purrr)
library(glue)

# write a function to pull the data
ffc_iter <- function(id, startDate, save=TRUE){
  if(save==TRUE){
    # start ffc processor
    ffc <- FFCProcessor$new()
    # setup
    ffc$gage_start_date = startDate
    ffc$set_up(gage_id = id, token=ffctoken)
    ffc$run()
    # write out
    write_csv(ffc$alteration, file = glue::glue("output/ffc/{id}_alteration.csv"))
    write_csv(ffc$ffc_results, file = glue::glue("output/ffc/{id}_ffc_results.csv"))
    write_csv(ffc$ffc_percentiles, file=glue::glue("output/ffc/{id}_ffc_percentiles.csv"))
    write_csv(ffc$predicted_percentiles, file=glue::glue("output/ffc/{id}_predicted_percentiles.csv"))
    #save(ffc, file = glue::glue("output/ffc/{id}_rdata_ffc.rda"))
  } else {
    # start ffc processor
    ffc <- FFCProcessor$new()
    # setup
    ffc$gage_start_date = startDate
    ffc$set_up(gage_id = id, token=ffctoken)
    ffc$run()
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

