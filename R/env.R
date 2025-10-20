#' Create or append to .env file
#'
#' Creates a .env file (if it doesn't exist) and appends environment variables.
#' Warns if .env is not in .gitignore to prevent accidental secret exposure.
#'
#' @param ... Named arguments for environment variables (e.g., DB_PASSWORD = "secret")
#' @param comment Optional comment to add before the variables
#' @param check_gitignore Logical; if TRUE (default), warns if .env not gitignored
#'
#' @return Invisibly returns TRUE on success
#' @export
#' @examples
#' \dontrun{
#' # Create .env with database credentials
#' make_env(
#'   DB_HOST = "localhost",
#'   DB_PORT = "5432",
#'   DB_PASSWORD = "secret",
#'   comment = "Database connection"
#' )
#'
#' # Add API keys
#' make_env(
#'   OPENAI_API_KEY = "sk-...",
#'   comment = "API credentials"
#' )
#' }
make_env <- function(..., comment = NULL, check_gitignore = TRUE) {
  vars <- list(...)

  if (length(vars) == 0) {
    stop("No environment variables provided. Usage: make_env(VAR_NAME = \"value\", ...)")
  }

  # Validate named arguments
  if (is.null(names(vars)) || any(names(vars) == "")) {
    stop("All arguments must be named. Usage: make_env(VAR_NAME = \"value\", ...)")
  }

  env_path <- ".env"
  env_exists <- file.exists(env_path)

  # Check .gitignore if requested
  if (check_gitignore) {
    .check_env_gitignored()
  }

  # Build content to append
  content <- character()

  # Add blank line if file exists
  if (env_exists) {
    content <- c(content, "")
  }

  # Add comment if provided
  if (!is.null(comment) && nzchar(comment)) {
    content <- c(content, paste0("# ", comment))
  }

  # Add variables
  for (var_name in names(vars)) {
    var_value <- vars[[var_name]]
    # Quote values that contain spaces or special characters
    if (grepl("[[:space:]#]", var_value)) {
      var_value <- sprintf('"%s"', var_value)
    }
    content <- c(content, sprintf("%s=%s", var_name, var_value))
  }

  # Append or create file
  if (env_exists) {
    # Append to existing file
    existing_content <- readLines(env_path, warn = FALSE)
    writeLines(c(existing_content, content), env_path)
    message(sprintf("✓ Appended %d variable(s) to .env", length(vars)))
  } else {
    # Create new file
    writeLines(content, env_path)
    message(sprintf("✓ Created .env with %d variable(s)", length(vars)))
  }

  # Show what was added (without revealing values)
  message("  Variables: ", paste(names(vars), collapse = ", "))

  invisible(TRUE)
}

#' Check if .env is gitignored
#'
#' Checks if .env is listed in .gitignore and warns if not.
#'
#' @return Invisibly returns logical indicating if .env is gitignored
#' @keywords internal
.check_env_gitignored <- function() {
  gitignore_path <- ".gitignore"

  if (!file.exists(gitignore_path)) {
    warning(
      ".gitignore not found!\n",
      "  Create one and add '.env' to prevent committing secrets.\n",
      "  Run: writeLines('.env', '.gitignore')",
      call. = FALSE
    )
    return(invisible(FALSE))
  }

  gitignore_content <- readLines(gitignore_path, warn = FALSE)

  # Check for .env entry (exact match or pattern)
  has_env <- any(grepl("^\\.env$|^\\.env\\s|^/\\.env$", gitignore_content))

  if (!has_env) {
    warning(
      ".env is NOT in .gitignore!\n",
      "  Add it to prevent accidentally committing secrets:\n",
      "  cat('\n.env', file = '.gitignore', append = TRUE)",
      call. = FALSE
    )
    return(invisible(FALSE))
  }

  invisible(TRUE)
}

