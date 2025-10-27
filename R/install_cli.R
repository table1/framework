#' Install Framework CLI Tool
#'
#' Creates a global `framework` command for creating new projects from the
#' command line. The CLI provides a convenient wrapper around new-project.sh.
#'
#' **Recommended:** Use the shell installer for better PATH setup:
#' ```bash
#' curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
#' ```
#'
#' This R function is a simpler alternative that attempts to create the
#' hybrid shim via symlink, falling back to copying the scripts when
#' symlinks are unavailable. You'll need to manually add `~/.local/bin`
#' to your PATH if needed.
#'
#' @param location Installation location: "user" (default) or "system".
#'   - "user": Installs to `~/.local/bin` (no sudo required)
#'   - "system": Installs to `/usr/local/bin` (requires sudo)
#' @param use_installer If TRUE (default), calls the shell installer script
#'   which handles PATH setup interactively. If FALSE, just creates symlink.
#'
#' @details
#' The CLI tool provides three ways to create Framework projects:
#'
#' 1. **CLI (this tool)**: `framework new myproject`
#' 2. **One-time curl**: `curl -fsSL https://... | bash`
#' 3. **Git clone**: `git clone https://github.com/table1/framework-project`
#'
#' All three methods use the same underlying implementation (new-project.sh).
#'
#' @section Installation Methods:
#'
#' **Shell installer (recommended):**
#' ```bash
#' curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash
#' ```
#'
#' **From R (simple):**
#' ```r
#' framework::cli_install()  # Calls shell installer
#' framework::cli_install(use_installer = FALSE)  # Just symlink
#' ```
#'
#' **System-wide:**
#' ```r
#' framework::cli_install(location = "system")  # Requires sudo
#' ```
#'
#' @examples
#' \dontrun{
#' # Install for current user (calls shell installer)
#' cli_install()
#'
#' # Install without shell installer (symlink only)
#' cli_install(use_installer = FALSE)
#'
#' # Install system-wide (requires sudo)
#' cli_install(location = "system")
#' }
#'
#' @export
cli_install <- function(location = c("user", "system"), use_installer = TRUE) {
  location <- match.arg(location)

  # For user installation, prefer the shell installer
  if (location == "user" && use_installer) {
    installer_script <- system.file("bin", "install-cli.sh", package = "framework")

    if (file.exists(installer_script)) {
      message("Running shell installer for better PATH setup...")
      result <- system(installer_script)

      if (result == 0) {
        return(invisible(path.expand("~/.local/bin/framework")))
      } else {
        warning("Shell installer failed. Falling back to simple installation.")
      }
    } else {
      warning("Shell installer not found. Using simple installation.")
    }
  }

  # Simple installation (no interactive prompts) - hybrid CLI pattern
  shim_script <- system.file("bin", "framework-shim", package = "framework")
  global_script <- system.file("bin", "framework-global", package = "framework")

  if (!file.exists(shim_script)) {
    stop(
      "CLI shim script not found. This may indicate a package installation issue.\n",
      "Expected location: ", shim_script
    )
  }

  if (!file.exists(global_script)) {
    stop(
      "CLI global script not found. This may indicate a package installation issue.\n",
      "Expected location: ", global_script
    )
  }

  if (location == "user") {
    # User installation to ~/.local/bin
    bin_dir <- path.expand("~/.local/bin")
    dir.create(bin_dir, showWarnings = FALSE, recursive = TRUE)

    # Install shim (main entry point)
    shim_target <- file.path(bin_dir, "framework")
    shim_result <- .install_cli_asset(shim_script, shim_target, "CLI shim")

    # Install global implementation
    global_target <- file.path(bin_dir, "framework-global")
    global_result <- .install_cli_asset(global_script, global_target, "global runner")

    message("\u2713 Framework CLI installed (hybrid pattern)\n")
    message("  Shim (", shim_result$method, "): ", shim_target, "\n")
    message("  Global (", global_result$method, "): ", global_target, "\n")

    # Check if in PATH
    path_dirs <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
    in_path <- bin_dir %in% path_dirs

    if (in_path) {
      message("\n\u2713 CLI is ready to use!\n\nTry: framework new myproject")
    } else {
      # Detect shell
      shell <- basename(Sys.getenv("SHELL"))
      shell_config <- switch(
        shell,
        zsh = "~/.zshrc",
        bash = "~/.bashrc",
        fish = "~/.config/fish/config.fish",
        "~/.profile"
      )

      # PATH export line based on shell
      path_line <- if (shell == "fish") {
        "set -gx PATH $HOME/.local/bin $PATH"
      } else {
        'export PATH="$HOME/.local/bin:$PATH"'
      }

      # Check if PATH already configured in shell config
      config_path <- path.expand(shell_config)

      if (file.exists(config_path)) {
        config_content <- readLines(config_path, warn = FALSE)
        if (any(grepl("\\.local/bin", config_content))) {
          message(
            "\n\u2713 PATH already configured in ", shell_config, "\n",
            "  (not active in this session)\n\n",
            "To activate now:\n",
            "  source ", shell_config, "\n\n",
            "Or restart your terminal, then try: framework new myproject"
          )

          # Prompt for AI assistant support
          ai_prefs <- .prompt_ai_support_install()
          frameworkrc <- path.expand("~/.frameworkrc")
          .update_frameworkrc(frameworkrc, ai_prefs$support, ai_prefs$assistants)

          return(invisible(shim_target))
        }
      }

      if (!interactive()) {
        message(
          "\nSkipping PATH setup (non-interactive session).\n",
          "Add to ", shell_config, ":\n",
          "  ", path_line, "\n",
          "Then restart your terminal or run: source ", shell_config
        )
      } else {
        message(
          "\nSetup PATH automatically?\n",
          "  Framework needs ~/.local/bin in your PATH to work from anywhere.\n",
          "  This will add one line to ", shell_config, "\n"
        )

        response <- readline("Add to PATH? [Y/n]: ")

        if (tolower(trimws(response)) %in% c("n", "no")) {
          message(
            "\nSkipping PATH setup\n\n",
            "To add manually later, add to ", shell_config, ":\n",
            "  ", path_line, "\n\n",
            "Then restart your terminal or run: source ", shell_config
          )
        } else {
          timestamp <- format(Sys.Date(), "%Y-%m-%d")
          new_lines <- c(
            sprintf("\n# Added by Framework CLI installer (%s)", timestamp),
            path_line
          )

          cat(new_lines, file = config_path, sep = "\n", append = TRUE)
          message("\n\u2713 Updated ", shell_config, "\n")

          message(
            "\nTo activate now:\n",
            "  source ", shell_config, "\n\n",
            "Or restart your terminal, then try: framework new myproject"
          )
        }
      }

      # Prompt for AI assistant support
      ai_prefs <- .prompt_ai_support_install()
      frameworkrc <- path.expand("~/.frameworkrc")
      .update_frameworkrc(frameworkrc, ai_prefs$support, ai_prefs$assistants)
    }
  } else {
    # System installation to /usr/local/bin
    shim_target <- "/usr/local/bin/framework"
    global_target <- "/usr/local/bin/framework-global"

    shim_result <- .install_cli_asset(shim_script, shim_target, "CLI shim", use_sudo = TRUE)
    global_result <- .install_cli_asset(global_script, global_target, "global runner", use_sudo = TRUE)

    message(
      "\u2713 Framework CLI installed system-wide (hybrid pattern)\n",
      "  Shim (", shim_result$method, "): ", shim_target, "\n",
      "  Global (", global_result$method, "): ", global_target, "\n\n",
      "Try: framework new myproject"
    )
  }

  invisible(shim_target)
}

