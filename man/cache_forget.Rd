% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cache_delete.R
\name{cache_forget}
\alias{cache_forget}
\title{Remove a cached value}
\usage{
cache_forget(name, file = NULL)
}
\arguments{
\item{name}{The cache name to remove}

\item{file}{Optional file path of the cache (default: {config$options$data$cache_dir}/{name}.rds)}
}
\description{
Remove a cached value
}
