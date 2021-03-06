# File parsing routines (internal)

#' Parse labels from information files
#'
#' @param file_data Character vector of file lines
#' @param line_label Character label
#' @param numeric_data Numeric data? Logical
#' @param sep Separator
#' @note If label is not found, produces an error (if label was required) or returns
#' \code{NA} (if not).
#' @keywords internal
#' @return Value (character) of data opposite label
extract_line <- function(file_data, line_label,
                         required = TRUE, sep = ":", numeric_data = FALSE) {
  rx <- paste0("^", line_label, sep)
  fd <- file_data[grep(rx, file_data)]
  if(length(fd) > 1) {
    #  browser()
    stop(length(fd), " entries found for required label ", line_label)
  }
  if(required & length(fd) == 0) {
    stop("No entries found for required label ", line_label)
  }
  if(!required & length(fd) == 0) {
    return(NA_character_)
  }

  d <- trimws(gsub(rx, "", fd))
  if(length(d) == 0) d <- NA_character_

  if(numeric_data) {
    dn <- suppressWarnings(as.numeric(d))
    if(d != "" & is.na(dn)) {
      stop(d, " could not be converted to numeric for ", line_label)
    }
    dn
  } else {
    d
  }
}


#' List available datasets
#'
#' @param path Path name
#' @return Character vector of datasets.
#' @export
#' @examples
#' list_datasets()
list_datasets <- function(path = resolve_dataset("")) {
  ds <- list.files(path)
  ds[grep("^d[0-9]{8}_", ds)]  # dataset folders start with "d" followed by eight numbers
}

#' Get the full path of a dataset folder(s)
#'
#' @param dataset_name Dataset name(s), character
#' @export
#' @return Fully-qualified filename(s) of dataset folder in \code{inst/extdata}
#'  (\code{extdata/} in built package).
resolve_dataset <- function(dataset_name) {
  system.file(file.path("extdata", dataset_name), package = "cosore", mustWork = TRUE)
}


#' Read a text file and strip out comments
#'
#' @param dataset_name Dataset name, character
#' @param file_name File name, character
#' @param file_data File data, character vector; optional for testing
#' @param comment_char Start-of-line comment character
#' @keywords internal
#' @return Contents of file in a character vector.
read_file <- function(dataset_name, file_name, file_data = NULL, comment_char = "#") {
  if(is.null(file_data)) {
    file_data <- readLines(file.path(resolve_dataset(dataset_name), file_name))
  }
  file_data[grep(paste0("^", comment_char), file_data, invert = TRUE)]
}


#' Read dataset DESCRIPTION file
#'
#' @param dataset_name Dataset name, character
#' @param file_data File data, character vector; optional for testing
#' @keywords internal
#' @return A \code{data.frame} with the following columns:
#' \item{Dataset}{Dataset name, character}
#' \item{Site_name}{Site name, character}
#' \item{Longitude}{Decimal Longitude, numeric}
#' \item{Latitude}{Decimal latitude, numeric}
#' \item{Instrument}{Instrument type, character}
#' \item{Ecosystem_type}{Ecosystem type, character}
#' \item{Primary_pub}{Primary publication, character}
#' \item{Other_pubs}{Other publications, character}
read_description_file <- function(dataset_name, file_data = NULL) {
  file_data <- read_file(dataset_name, "DESCRIPTION.txt", file_data = file_data)

  d <- data.frame(Site_name = extract_line(file_data, "Site_name"),
                  Longitude = extract_line(file_data, "Longitude", numeric_data = TRUE),
                  Latitude = extract_line(file_data, "Latitude", numeric_data = TRUE),
                  Elevation = extract_line(file_data, "Elevation", numeric_data = TRUE),
                  UTC_offset = extract_line(file_data, "UTC_offset", numeric_data = TRUE),
                  IGBP = extract_line(file_data, "IGBP"),
                  Instrument = extract_line(file_data, "Instrument"),
                  Primary_pub = extract_line(file_data, "Primary_pub", required = FALSE),
                  Other_pubs = extract_line(file_data, "Other_pub", required = FALSE),
                  Data_URL = extract_line(file_data, "Data_URL", required = FALSE),
                  Acknowledgment = extract_line(file_data, "Acknowledgment", required = FALSE),
                  stringsAsFactors = FALSE)

  if(is.na(d$UTC_offset) | d$UTC_offset == "" | abs(d$UTC_offset) >= 15) {
    stop("Bad UTC_offset in ", dataset_name)
  }
  d
}


