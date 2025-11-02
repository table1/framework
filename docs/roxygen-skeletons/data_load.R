#' Load Data from Catalog
#'
#' Load datasets defined in your data catalog (settings/data.yml). Supports
#' CSV and RDS formats with automatic integrity verification, encryption,
#' and caching.
#' 
#'
#' @param name Name of the dataset as defined in settings/data.yml (supports dot-notation like "source.private.my_data")
#' @param verify_hash Verify file integrity against stored hash from framework.db
#' @param cache Cache the loaded data in memory for faster subsequent access
#'
#' @return The loaded dataset as a data.frame or tibble. Encrypted files are automatically
decrypted if sodium package is available.

#'
#' @seealso \code{\link{data_save}}, \code{\link{data_list}}, \code{\link{data_encrypt}}
#'
#' @examples
#'   # Load a simple dataset
#'   df <- data_load("example")
#'   
#'
#' @export
data_load <- function(...) {
  # Implementation
}
