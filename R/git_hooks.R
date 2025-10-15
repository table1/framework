#' Install Git Pre-commit Hook
#'
#' Creates a pre-commit hook that runs Framework checks based on config.yml settings.
#'
#' @param config_file Path to configuration file (default: "config.yml")
#' @param force Logical; if TRUE, overwrite existing hook (default: FALSE)
#' @param verbose Logical; if TRUE (default), show installation messages
#'
#' @return Invisible TRUE on success, FALSE on failure
#'
#' @details
#' Creates or updates `.git/hooks/pre-commit` to run enabled Framework hooks:
#' \itemize{
#'   \item **ai_sync**: Sync AI assistant context files before commit
#'   \item **data_security**: Run security audit to catch data leaks
#' }
#'
#' Hook behavior is controlled by `git.hooks.*` settings in config.yml.
#'
#' @examples
#' \dontrun{
#' # Install hooks based on config.yml
#' hooks_install()
#'
#' # Force reinstall (overwrites existing hook)
#' hooks_install(force = TRUE)
#' }
#'
#' @export
hooks_install <- function(config_file = "config.yml",
                         force = FALSE,
                         verbose = TRUE) {

  # Check if git repo
  if (!.is_git_repo()) {
    if (verbose) {
      message("✗ Not a git repository")
    }
    return(invisible(FALSE))
  }

  # Check if config exists
  if (!file.exists(config_file)) {
    if (verbose) {
      message("✗ Config file not found: ", config_file)
    }
    return(invisible(FALSE))
  }

  # Read hook configuration
  ai_sync_enabled <- config("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security_enabled <- config("git.hooks.data_security", config_file = config_file, default = FALSE)

  if (!ai_sync_enabled && !data_security_enabled) {
    if (verbose) {
      message("ℹ No hooks enabled in config.yml")
      message("  Enable with: config$git$hooks$ai_sync = TRUE")
    }
    return(invisible(FALSE))
  }

  # Create .git/hooks directory if needed
  hooks_dir <- ".git/hooks"
  if (!dir.exists(hooks_dir)) {
    dir.create(hooks_dir, recursive = TRUE)
  }

  hook_path <- file.path(hooks_dir, "pre-commit")

  # Check if hook already exists
  if (file.exists(hook_path) && !force) {
    if (verbose) {
      message("✗ Pre-commit hook already exists")
      message("  Use force=TRUE to overwrite or edit .git/hooks/pre-commit manually")
    }
    return(invisible(FALSE))
  }

  # Generate hook script
  hook_script <- .generate_hook_script(ai_sync_enabled, data_security_enabled)

  # Write hook
  tryCatch({
    writeLines(hook_script, hook_path)
    Sys.chmod(hook_path, mode = "0755")  # Make executable

    if (verbose) {
      message("✓ Installed pre-commit hook")
      if (ai_sync_enabled) {
        message("  • AI context sync enabled")
      }
      if (data_security_enabled) {
        message("  • Data security check enabled")
      }
    }

    invisible(TRUE)
  }, error = function(e) {
    if (verbose) {
      message("✗ Failed to install hook: ", e$message)
    }
    invisible(FALSE)
  })
}


#' Uninstall Git Pre-commit Hook
#'
#' Removes the Framework-managed pre-commit hook.
#'
#' @param verbose Logical; if TRUE (default), show messages
#'
#' @return Invisible TRUE if hook was removed, FALSE otherwise
#'
#' @export
hooks_uninstall <- function(verbose = TRUE) {
  hook_path <- ".git/hooks/pre-commit"

  if (!file.exists(hook_path)) {
    if (verbose) {
      message("ℹ No pre-commit hook found")
    }
    return(invisible(FALSE))
  }

  # Check if it's a Framework-managed hook
  hook_content <- readLines(hook_path, warn = FALSE)
  is_framework_hook <- any(grepl("Framework Git Hooks", hook_content))

  if (!is_framework_hook) {
    if (verbose) {
      message("⚠ Pre-commit hook exists but not managed by Framework")
      message("  Delete .git/hooks/pre-commit manually if needed")
    }
    return(invisible(FALSE))
  }

  # Remove hook
  tryCatch({
    file.remove(hook_path)
    if (verbose) {
      message("✓ Removed pre-commit hook")
    }
    invisible(TRUE)
  }, error = function(e) {
    if (verbose) {
      message("✗ Failed to remove hook: ", e$message)
    }
    invisible(FALSE)
  })
}


#' Enable Specific Git Hook
#'
#' Enables a specific hook in config.yml and reinstalls the pre-commit hook.
#'
#' @param hook_name Name of hook: "ai_sync" or "data_security"
#' @param config_file Path to configuration file (default: "config.yml")
#' @param verbose Logical; if TRUE (default), show messages
#'
#' @return Invisible TRUE on success
#'
#' @examples
#' \dontrun{
#' hooks_enable("ai_sync")
#' hooks_enable("data_security")
#' }
#'
#' @export
hooks_enable <- function(hook_name, config_file = "config.yml", verbose = TRUE) {
  valid_hooks <- c("ai_sync", "data_security")

  if (!hook_name %in% valid_hooks) {
    stop("Invalid hook name. Must be one of: ", paste(valid_hooks, collapse = ", "))
  }

  # Update config.yml
  .update_hook_config(hook_name, TRUE, config_file)

  if (verbose) {
    message("✓ Enabled ", hook_name, " hook")
  }

  # Reinstall hooks
  hooks_install(config_file = config_file, force = TRUE, verbose = verbose)
}


#' Disable Specific Git Hook
#'
#' Disables a specific hook in config.yml and reinstalls the pre-commit hook.
#'
#' @param hook_name Name of hook: "ai_sync" or "data_security"
#' @param config_file Path to configuration file (default: "config.yml")
#' @param verbose Logical; if TRUE (default), show messages
#'
#' @return Invisible TRUE on success
#'
#' @export
hooks_disable <- function(hook_name, config_file = "config.yml", verbose = TRUE) {
  valid_hooks <- c("ai_sync", "data_security")

  if (!hook_name %in% valid_hooks) {
    stop("Invalid hook name. Must be one of: ", paste(valid_hooks, collapse = ", "))
  }

  # Update config.yml
  .update_hook_config(hook_name, FALSE, config_file)

  if (verbose) {
    message("✓ Disabled ", hook_name, " hook")
  }

  # Reinstall hooks (or uninstall if all disabled)
  ai_sync_enabled <- config("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security_enabled <- config("git.hooks.data_security", config_file = config_file, default = FALSE)

  if (!ai_sync_enabled && !data_security_enabled) {
    hooks_uninstall(verbose = verbose)
  } else {
    hooks_install(config_file = config_file, force = TRUE, verbose = verbose)
  }
}


#' List Git Hook Status
#'
#' Shows which hooks are enabled and their current status.
#'
#' @param config_file Path to configuration file (default: "config.yml")
#'
#' @return Data frame with hook information
#'
#' @export
hooks_list <- function(config_file = "config.yml") {
  if (!file.exists(config_file)) {
    message("✗ Config file not found: ", config_file)
    return(invisible(NULL))
  }

  ai_sync <- config("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security <- config("git.hooks.data_security", config_file = config_file, default = FALSE)

  hook_installed <- file.exists(".git/hooks/pre-commit")

  df <- data.frame(
    hook = c("ai_sync", "data_security"),
    enabled = c(ai_sync, data_security),
    description = c(
      "Sync AI assistant context files",
      "Check for secrets/credentials"
    ),
    stringsAsFactors = FALSE
  )

  message("=== Framework Git Hooks ===\n")
  message("Pre-commit hook: ", if (hook_installed) "installed" else "not installed")
  message("")

  for (i in seq_len(nrow(df))) {
    status_icon <- if (df$enabled[i]) "✓" else "✗"
    message(sprintf("%s %s - %s", status_icon, df$hook[i], df$description[i]))
  }

  message("\nCommands:")
  message("  framework hooks:enable <name>")
  message("  framework hooks:disable <name>")
  message("  framework hooks:install")
  message("  framework hooks:uninstall")

  invisible(df)
}


# Internal helpers --------------------------------------------------------

#' Check if current directory is a git repository
#' @keywords internal
.is_git_repo <- function() {
  dir.exists(".git")
}


#' Generate pre-commit hook script
#' @keywords internal
.generate_hook_script <- function(ai_sync_enabled, data_security_enabled) {
  c(
    "#!/usr/bin/env bash",
    "# Framework Git Hooks",
    "# Managed by Framework - do not edit manually",
    "# Use 'framework hooks:*' commands to configure",
    "",
    "set -e",
    "",
    "# Get project root",
    "PROJECT_ROOT=\"$(git rev-parse --show-toplevel)\"",
    "cd \"$PROJECT_ROOT\"",
    "",
    if (ai_sync_enabled) c(
      "# AI context sync",
      "if ! Rscript -e \"library(framework); ai_sync_context(verbose=FALSE)\"; then",
      "  echo \"✗ AI context sync failed\"",
      "  exit 1",
      "fi",
      ""
    ) else NULL,
    if (data_security_enabled) c(
      "# Data security check",
      "if ! Rscript -e \"library(framework); result <- security_audit(verbose=FALSE); if (any(result\\$summary\\$status == 'fail')) quit(status=1)\"; then",
      "  echo \"✗ Data security check failed\"",
      "  echo \"Run 'framework security:audit' for details\"",
      "  exit 1",
      "fi",
      ""
    ) else NULL,
    "exit 0"
  )
}


#' Update hook configuration in config.yml
#' @keywords internal
.update_hook_config <- function(hook_name, enabled, config_file) {
  if (!file.exists(config_file)) {
    stop("Config file not found: ", config_file)
  }

  # Read config
  config_content <- yaml::read_yaml(config_file)

  # Ensure structure exists
  if (is.null(config_content$default$git)) {
    config_content$default$git <- list()
  }
  if (is.null(config_content$default$git$hooks)) {
    config_content$default$git$hooks <- list()
  }

  # Update hook setting
  config_content$default$git$hooks[[hook_name]] <- enabled

  # Write back
  yaml::write_yaml(config_content, config_file)

  invisible(TRUE)
}
