capture <- function(x, name, location = NULL) {
  # Create directory if it doesn't exist
  dir.create(location, showWarnings = FALSE, recursive = TRUE)

  # Construct full file path

  file_path <- file.path(location, paste0(name, ".rds"))

  # Save the object
  saveRDS(x, file_path)

  # Return the saved object invisibly
  invisible(x)
}
