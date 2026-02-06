# Git Helper Functions ----------------------------------------------------

#' Show Git Status
#'
#' Display the working tree status from the R console.
#'
#' @param short Logical; if TRUE, show short format (default: FALSE)
#'
#' @return Invisibly returns the status output as a character vector
#'
#' @examples
#' \dontrun{
#' git_status()
#' git_status(short = TRUE)
#' }
#'
#' @export
git_status <- function(short = FALSE) {
  .require_git_repo()

  args <- "status"
  if (short) args <- c(args, "--short")

  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  cat(result, sep = "\n")
  invisible(result)
}


#' Stage Files for Commit
#'
#' Add file contents to the staging area.
#'
#' @param files Character vector of file paths to stage, or "." for all (default)
#'
#' @return Invisibly returns TRUE on success
#'
#' @examples
#' \dontrun{
#' git_add()              # Stage all changes
#' git_add("README.md")   # Stage specific file
#' git_add(c("R/foo.R", "R/bar.R"))
#' }
#'
#' @export
git_add <- function(files = ".") {
  .require_git_repo()

  result <- system2("git", c("add", files), stdout = TRUE, stderr = TRUE)

  if (length(files) == 1 && files == ".") {
    message("\u2713 Staged all changes")
  } else {
    message("\u2713 Staged: ", paste(files, collapse = ", "))
  }

  invisible(TRUE)
}


#' Commit Staged Changes
#'
#' Record changes to the repository with a commit message.
#'
#' @param message Commit message (required)
#' @param all Logical; if TRUE, automatically stage modified/deleted files (default: FALSE)
#'
#' @return Invisibly returns TRUE on success
#'
#' @examples
#' \dontrun{
#' git_commit("Fix bug in data loading")
#' git_commit("Update README", all = TRUE)  # Stage and commit
#' }
#'
#' @export
git_commit <- function(message, all = FALSE) {
  .require_git_repo()

  if (missing(message) || is.null(message) || message == "") {
    stop("Commit message is required")
  }

  # Write message to a temporary file to avoid shell/spacing issues
  msg_file <- tempfile("framework_commit_msg_")
  writeLines(message, msg_file)
  on.exit(unlink(msg_file), add = TRUE)

  args <- c("commit", "-F", msg_file)
  if (all) args <- c(args, "-a")

  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")

  if (!is.null(status) && status != 0) {
    cat(result, sep = "\n")
    stop("Commit failed")
  }

  message("\u2713 Committed: ", message)
  invisible(TRUE)
}


#' Push to Remote
#'
#' Push commits to the remote repository.
#'
#' @param remote Remote name (default: "origin")
#' @param branch Branch name (default: current branch)
#'
#' @return Invisibly returns TRUE on success
#'
#' @examples
#' \dontrun{
#' git_push()
#' git_push(remote = "origin", branch = "main")
#' }
#'
#' @export
git_push <- function(remote = "origin", branch = NULL) {
  .require_git_repo()

  args <- c("push", remote)
  if (!is.null(branch)) args <- c(args, branch)

  message("Pushing to ", remote, "...")
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")

  if (!is.null(status) && status != 0) {
    cat(result, sep = "\n")
    stop("Push failed")
  }

  message("\u2713 Pushed successfully")
  invisible(TRUE)
}


#' Pull from Remote
#'
#' Fetch and integrate changes from the remote repository.
#'
#' @param remote Remote name (default: "origin")
#' @param branch Branch name (default: current branch)
#'
#' @return Invisibly returns TRUE on success
#'
#' @examples
#' \dontrun{
#' git_pull()
#' git_pull(remote = "origin", branch = "main")
#' }
#'
#' @export
git_pull <- function(remote = "origin", branch = NULL) {
  .require_git_repo()

  args <- c("pull", remote)
  if (!is.null(branch)) args <- c(args, branch)

  message("Pulling from ", remote, "...")
  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")

  if (!is.null(status) && status != 0) {
    cat(result, sep = "\n")
    stop("Pull failed")
  }

  cat(result, sep = "\n")
  invisible(TRUE)
}


