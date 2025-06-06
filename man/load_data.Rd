% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_read.R
\name{load_data}
\alias{load_data}
\title{Load data using dot notation path}
\usage{
load_data(path, delim = NULL, ...)
}
\arguments{
\item{path}{Dot notation path to load data (e.g. "source.private.example")}

\item{delim}{Optional delimiter for CSV files ("comma", "tab", "semicolon", "space")}

\item{...}{Additional arguments passed to readr::read_delim}
}
\description{
Load data using dot notation path
}