#' Read dataset CONTRIBUTORS file
#'
#' @param dataset_name Dataset name, character
#' @param file_data File data, character vector; optional for testing
#' @keywords internal
#' @note For information about ORCID see \url{https://orcid.org}. For
#' CRediT roles, see \url{https://www.casrai.org/credit.html}.
#' @return A \code{data.frame} with the following columns:
#' \item{First_name}{Site name, character}
#' \item{Family_name}{Decimal Longitude, numeric}
#' \item{Email}{Decimal latitude, numeric}
#' \item{ORCID}{Instrument type, character}
#' \item{Role}{Role, character}
read_contributors_file <- function(dataset_name, file_data = NULL) {
  file_data <- read_file(dataset_name, "CONTRIBUTORS.txt", file_data)
  read_csv_data(file_data, required = c("First_name", "Family_name"))
}


#' Read comma-separated data from a character vector
#'
#' @param file_data File data to read, character vector
#' @param required Vector of column names that must be all filled in, optional
#' @return A data frame with loaded data.
#' @keywords internal
read_csv_data <- function(file_data, required = NULL) {
  x <- read.csv(textConnection(file_data), strip.white = TRUE, stringsAsFactors = FALSE)
  for(req in required) {
    if(!req %in% colnames(x)) {
      stop(req, " is not a column name")
    }
    empty <- which(is.na(x[[req]]) | x[[req]] == "")
    if(length(empty)) {
      stop("Column ", req, " is required but has empty entries: ", empty)
    }
  }
  x
}


#' Read dataset PORTS file
#'
#' @param dataset_name Dataset name, character
#' @param file_data File data, character vector; optional for testing
#' @keywords internal
#' @return A \code{data.frame} with the following columns:
#' \item{Port}{Port number, numeric; 0 = all ports}
#' \item{Treatment}{Treatment, character; by default "None"}
#' \item{Species}{Species, character}
read_ports_file <- function(dataset_name, file_data = NULL) {
  file_data <- read_file(dataset_name, "PORTS.txt", file_data)
  read_csv_data(file_data, required = c("Port", "Treatment"))
}


#' Read dataset COLUMNS file
#'
#' @param dataset_name Dataset name, character
#' @param file_data File data, character vector; optional for testing
#' @keywords internal
#' @return A \code{data.frame} with the following columns:
#' \item{Database}{Database column name, character}
#' \item{Dataset}{Dataset column name, character}
#' \item{Computation}{Optional computation R-parseable to perform, character}
#' \item{Port}{Optional port number, integer}
#' \item{Notes}{Optional notes, character}
read_columns_file <- function(dataset_name, file_data = NULL) {
  file_data <- read_file(dataset_name, "COLUMNS.txt", file_data)
  read_csv_data(file_data, required = c("Database", "Dataset"))
}

#' Read dataset ANCILLARY file
#'
#' @param dataset_name Dataset name, character
#' @param file_data File data, character vector; optional for testing
#' @keywords internal
#' @importFrom utils read.csv
#' @note This is simply a comma-separated table.
#' @return A \code{data.frame} containing any data in the file.
read_ancillary_file <- function(dataset_name, file_data = NULL) {
  file_data <- read_file(dataset_name, "ANCILLARY.txt", file_data)
  read_csv_data(file_data)
}


