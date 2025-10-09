#' Get current datetime
#' @return Current datetime as an ISO 8601 formatted character string
#' @export
now <- function() {
  format(lubridate::now(), "%Y-%m-%dT%H:%M:%S%z")
}