#' Show Changes (Diff)
#'
#' Show changes between commits, working tree, etc.
#'
#' @param staged Logical; if TRUE, show staged changes (default: FALSE shows unstaged)
#' @param file Optional file path to show diff for specific file
#'
#' @return Invisibly returns the diff output as a character vector
#'
#' @examples
#' \dontrun{
#' git_diff()             # Show unstaged changes
#' git_diff(staged = TRUE) # Show staged changes
#' git_diff(file = "R/foo.R")
#' }
#'
#' @export
git_diff <- function(staged = FALSE, file = NULL) {
  .require_git_repo()

  args <- "diff"
  if (staged) args <- c(args, "--staged")
  if (!is.null(file)) args <- c(args, file)

  result <- system2("git", args, stdout = TRUE, stderr = TRUE)

  if (length(result) == 0) {
    message("No changes")
  } else {
    cat(result, sep = "\n")
  }

  invisible(result)
}


#' Show Commit Log
#'
#' Show recent commit history.
#'
#' @param n Number of commits to show (default: 10)
#' @param oneline Logical; if TRUE, show condensed one-line format (default: TRUE)
#'
#' @return Invisibly returns the log output as a character vector
#'
#' @examples
#' \dontrun{
#' git_log()
#' git_log(n = 5)
#' git_log(oneline = FALSE)  # Full format
#' }
#'
#' @export
git_log <- function(n = 10, oneline = TRUE) {
  .require_git_repo()

  args <- c("log", paste0("-", n))
  if (oneline) args <- c(args, "--oneline")

  result <- system2("git", args, stdout = TRUE, stderr = TRUE)
  cat(result, sep = "\n")
  invisible(result)
}


# Git Hooks Management ----------------------------------------------------

