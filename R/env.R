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
