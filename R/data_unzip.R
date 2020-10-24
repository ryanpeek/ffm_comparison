##' .. content for \description{unzip data from .zip folder}
##' .. content for \details{takes compressed folder and splits into stream classes each with a csv} ..
##' @title unzip data
##' @param ffc_version
##' @param
##' @return
##' @author Ryan Peek
##' @export
data_unzip <- function(ffc_version){
    # ls zip files
    zips <- fs::dir_ls("data", type = "file", glob = "*.zip")
    # set basefolder name
    basefolder <- path_ext_remove(zips[grepl(pattern = ffc_version, zips)])
    # unzip
    if(!fs::dir_exists(basefolder)){
      unzip(zipfile = glue("{basefolder}.zip"), exdir = "data", overwrite = FALSE)
    } else{ print("Already unzipped")}
}