.install_cli_asset <- function(source, target, label, use_sudo = FALSE) {
  if (!file.exists(source)) {
    stop(sprintf("%s not found at %s", label, source))
  }

  parent_dir <- dirname(target)
  if (!use_sudo && !dir.exists(parent_dir)) {
    dir.create(parent_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (file.exists(target)) {
    if (use_sudo) {
      system(sprintf("sudo rm -f %s", shQuote(target)), ignore.stdout = TRUE)
    } else {
      file.remove(target)
    }
  }

  force_copy <- tolower(Sys.getenv("FRAMEWORK_FORCE_COPY", "")) %in% c("true", "1", "yes")
  symlink_supported <- (.Platform$OS.type != "windows") && !force_copy

  method <- "symlink"
  success <- FALSE

  if (symlink_supported) {
    success <- tryCatch({
      if (use_sudo) {
        system(sprintf("sudo ln -s %s %s", shQuote(source), shQuote(target)), ignore.stdout = TRUE) == 0
      } else {
        file.symlink(source, target)
      }
    }, warning = function(w) FALSE, error = function(e) FALSE)
  }

  if (!success) {
    method <- "copy"
    if (use_sudo) {
      success <- system(sprintf("sudo cp %s %s", shQuote(source), shQuote(target)), ignore.stdout = TRUE) == 0
    } else {
      success <- file.copy(source, target, overwrite = TRUE)
    }
  }

  if (!success) {
    stop("Failed to install ", label, " at ", target,
         ". Ensure you have permission to modify the destination directory.")
  }

  if (use_sudo) {
    system(sprintf("sudo chmod 755 %s", shQuote(target)), ignore.stdout = TRUE)
  } else if (.Platform$OS.type != "windows") {
    Sys.chmod(target, "755")
  }

  if (method == "copy" && symlink_supported) {
    message("  Symlink unavailable; copied ", label, " instead.")
  }

  invisible(list(path = target, method = method))
}


#' Uninstall Framework CLI Tool
#'
#' Removes the global `framework` command and framework-global.
#' 
#' @param location Installation location to remove: "user" or "system".
#'   Must match the location used during installation.
#'
#' @examples
#' \dontrun{
#' # Uninstall user installation
#' cli_uninstall()
#'
#' # Uninstall system installation
#' cli_uninstall(location = "system")
#' }
#'
#' @export
cli_uninstall <- function(location = c("user", "system")) {
  location <- match.arg(location)

  if (location == "user") {
    shim_target <- path.expand("~/.local/bin/framework")
    global_target <- path.expand("~/.local/bin/framework-global")
  } else {
    shim_target <- "/usr/local/bin/framework"
    global_target <- "/usr/local/bin/framework-global"
  }

  removed <- FALSE

  if (location == "user") {
    if (file.exists(shim_target)) {
      file.remove(shim_target)
      message("\u2713 Removed ", shim_target)
      removed <- TRUE
    }
    if (file.exists(global_target)) {
      file.remove(global_target)
      message("\u2713 Removed ", global_target)
      removed <- TRUE
    }
  } else {
    if (file.exists(shim_target)) {
      cmd <- sprintf("sudo rm -f %s", shQuote(shim_target))
      result <- system(cmd, ignore.stdout = TRUE)
      if (result == 0) {
        message("\u2713 Removed ", shim_target)
        removed <- TRUE
      }
    }
    if (file.exists(global_target)) {
      cmd <- sprintf("sudo rm -f %s", shQuote(global_target))
      result <- system(cmd, ignore.stdout = TRUE)
      if (result == 0) {
        message("\u2713 Removed ", global_target)
        removed <- TRUE
      }
    }
  }

  if (!removed) {
    message("CLI not found at expected locations")
    return(invisible(FALSE))
  }

  invisible(TRUE)
}


#' Update Framework CLI Tool
#'
#' Updates the Framework package and CLI tool to the latest version from GitHub.
#' Since the CLI is a symlink to the installed package, updating the package
#' automatically updates the CLI.
#'
#' This function runs quietly without interactive prompts, suitable for CLI usage.
#' The CLI wrapper script handles user prompts in bash before calling this function.
#'
#' @param ref Git reference (branch, tag, or commit). Default: "main"
#' @param upgrade_deps Update dependencies to latest versions. Default: TRUE
#' @param force Force reinstall even if SHA hasn't changed. Default: FALSE
#'
#' @examples
#' \dontrun{
#' # Update everything (package + dependencies)
#' cli_update()
#'
#' # Update Framework only, keep current dependencies
#' cli_update(upgrade_deps = FALSE)
#'
#' # Force reinstall
#' cli_update(force = TRUE)
#'
#' # Update to specific branch
#' cli_update(ref = "develop")
#' }
#'
#' @export
cli_update <- function(ref = "main", upgrade_deps = TRUE, force = FALSE) {
  message("Updating Framework package and CLI from GitHub...")

  # Check if devtools is available, install if missing
  if (!requireNamespace("devtools", quietly = TRUE)) {
    message("Installing devtools (required for updates)...")

    # Check if we're in an renv project
    if (renv_enabled()) {
      # Use renv to install devtools
      if (!requireNamespace("renv", quietly = TRUE)) {
        stop(
          "renv is enabled but not available. Please install renv first:\n",
          "  install.packages('renv')"
        )
      }
      renv::install("devtools")
    } else {
      # Use standard install.packages
      install.packages("devtools", repos = "https://cloud.r-project.org")
    }
  }

  # Store old version
  old_version <- tryCatch(
    as.character(packageVersion("framework")),
    error = function(e) "unknown"
  )

  # Determine upgrade strategy
  upgrade_mode <- if (upgrade_deps) "always" else "never"

  # Update package (quietly, no interactive prompts)
  devtools::install_github(
    "table1/framework",
    ref = ref,
    upgrade = upgrade_mode,
    force = force,
    quiet = TRUE
  )

  message("\u2713 Framework CLI updated!")

  # Show version info
  new_version <- as.character(packageVersion("framework"))

  if (old_version != "unknown" && old_version != new_version) {
    message("Updated: ", old_version, " \u2192 ", new_version)
  } else if (force) {
    message("Reinstalled: ", new_version)
  } else {
    message("Already up to date: ", new_version)
  }

  invisible(new_version)
}


#' @rdname cli_install
#' @export
install_cli <- cli_install

#' @rdname cli_uninstall
#' @export
uninstall_cli <- cli_uninstall