#' Install Git Pre-commit Hook
#'
#' Creates a pre-commit hook that runs Framework checks based on settings.yml settings.
#'
#' @param config_file Path to configuration file (default: "settings.yml")
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
#'   \item **check_sensitive_dirs**: Warn about unignored sensitive directories
#' }
#'
#' Hook behavior is controlled by `git.hooks.*` settings in settings.yml.
#'
#' @examples
#' \dontrun{
#' # Install hooks based on settings.yml
#' git_hooks_install()
#'
#' # Force reinstall (overwrites existing hook)
#' git_hooks_install(force = TRUE)
#' }
#'
#' @export
git_hooks_install <- function(config_file = NULL,
                              force = FALSE,
                              verbose = TRUE) {

  # Check if git repo
  if (!.is_git_repo()) {
    if (verbose) {
      message("\u2717 Not a git repository")
    }
    return(invisible(FALSE))
  }

  # Auto-discover settings file if not specified
  if (is.null(config_file)) {
    config_file <- .get_settings_file()
  }

  if (is.null(config_file)) {
    if (verbose) {
      message("\u2717 Settings file not found")
    }
    return(invisible(FALSE))
  }

  # Check if config exists
  if (!file.exists(config_file)) {
    if (verbose) {
      message("\u2717 Config file not found: ", config_file)
    }
    return(invisible(FALSE))
  }

  # Read hook configuration
  ai_sync_enabled <- .get_hook_setting("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security_enabled <- .get_hook_setting("git.hooks.data_security", config_file = config_file, default = FALSE)
  check_sensitive_dirs_enabled <- .get_hook_setting(
    "git.hooks.check_sensitive_dirs",
    alias = "git.hooks.warn_unignored_sensitive",
    config_file = config_file,
    default = FALSE
  )

  if (!ai_sync_enabled && !data_security_enabled && !check_sensitive_dirs_enabled) {
    if (verbose) {
      message("\u2139 No hooks enabled in settings.yml/config.yml")
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
      message("\u2717 Pre-commit hook already exists")
      message("  Use force=TRUE to overwrite or edit .git/hooks/pre-commit manually")
    }
    return(invisible(FALSE))
  }

  # Generate hook script
  hook_script <- .generate_hook_script(ai_sync_enabled, data_security_enabled, check_sensitive_dirs_enabled)

  # Write hook
  tryCatch({
    writeLines(hook_script, hook_path)
    Sys.chmod(hook_path, mode = "0755")  # Make executable

    if (verbose) {
      message("\u2713 Installed pre-commit hook")
      if (ai_sync_enabled) {
        message("  \u2022 AI context sync enabled")
      }
      if (data_security_enabled) {
        message("  \u2022 Data security check enabled")
      }
      if (check_sensitive_dirs_enabled) {
        message("  \u2022 Sensitive directories check enabled")
      }
    }

    invisible(TRUE)
  }, error = function(e) {
    if (verbose) {
      message("\u2717 Failed to install hook: ", e$message)
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
git_hooks_uninstall <- function(verbose = TRUE) {
  hook_path <- ".git/hooks/pre-commit"

  if (!file.exists(hook_path)) {
    if (verbose) {
      message("\u2139 No pre-commit hook found")
    }
    return(invisible(FALSE))
  }

  # Check if it's a Framework-managed hook
  hook_content <- readLines(hook_path, warn = FALSE)
  is_framework_hook <- any(grepl("Framework Git Hooks", hook_content))

  if (!is_framework_hook) {
    if (verbose) {
      message("\u26a0 Pre-commit hook exists but not managed by Framework")
      message("  Delete .git/hooks/pre-commit manually if needed")
    }
    return(invisible(FALSE))
  }

  # Remove hook
  tryCatch({
    file.remove(hook_path)
    if (verbose) {
      message("\u2713 Removed pre-commit hook")
    }
    invisible(TRUE)
  }, error = function(e) {
    if (verbose) {
      message("\u2717 Failed to remove hook: ", e$message)
    }
    invisible(FALSE)
  })
}


#' Enable Specific Git Hook
#'
#' Enables a specific hook in settings and reinstalls the pre-commit hook.
#'
#' @param hook_name Name of hook: "ai_sync", "data_security", or "check_sensitive_dirs"
#' @param config_file Path to configuration file (default: auto-discover settings.yml or settings.yml)
#' @param verbose Logical; if TRUE (default), show messages
#'
#' @return Invisible TRUE on success
#'
#' @examples
#' \dontrun{
#' git_hooks_enable("ai_sync")
#' git_hooks_enable("data_security")
#' }
#'
#' @export
git_hooks_enable <- function(hook_name, config_file = NULL, verbose = TRUE) {
  valid_hooks <- c("ai_sync", "data_security", "check_sensitive_dirs", "warn_unignored_sensitive")

  if (!hook_name %in% valid_hooks) {
    stop("Invalid hook name. Must be one of: ", paste(valid_hooks, collapse = ", "))
  }

  # Auto-discover settings file if not specified
  if (is.null(config_file)) {
    config_file <- .get_settings_file()
    if (is.null(config_file)) {
      stop("Settings file not found")
    }
  }

  # Update settings.yml/config.yml
  .update_hook_config(hook_name, TRUE, config_file)

  if (verbose) {
    message("\u2713 Enabled ", hook_name, " hook")
  }

  # Reinstall hooks
  git_hooks_install(config_file = config_file, force = TRUE, verbose = verbose)
}


#' Disable Specific Git Hook
#'
#' Disables a specific hook in settings and reinstalls the pre-commit hook.
#'
#' @param hook_name Name of hook: "ai_sync", "data_security", or "check_sensitive_dirs"
#' @param config_file Path to configuration file (default: auto-discover settings.yml or settings.yml)
#' @param verbose Logical; if TRUE (default), show messages
#'
#' @return Invisible TRUE on success
#'
#' @export
git_hooks_disable <- function(hook_name, config_file = NULL, verbose = TRUE) {
  valid_hooks <- c("ai_sync", "data_security", "check_sensitive_dirs", "warn_unignored_sensitive")

  if (!hook_name %in% valid_hooks) {
    stop("Invalid hook name. Must be one of: ", paste(valid_hooks, collapse = ", "))
  }

  # Auto-discover settings file if not specified
  if (is.null(config_file)) {
    config_file <- .get_settings_file()
    if (is.null(config_file)) {
      stop("Settings file not found")
    }
  }

  # Update settings.yml/config.yml
  .update_hook_config(hook_name, FALSE, config_file)

  if (verbose) {
    message("\u2713 Disabled ", hook_name, " hook")
  }

  # Reinstall hooks (or uninstall if all disabled)
  ai_sync_enabled <- .get_hook_setting("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security_enabled <- .get_hook_setting("git.hooks.data_security", config_file = config_file, default = FALSE)
  check_sensitive_dirs_enabled <- .get_hook_setting(
    "git.hooks.check_sensitive_dirs",
    alias = "git.hooks.warn_unignored_sensitive",
    config_file = config_file,
    default = FALSE
  )

  if (!ai_sync_enabled && !data_security_enabled && !check_sensitive_dirs_enabled) {
    git_hooks_uninstall(verbose = verbose)
  } else {
    git_hooks_install(config_file = config_file, force = TRUE, verbose = verbose)
  }
}


#' List Git Hook Status
#'
#' Shows which hooks are enabled and their current status.
#'
#' @param config_file Path to configuration file (default: auto-discover settings.yml or settings.yml)
#'
#' @return Data frame with hook information
#'
#' @export
git_hooks_list <- function(config_file = NULL) {
  # Auto-discover settings file if not specified
  if (is.null(config_file)) {
    config_file <- .get_settings_file()
  }

  if (is.null(config_file)) {
    message("\u2717 Settings file not found")
    return(invisible(NULL))
  }

  if (!file.exists(config_file)) {
    message("\u2717 Config file not found: ", config_file)
    return(invisible(NULL))
  }

  ai_sync <- .get_hook_setting("git.hooks.ai_sync", config_file = config_file, default = FALSE)
  data_security <- .get_hook_setting("git.hooks.data_security", config_file = config_file, default = FALSE)
  check_sensitive_dirs <- .get_hook_setting(
    "git.hooks.check_sensitive_dirs",
    alias = "git.hooks.warn_unignored_sensitive",
    config_file = config_file,
    default = FALSE
  )

  hook_installed <- file.exists(".git/hooks/pre-commit")

  df <- data.frame(
    hook = c("ai_sync", "data_security", "check_sensitive_dirs"),
    enabled = c(ai_sync, data_security, check_sensitive_dirs),
    description = c(
      "Sync AI assistant context files",
      "Check for secrets/credentials",
      "Warn about unignored sensitive directories"
    ),
    stringsAsFactors = FALSE
  )

  message("=== Framework Git Hooks ===\n")
  message("Pre-commit hook: ", if (hook_installed) "installed" else "not installed")
  message("")

  for (i in seq_len(nrow(df))) {
    status_icon <- if (df$enabled[i]) "\u2713" else "\u2717"
    message(sprintf("%s %s - %s", status_icon, df$hook[i], df$description[i]))
  }

  message("\nCommands:")
  message("  git_hooks_enable(\"ai_sync\")")
  message("  git_hooks_disable(\"ai_sync\")")
  message("  git_hooks_install()")
  message("  git_hooks_uninstall()")

  invisible(df)
}


# Internal helpers --------------------------------------------------------

#' Check if current directory is a git repository
#' @keywords internal
.is_git_repo <- function() {
  dir.exists(".git")
}

#' Check if git is available on the system
#' @return TRUE if git is available, FALSE otherwise
#' @keywords internal
.git_available <- function() {
  nzchar(Sys.which("git"))
}

#' Require git repository or stop
#' @keywords internal
.require_git_repo <- function() {
  if (!.git_available()) {
    stop("Git is not installed or not in PATH. Please install git to use this feature.")
  }
  if (!.is_git_repo()) {
    stop("Not a git repository. Run 'git init' first.")
  }
}

#' Get git hook setting with optional alias fallback
#' @keywords internal
.get_hook_setting <- function(key, alias = NULL, config_file = NULL, default = FALSE) {
  value <- config(key, config_file = config_file, default = default)
  if (!is.null(alias) && identical(value, default)) {
    value <- config(alias, config_file = config_file, default = default)
  }
  value
}


#' Generate pre-commit hook script
#' @keywords internal
.generate_hook_script <- function(ai_sync_enabled, data_security_enabled, check_sensitive_dirs_enabled) {
  c(
    "#!/usr/bin/env bash",
    "# Framework Git Hooks",
    "# Managed by Framework - do not edit manually",
    "# Use git_hooks_*() functions to configure",
    "",
    "set -e",
    "",
    "# Get project root",
    "PROJECT_ROOT=\"$(git rev-parse --show-toplevel)\"",
    "cd \"$PROJECT_ROOT\"",
    "",
    if (check_sensitive_dirs_enabled) c(
      "# Check for unignored sensitive directories",
      "SENSITIVE_PATTERNS=('*private*' '*confidential*' '*sensitive*' '*cache*' '*scratch*')",
      "UNIGNORED_DIRS=()",
      "",
      "for pattern in \"${SENSITIVE_PATTERNS[@]}\"; do",
      "  while IFS= read -r -d '' dir; do",
      "    # Skip if it's the .git directory itself",
      "    [[ \"$dir\" == \"./.git\"* ]] && continue",
      "    ",
      "    # Check if directory is gitignored",
      "    if ! git check-ignore -q \"$dir\"; then",
      "      UNIGNORED_DIRS+=(\"$dir\")",
      "    fi",
      "  done < <(find . -type d -iname \"$pattern\" -print0 2>/dev/null)",
      "done",
      "",
      "if [ ${#UNIGNORED_DIRS[@]} -gt 0 ]; then",
      "  echo \"\u26a0 Warning: Found sensitive directories that are NOT gitignored:\"",
      "  for dir in \"${UNIGNORED_DIRS[@]}\"; do",
      "    echo \"  - $dir\"",
      "  done",
      "  echo \"\"",
      "  echo \"These directories may contain sensitive data and should be added to .gitignore.\"",
      "  echo \"Pattern-based .gitignore entries like '**/private/**' will automatically catch them.\"",
      "  echo \"\"",
      "  # Prompt user if running interactively, otherwise just warn",
      "  if [ -t 0 ] || exec < /dev/tty 2>/dev/null; then",
      "    read -p \"Continue with commit anyway? (y/N) \" -n 1 -r",
      "    echo",
      "    if [[ ! $REPLY =~ ^[Yy]$ ]]; then",
      "      echo \"Commit aborted. Add directories to .gitignore and try again.\"",
      "      exit 1",
      "    fi",
      "  else",
      "    echo \"(Non-interactive mode: continuing with warning)\"",
      "  fi",
      "fi",
      ""
    ) else NULL,
    if (ai_sync_enabled) c(
      "# AI context sync",
      "if ! Rscript -e \"library(framework); ai_sync_context(verbose=FALSE)\"; then",
      "  echo \"\u2717 AI context sync failed\"",
      "  exit 1",
      "fi",
      "",
      "# Add any files modified by AI sync",
      "git add CLAUDE.md AGENTS.md .github/copilot-instructions.md 2>/dev/null || true",
      ""
    ) else NULL,
    if (data_security_enabled) c(
      "# Data security check",
      "if ! Rscript -e \"library(framework); result <- git_security_audit(verbose=FALSE); if (any(result\\$summary\\$status == 'fail')) quit(status=1)\"; then",
      "  echo \"\u2717 Data security check failed\"",
      "  echo \"Run 'framework security:audit' for details\"",
      "  exit 1",
      "fi",
      ""
    ) else NULL,
    "exit 0"
  )
}


#' Update hook configuration in settings.yml/settings.yml
#' @keywords internal
.update_hook_config <- function(hook_name, enabled, config_file) {
  if (!file.exists(config_file)) {
    stop("Config file not found: ", config_file)
  }

  # Read config
  config_content <- yaml::read_yaml(config_file, eval.expr = FALSE)

  has_envs <- !is.null(config_content$default) && is.list(config_content$default)
  env_config <- if (has_envs) config_content$default else config_content

  # Ensure structure exists
  if (is.null(env_config$git)) {
    env_config$git <- list()
  }
  if (is.null(env_config$git$hooks)) {
    env_config$git$hooks <- list()
  }

  # Update hook setting
  env_config$git$hooks[[hook_name]] <- enabled

  if (has_envs) {
    config_content$default <- env_config
  } else {
    config_content <- env_config
  }

  # Write back
  yaml::write_yaml(config_content, config_file)

  invisible(TRUE)
}
