% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/queries.R
\name{db_find}
\alias{db_find}
\title{Find a record by ID}
\usage{
db_find(conn, table_name, id, with_trashed = FALSE)
}
\arguments{
\item{conn}{Database connection}

\item{table_name}{Name of the table to query}

\item{id}{The ID to look up}

\item{with_trashed}{Whether to include soft-deleted records (default: FALSE)}
}
\value{
A data frame with the record, or empty if not found
}
\description{
Finds a single record in a table by its ID.
}