#' Map data columns to new names/values.
#'
#' @param dat Dataset data, a \code{data.frame}
#' @param columns Column mapping data from the \code{COLUMNS.txt} file, a \code{data.frame}
#' @return The \code{dat} data frame with column names transformed, and possibly
#' computed, as defined by \code{columns}.
#' @export
#' @examples
#' dat <- data.frame(x = 1:3)
#' columns <- data.frame(Database = "y", Dataset = "x", Computation = "x * 2")
#' map_columns(dat, columns)  # produces a data.frame(y = c(2, 4, 6))
map_columns <- function(dat, columns) {
  if(is.data.frame(dat) & is.data.frame(columns)) {

    if(!"Computation" %in% names(columns)) {
      columns$Computation <- NA_character_
    }

    # As usual, factors screw things up, so make sure not dealing with them
    columns$Database <- as.character(columns$Database)
    columns$Dataset <- as.character(columns$Dataset)
    columns$Computation <- as.character(columns$Computation)

    for(col in seq_len(nrow(columns))) {
      dbcol <- columns$Database[col]
      dscol <- columns$Dataset[col]
      comp <- columns$Computation[col]

      # Apply map/computation
      if(!dscol %in% names(dat)) {
        stop("Column ", dscol, " not found in data")
      }
      stopifnot(dscol != dbcol)
      if(is.na(comp) | comp == "") {
        message(dbcol, " <- ", dscol)
        names(dat)[which(names(dat) == dscol)] <- dbcol  # rename
      } else {
        message(dbcol, " <- ", comp)
        dat[[dbcol]] <- with(dat, eval(parse(text = comp)))
        dat[[dscol]] <- NULL  # remove original column
      }
    }
  }
  dat
}

#' Read a complete dataset
#'
#' @param dataset_name Dataset name, character
#' @param raw_data Path to the raw data folder (not in package)
#' @param log Log messages? Logical
#' @return A list with (at least) elements:
#' \item{description}{Contents of \code{DESCRIPTION.txt} file}
#' \item{contributors}{Contents of \code{CONTRIBUTORS.txt} file}
#' \item{ports}{Contents of \code{PORTS.txt} file}
#' \item{data}{Continuous soil respiration data, parsed into a \code{data.frame}}
#' \item{ancillary}{Ancillary site information}
#' @export
#' @examples
#' read_dataset("TEST_licordata")
read_dataset <- function(dataset_name, raw_data, log = TRUE) {

  dataset <- list(dataset_name = dataset_name,
                  description = read_description_file(dataset_name),
                  contributors = read_contributors_file(dataset_name),
                  ports = read_ports_file(dataset_name),
                  columns = read_columns_file(dataset_name),
                  ancillary = read_ancillary_file(dataset_name)
  )

  # Parse the actual data
  # Test data live inside the package, in a data/ subdirectory, but generally
  # we look in raw_data/ which is supplied by the user (external to the package)
  if(missing(raw_data)) {
    df <- file.path(resolve_dataset(dataset_name), "data")
  } else {
    df <- file.path(raw_data, dataset_name)
  }

  if(log) {
    # tf <- tempfile()
    # zz <- file(tf, open = "wt")
    # sink(zz, type = "output")
    # sink(zz, type = "message")
  }

  if(!dir.exists(df)) {
    message("No data folder found for ", dataset_name)
    dataset$description$Records <- 0
    return(dataset)
  }

  # Dispatch to correct parsing function based on instrument name
  utc <- dataset$description$UTC_offset
  ins <- dataset$description$Instrument
  func <- paste0("parse_", ins)
  if(exists(func)) {
    dataset$data <- do.call(func, list(df, utc))
  } else {
    message("Unknown instrument ", ins, " in ", dataset_name)
    dataset$data <- data.frame()
  }

  # Column mapping and computation
  dataset$data <- map_columns(dataset$data, dataset$columns)

  # Remove NA flux records
  dataset$description$Records_removed <- sum(is.na(dataset$data$CSR_FLUX))
  dataset$data <- subset(dataset$data, !is.na(CSR_FLUX))

  if(log) {
    # sink(type = "message")
    # sink(type = "output")
    # dataset$log <- readLines(tf)
    # unlink(tf)
  }

  dataset$description$Records <- nrow(dataset$data)
  dataset
}
