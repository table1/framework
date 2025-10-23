#' Check if settings file exists
#'
#' Checks for settings.yml (preferred) or config.yml (backward compatibility).
#'
#' @param path Optional path to check in (default: current directory)
#' @return TRUE if either file exists, FALSE otherwise
#' @keywords internal
.has_settings_file <- function(path = ".") {
  file.exists(file.path(path, "settings.yml")) || file.exists(file.path(path, "config.yml"))
}

#' Get settings file path
#'
#' Returns path to settings.yml (preferred) or config.yml (backward compatibility).
#'
#' @param path Optional path to check in (default: current directory)
#' @return Path to settings file, or NULL if neither exists
#' @keywords internal
.get_settings_file <- function(path = ".") {
  settings_path <- file.path(path, "settings.yml")
  config_path <- file.path(path, "config.yml")

  if (file.exists(settings_path)) {
    return(settings_path)
  } else if (file.exists(config_path)) {
    return(config_path)
  } else {
    return(NULL)
  }
}

#' Standardize Working Directory for Framework Projects
#'
#' This function helps standardize the working directory when working with
#' framework projects, especially useful in Quarto/RMarkdown documents that
#' may be rendered from subdirectories.
#'
#' @param project_root Character string specifying the project root directory.
#'   If NULL (default), the function will attempt to find it automatically.
#'
#' @return Invisibly returns the standardized project root path.
#'
#' @details
#' The function looks for common framework project indicators:
#' - settings.yml or config.yml file
#' - .Rprofile file
#' - Being in common subdirectories (scratch, work)
#'
#' It sets both the regular working directory and knitr's root.dir option
#' if knitr is available.
#'
#' @examples
#' \dontrun{
#' library(framework)
#' standardize_wd()
#' scaffold()
#' }
#'
#' @export
standardize_wd <- function(project_root = NULL) {
  # If no project root specified, try to find it
  if (is.null(project_root)) {
    current <- getwd()
    
    # Check various patterns to find the R project directory
    search_paths <- list(
      # If we're in scratch or work subdirectory
      list(
        condition = basename(current) %in% c("scratch", "work", "analysis", "reports"),
        path = dirname(current)
      ),
      # If settings file exists in current directory
      list(
        condition = .has_settings_file("."),
        path = current
      ),
      # If settings file exists in parent
      list(
        condition = .has_settings_file(".."),
        path = normalizePath("..")
      ),
      # If settings file exists in grandparent
      list(
        condition = .has_settings_file("../.."),
        path = normalizePath("../..")
      ),
      # If we're in project root and R subdirectory exists
      list(
        condition = .has_settings_file("R"),
        path = file.path(current, "R")
      ),
      # If we can find an .Rprofile in parent directories
      list(
        condition = file.exists("../.Rprofile") && .has_settings_file("../R"),
        path = file.path(dirname(current), "R")
      )
    )
    
    # Try each search pattern
    for (search in search_paths) {
      if (search$condition) {
        project_root <- search$path
        break
      }
    }
    
    # If still not found, check for .Rproj files
    if (is.null(project_root)) {
      rproj_files <- list.files(
        path = c(".", "..", "../.."),
        pattern = "\\.Rproj$",
        full.names = TRUE,
        recursive = FALSE
      )
      
      if (length(rproj_files) > 0) {
        # Use the directory containing the first .Rproj file found
        project_root <- file.path(dirname(rproj_files[1]), "R")
      }
    }
  }
  
  # Validate and set the working directory
  if (!is.null(project_root) && dir.exists(project_root)) {
    # Normalize the path
    project_root <- normalizePath(project_root, mustWork = TRUE)
    
    # Set knitr working directory if available
    if (requireNamespace("knitr", quietly = TRUE)) {
      knitr::opts_knit$set(root.dir = project_root)
    }
    
    # Set the actual working directory
    old_wd <- setwd(project_root)

    # Check for expected files
    if (!.has_settings_file(".")) {
      warning("settings.yml or config.yml not found in standardized directory")
    }
    
  } else {
    # Return NULL silently - let calling function (scaffold) handle the error
    project_root <- NULL
  }
  
  invisible(project_root)
}