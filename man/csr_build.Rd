% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plan.R
\name{csr_build}
\alias{csr_build}
\title{Build the cosore dataset.}
\usage{
csr_build(raw_data)
}
\arguments{
\item{raw_data}{The raw data folder to use, character path}
}
\value{
The drake plan.
}
\description{
Build the cosore dataset.
}
\examples{
csr_build("")  # build without raw data; metadata only
\dontrun{
csr_build("../rawdata/")  # build with raw data
}
}
