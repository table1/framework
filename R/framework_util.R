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
#' - config.yml file
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
      # If config.yml exists in current directory
      list(
        condition = file.exists("config.yml"),
        path = current
      ),
      # If config.yml exists in parent
      list(
        condition = file.exists("../config.yml"),
        path = normalizePath("..")
      ),
      # If config.yml exists in grandparent
      list(
        condition = file.exists("../../config.yml"),
        path = normalizePath("../..")
      ),
      # If we're in project root and R subdirectory exists
      list(
        condition = file.exists("R/config.yml"),
        path = file.path(current, "R")
      ),
      # If we can find an .Rprofile in parent directories
      list(
        condition = file.exists("../.Rprofile") && file.exists("../R/config.yml"),
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
    if (!file.exists("config.yml")) {
      warning("config.yml not found in standardized directory")
    }
    
  } else {
    warning(
      "Could not determine project root directory. ",
      "Current directory: ", getwd(), "\n",
      "Consider specifying project_root explicitly."
    )
    project_root <- NULL
  }
  
  invisible(project_root)
}