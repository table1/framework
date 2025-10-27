#' Show Framework project status
#'
#' Displays comprehensive information about the current Framework project including:
#' - Framework package version
#' - Project configuration
#' - Git status
#' - AI assistant configuration
#' - Git hooks status
#' - Package dependencies
#' - Directory structure
#'
#' @export
#' @examples
#' \dontrun{
#' status()
#' }
status <- function() {
  # Check if we're in a Framework project
  if (!.has_settings_file()) {
    stop("Not in a Framework project directory (settings.yml or config.yml not found)")
  }

  cat("\n")
  cat("\033[1;34m")  # Bold blue
  cat("═══════════════════════════════════════════════════\n")
  cat("  FRAMEWORK PROJECT STATUS\n")
  cat("═══════════════════════════════════════════════════\n")
  cat("\033[0m")  # Reset
  cat("\n")

  # Framework version
  cat("\033[1;33m")  # Bold yellow
  cat("Framework:\n")
  cat("\033[0m")  # Reset
  fw_version <- as.character(packageVersion("framework"))
  cat(sprintf("  Version: %s\n", fw_version))
  cat("\n")

  # Project info
  config <- tryCatch(read_config(), error = function(e) NULL)
  if (!is.null(config)) {
    cat("\033[1;33m")  # Bold yellow
    cat("Project:\n")
    cat("\033[0m")  # Reset

    if (!is.null(config$project_type)) {
      cat(sprintf("  Type: %s\n", config$project_type))
    }

    if (!is.null(config$author$name)) {
      cat(sprintf("  Author: %s\n", config$author$name))
    }

    if (!is.null(config$default_notebook_format)) {
      cat(sprintf("  Notebook format: %s\n", config$default_notebook_format))
    }

    cat("\n")
  }

  # Git status
  cat("\033[1;33m")  # Bold yellow
  cat("Git:\n")
  cat("\033[0m")  # Reset

  git_available <- tryCatch({
    system("git rev-parse --git-dir", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0
  }, error = function(e) FALSE)

  if (git_available) {
    # Check if there are commits
    has_commits <- tryCatch({
      system("git rev-parse HEAD", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0
    }, error = function(e) FALSE)

    if (has_commits) {
      # Get current branch
      branch <- tryCatch({
        trimws(system("git branch --show-current", intern = TRUE, ignore.stderr = TRUE))
      }, error = function(e) "unknown")

      # Get commit count
      commit_count <- tryCatch({
        as.integer(system("git rev-list --count HEAD", intern = TRUE, ignore.stderr = TRUE))
      }, error = function(e) 0)

      # Get uncommitted changes count
      status_result <- tryCatch({
        system("git status --porcelain", intern = TRUE, ignore.stderr = TRUE)
      }, error = function(e) character(0))

      uncommitted <- length(status_result)

      cat(sprintf("  Branch: %s\n", branch))
      cat(sprintf("  Commits: %d\n", commit_count))

      if (uncommitted > 0) {
        cat(sprintf("  \033[1;31mUncommitted changes: %d\033[0m\n", uncommitted))
      } else {
        cat("  \033[0;32mWorking tree clean\033[0m\n")
      }
    } else {
      cat("  \033[1;31mNo commits yet\033[0m\n")
    }
  } else {
    cat("  Not a git repository\n")
  }

  cat("\n")

  # AI assistants
  if (!is.null(config) && !is.null(config$ai)) {
    cat("\033[1;33m")  # Bold yellow
    cat("AI Assistants:\n")
    cat("\033[0m")  # Reset

    ai_files <- c()
    if (file.exists("CLAUDE.md")) ai_files <- c(ai_files, "CLAUDE.md")
    if (file.exists("AGENTS.md")) ai_files <- c(ai_files, "AGENTS.md")
    if (file.exists(".github/copilot-instructions.md")) {
      ai_files <- c(ai_files, ".github/copilot-instructions.md")
    }

    if (length(ai_files) > 0) {
      cat(sprintf("  Files: %s\n", paste(ai_files, collapse = ", ")))

      if (!is.null(config$ai$canonical_file)) {
        cat(sprintf("  Canonical: %s\n", config$ai$canonical_file))
      }
    } else {
      cat("  No AI instruction files found\n")
    }

    cat("\n")
  }

  # Git hooks
  if (git_available && file.exists(".git/hooks/pre-commit")) {
    cat("\033[1;33m")  # Bold yellow
    cat("Git Hooks:\n")
    cat("\033[0m")  # Reset

    if (!is.null(config) && !is.null(config$git) && !is.null(config$git$hooks)) {
      hooks <- config$git$hooks

      if (!is.null(hooks$ai_sync)) {
        status <- if (isTRUE(hooks$ai_sync)) "\033[0;32menabled\033[0m" else "disabled"
        cat(sprintf("  AI sync: %s\n", status))
      }

      if (!is.null(hooks$data_security)) {
        status <- if (isTRUE(hooks$data_security)) "\033[0;32menabled\033[0m" else "disabled"
        cat(sprintf("  Data security: %s\n", status))
      }
    }

    cat("\n")
  }

  # renv status
  cat("\033[1;33m")  # Bold yellow
  cat("Package Management:\n")
  cat("\033[0m")  # Reset

  if (file.exists("renv.lock")) {
    cat("  \033[0;32mrenv: enabled\033[0m\n")
  } else {
    cat("  renv: disabled\n")
  }

  cat("\n")

  # Directories
  if (!is.null(config) && !is.null(config$directories)) {
    cat("\033[1;33m")  # Bold yellow
    cat("Directories:\n")
    cat("\033[0m")  # Reset

    dirs <- config$directories
    for (name in names(dirs)) {
      path <- dirs[[name]]
      exists <- dir.exists(path)
      status <- if (exists) "\033[0;32m✓\033[0m" else "\033[1;31m✗\033[0m"
      cat(sprintf("  %s %s → %s\n", status, name, path))
    }

    cat("\n")
  }

  # Packages
  if (!is.null(config) && !is.null(config$packages)) {
    cat("\033[1;33m")  # Bold yellow
    cat("Dependencies:\n")
    cat("\033[0m")  # Reset

    packages <- .get_package_requirements(config)
    auto_attached <- sum(sapply(packages, function(p) p$load))
    total <- length(packages)

    cat(sprintf("  Total: %d package%s\n", total, if (total == 1) "" else "s"))
    if (auto_attached > 0) {
      cat(sprintf("  Auto-attached: %d\n", auto_attached))
    }

    cat("\n")
  }

  # Database connections
  if (!is.null(config) && !is.null(config$connections)) {
    cat("\033[1;33m")  # Bold yellow
    cat("Database Connections:\n")
    cat("\033[0m")  # Reset

    conn_names <- names(config$connections)
    for (conn_name in conn_names) {
      conn <- config$connections[[conn_name]]
      if (!is.null(conn$type)) {
        cat(sprintf("  %s (%s)\n", conn_name, conn$type))
      } else {
        cat(sprintf("  %s\n", conn_name))
      }
    }

    cat("\n")
  }

  cat("\033[1;34m")  # Bold blue
  cat("═══════════════════════════════════════════════════\n")
  cat("\033[0m")  # Reset
  cat("\n")

  invisible(NULL)
}