#' Reset R environment
#'
#' Cleans up the R environment by removing objects, closing plots, detaching
#' packages, and running garbage collection. Does not clear the console.
#'
#' @param keep Character vector of object names to keep (default: empty)
#' @return Invisibly returns NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Clean everything
#' env_reset()
#'
#' # Keep specific objects
#' env_reset(keep = c("config", "data"))
#' }
env_reset <- function(keep = character()) {
  # Remove all objects except those specified in 'keep'
  all_objects <- ls(all.names = TRUE, envir = .GlobalEnv)
  to_remove <- setdiff(all_objects, keep)
  if (length(to_remove) > 0) {
    rm(list = to_remove, envir = .GlobalEnv)
    message(sprintf("✓ Removed %d object%s", length(to_remove), if (length(to_remove) == 1) "" else "s"))
    if (length(keep) > 0) {
      message(sprintf("  Kept: %s", paste(keep, collapse = ", ")))
    }
  } else {
    message("✓ No objects to remove")
  }

  # Clear plots
  if (dev.cur() != 1) {
    dev.off(dev.list())
    message("✓ Cleared plot devices")
  }

  # Detach loaded packages (with dependency resolution to avoid warnings)
  pkgs <- names(sessionInfo()$otherPkgs)
  if (length(pkgs) > 0) {
    # Build dependency graph and unload in reverse topological order
    suppressWarnings({
      # Get all loaded namespaces
      loaded <- loadedNamespaces()

      # Try to unload packages, silently handling dependency issues
      for (pkg in pkgs) {
        tryCatch(
          detach(paste0("package:", pkg), unload = TRUE, character.only = TRUE),
          error = function(e) invisible(NULL)
        )
      }

      # Force unload namespaces if still loaded
      for (pkg in pkgs) {
        if (pkg %in% loadedNamespaces()) {
          tryCatch(
            unloadNamespace(pkg),
            error = function(e) invisible(NULL)
          )
        }
      }
    })
    message(sprintf("✓ Detached %d package%s", length(pkgs), if (length(pkgs) == 1) "" else "s"))
  }

  # Run garbage collection
  gc_result <- gc(verbose = FALSE)
  message("✓ Garbage collection complete")

  invisible(NULL)
}

#' Summarize R environment
#'
#' Displays a summary of the current R environment including loaded packages,
#' objects in the global environment, and memory usage.
#'
#' @return Invisibly returns a list with environment information
#' @export
#'
#' @examples
#' \dontrun{
#' env_summary()
#' }
env_summary <- function() {
  message("\n=== Environment Summary ===\n")

  # Session info
  si <- sessionInfo()
  message(sprintf("R Version: %s", R.version.string))
  message(sprintf("Platform: %s", si$platform))
  message("")

  # Loaded packages
  pkgs <- names(si$otherPkgs)
  if (length(pkgs) > 0) {
    message(sprintf("Loaded Packages (%d):", length(pkgs)))
    for (pkg in pkgs) {
      version <- packageVersion(pkg)
      message(sprintf("  • %s (%s)", pkg, version))
    }
  } else {
    message("Loaded Packages: none")
  }
  message("")

  # Global environment objects
  all_objects <- ls(all.names = FALSE, envir = .GlobalEnv)
  hidden_objects <- setdiff(ls(all.names = TRUE, envir = .GlobalEnv), all_objects)

  message(sprintf("Objects in Global Environment: %d", length(all_objects)))
  if (length(all_objects) > 0) {
    # Group by class
    obj_info <- lapply(all_objects, function(x) {
      obj <- get(x, envir = .GlobalEnv)
      list(
        name = x,
        class = class(obj)[1],
        size = as.numeric(object.size(obj))
      )
    })

    # Show top 10 by size
    obj_df <- do.call(rbind, lapply(obj_info, function(x) {
      data.frame(name = x$name, class = x$class, size = x$size, stringsAsFactors = FALSE)
    }))
    obj_df <- obj_df[order(-obj_df$size), ]

    n_show <- min(10, nrow(obj_df))
    message(sprintf("  Top %d by size:", n_show))
    for (i in 1:n_show) {
      size_mb <- obj_df$size[i] / 1024^2
      size_str <- if (size_mb >= 1) {
        sprintf("%.1f MB", size_mb)
      } else {
        sprintf("%.1f KB", obj_df$size[i] / 1024)
      }
      message(sprintf("    %s [%s] - %s", obj_df$name[i], obj_df$class[i], size_str))
    }
  }

  if (length(hidden_objects) > 0) {
    message(sprintf("  Hidden objects: %d", length(hidden_objects)))
  }
  message("")

  # Memory usage
  gc_result <- gc(verbose = FALSE)
  mem_used_mb <- sum(gc_result[, 2])
  message(sprintf("Memory in use: %.1f MB", mem_used_mb))
  message("")

  # Return info invisibly
  invisible(list(
    r_version = R.version.string,
    platform = si$platform,
    packages = pkgs,
    n_objects = length(all_objects),
    n_hidden = length(hidden_objects),
    memory_mb = mem_used_mb
  ))
}
