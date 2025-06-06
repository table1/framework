% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scratch.R
\name{capture}
\alias{capture}
\title{Capture and Save Data to File}
\usage{
capture(x, name = NULL, to = NULL, location = NULL, n = Inf)
}
\arguments{
\item{x}{The object to save}

\item{name}{Optional character string specifying the name of the file (without extension).
If not provided, will use the name of the object passed in.}

\item{to}{Optional character string indicating the output format. One of: "text", "rds", "csv", "tsv".
If not provided, will choose based on object type.}

\item{location}{Optional character string specifying the directory where the file should be saved.
If NULL, uses the scratch directory from the configuration.}

\item{n}{Optional number of rows to capture for data frames (default: all rows)}
}
\value{
The input object \code{x} invisibly.
}
\description{
Saves data to a file in various formats based on the object type and specified format.
If no name is provided, uses the name of the object passed in.
If no location is provided, uses the scratch directory from the configuration.
}
\examples{
# Save a character vector as text
capture(c("hello", "world"))

# Save a data frame as TSV
capture(mtcars)

# Save an R object as RDS
capture(list(a = 1, b = 2), to = "rds")

}
