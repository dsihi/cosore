

#' Parse a file from Harvard Forest HF068 dataset.
#'
#' @param path Data directory path, character
#' @param UTC_offset Offset from UTC in hours, numeric
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @export
parse_d20190415_HF068 <- function(path, UTC_offset) {
  files <- list.files(path, pattern = ".csv$", full.names = TRUE, recursive = TRUE)
  dat <- do.call("rbind", lapply(files, read.csv, stringsAsFactors = FALSE, check.names = FALSE))
  dat$Timestamp <- as.POSIXct(dat$datetime, format = "%Y-%m-%dT%H:%M", tz = "UTC") - UTC_offset * 60 * 60
  dat$datetime <- dat$year <- dat$doy <- dat$hour <- NULL
  # Fill in data given at http://harvardforest.fas.harvard.edu:8080/exist/apps/datasets/showData.html?id=hf068
  dat$Area <- 43.2 ^ 2
  dat$Error <- FALSE
  dat
}

#' Parse a file with timestamp in year-doy-hour format.
#'
#' @param path Data directory path, character
#' @param UTC_offset Offset from UTC in hours, numeric
#' @return A \code{data.frame} containing extracted data.
#' @importFrom utils read.csv
#' @export
parse_IRGA_ydh <- function(path, UTC_offset) {
  files <- list.files(path, pattern = ".csv$", full.names = TRUE, recursive = TRUE)
  dat <- do.call("rbind", lapply(files, read.csv,
                                 na.strings = "-9999", stringsAsFactors = FALSE, check.names = FALSE))
  dat$Timestamp <- as.POSIXct(paste(dat$year, dat$doy, dat$hour),
                              format = "%Y %j %H", tz = "UTC") - UTC_offset * 60 * 60
  dat$year <- dat$doy <- dat$hour <- NULL
  # Fill in data given at https://www.sciencedirect.com/science/article/pii/S0168192312003759
  dat$Area <- 491
  dat$Error <- FALSE
  dat
}
