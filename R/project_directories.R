#' Add custom directories to an existing project
#'
#' Adds new directories to a project's configuration and creates them on the
#' filesystem. This function is used by the GUI to allow users to add custom
#' directories to their project structure without modifying existing directories.
#'
#' @param project_path Character string. Absolute path to the project root directory.
#' @param key Character string. Internal key for the directory (e.g., "analysis_archive").
#'   Must be unique within the project's directory configuration.
#' @param label Character string. Human-readable label for the directory (e.g., "Analysis Archive").
#' @param path Character string. Relative path where the directory should be created
#'   (e.g., "analysis/archive"). Must be relative, not absolute. Parent directories
#'   will be created as needed.
#'
#' @return List with success status and directory information:
#'   \itemize{
#'     \item \code{success}: Logical indicating whether the operation succeeded
#'     \item \code{directory}: List containing key, label, path, absolute_path, and created flag
#'     \item \code{error}: Character string with error message (only present if success is FALSE)
#'   }
#'
#' @details
#' This function performs the following steps:
#' \enumerate{
#'   \item Validates all input arguments
#'   \item Reads the project's config.yml file
#'   \item Checks for duplicate keys in existing directories
#'   \item Adds the new directory to the directories section
#'   \item Writes the updated config.yml back to disk
#'   \item Creates the directory on the filesystem (with recursive creation)
#' }
#'
#' The function follows a non-destructive, additive-only approach. It will not:
#' \itemize{
#'   \item Rename existing directories
#'   \item Delete existing directories
#'   \item Modify existing directory paths
#'   \item Change the project type
#' }
#'
#' @section Safety:
#' The function includes several safety checks:
#' \itemize{
#'   \item Rejects absolute paths (must be relative)
#'   \item Rejects paths containing ".." (no directory traversal)
#'   \item Checks for duplicate keys before adding
#'   \item Wraps filesystem operations in error handling
#' }
#'
#' @examples
#' \dontrun{
#' # Add a custom directory for archived analyses
#' result <- project_add_directory(
#'   project_path = "/path/to/project",
#'   key = "analysis_archive",
#'   label = "Analysis Archive",
#'   path = "analysis/archive"
#' )
#'
#' if (result$success) {
#'   message("Directory created at: ", result$directory$absolute_path)
#' } else {
#'   warning("Failed to create directory: ", result$error)
#' }
#' }
#'
#' @export
project_add_directory <- function(project_path, key, label, path) {
  # 1. VALIDATE ALL ARGUMENTS
  checkmate::assert_directory_exists(project_path)
  checkmate::assert_string(key, min.chars = 1)
  checkmate::assert_string(label, min.chars = 1)
  checkmate::assert_string(path, min.chars = 1)

  # 2. VALIDATE PATH IS RELATIVE AND SAFE
  if (grepl("^/", path) || grepl("^[A-Z]:", path)) {
    return(list(
      success = FALSE,
      error = sprintf("Path must be relative, not absolute: %s", path)
    ))
  }

  if (grepl("\\.\\.", path)) {
    return(list(
      success = FALSE,
      error = sprintf("Path cannot contain '..': %s", path)
    ))
  }

  # 3. READ PROJECT CONFIG
  config_path <- file.path(project_path, "config.yml")

  if (!file.exists(config_path)) {
    return(list(
      success = FALSE,
      error = sprintf("Project config not found: %s", config_path)
    ))
  }

  tryCatch(
    {
      config <- yaml::read_yaml(config_path)

      # Extract the "default" environment section (config package convention)
      if (!is.null(config$default)) {
        config <- config$default
      }

      # 4. CHECK FOR DUPLICATE KEY
      if (!is.null(config$directories) && key %in% names(config$directories)) {
        return(list(
          success = FALSE,
          error = sprintf("Directory key '%s' already exists in config", key)
        ))
      }

      # 5. ADD DIRECTORY TO CONFIG
      if (is.null(config$directories)) {
        config$directories <- list()
      }

      config$directories[[key]] <- path

      # 6. WRITE CONFIG BACK (wrapped in "default" section for config package)
      write_config <- list(default = config)

      yaml::write_yaml(write_config, config_path)

      # 7. CREATE DIRECTORY ON FILESYSTEM
      absolute_path <- file.path(project_path, path)

      dir_created <- tryCatch(
        {
          dir.create(absolute_path, recursive = TRUE, showWarnings = FALSE)
          TRUE
        },
        error = function(e) {
          # If directory already exists, that's OK
          if (dir.exists(absolute_path)) {
            return(TRUE)
          }
          stop(sprintf("Failed to create directory '%s': %s", absolute_path, e$message))
        }
      )

      # 8. RETURN SUCCESS
      return(list(
        success = TRUE,
        directory = list(
          key = key,
          label = label,
          path = path,
          absolute_path = absolute_path,
          created = dir_created
        )
      ))
    },
    error = function(e) {
      return(list(
        success = FALSE,
        error = sprintf("Failed to add directory: %s", e$message)
      ))
    }
  )
}
