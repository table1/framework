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
#' This R function is a simpler alternative that just creates the symlink.
#' You'll need to manually add `~/.local/bin` to your PATH if needed.
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

  # Simple installation (no interactive prompts)
  cli_script <- system.file("bin", "framework", package = "framework")

  if (!file.exists(cli_script)) {
    stop(
      "CLI script not found. This may indicate a package installation issue.\n",
      "Expected location: ", cli_script
    )
  }

  if (location == "user") {
    # User installation to ~/.local/bin
    bin_dir <- path.expand("~/.local/bin")
    dir.create(bin_dir, showWarnings = FALSE, recursive = TRUE)
    target <- file.path(bin_dir, "framework")

    # Remove existing symlink/file
    if (file.exists(target)) {
      file.remove(target)
    }

    # Create symlink
    file.symlink(cli_script, target)

    # Make executable
    Sys.chmod(target, "755")

    message("\u2713 CLI installed to ", target, "\n")

    # Check if in PATH
    path_dirs <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
    in_path <- bin_dir %in% path_dirs

    if (in_path) {
      message("\nCLI is ready to use!\n\nTry: framework new myproject")
    } else {
      # Detect shell and provide manual instructions
      shell <- basename(Sys.getenv("SHELL"))
      shell_config <- switch(
        shell,
        zsh = "~/.zshrc",
        bash = "~/.bashrc",
        fish = "~/.config/fish/config.fish",
        "~/.profile"
      )

      export_line <- if (shell == "fish") {
        "set -gx PATH $HOME/.local/bin $PATH"
      } else {
        'export PATH="$HOME/.local/bin:$PATH"'
      }

      message(
        "\nTo use the CLI, add this line to ", shell_config, ":\n",
        "  ", export_line, "\n\n",
        "Then restart your terminal or run: source ", shell_config, "\n\n",
        "Or reinstall with the shell installer:\n",
        "  curl -fsSL https://raw.githubusercontent.com/table1/framework/main/inst/bin/install-cli.sh | bash"
      )
    }
  } else {
    # System installation to /usr/local/bin
    target <- "/usr/local/bin/framework"

    # Remove existing if present
    if (file.exists(target)) {
      system(sprintf("sudo rm -f %s", shQuote(target)), ignore.stdout = TRUE)
    }

    # Create symlink with sudo
    cmd <- sprintf(
      "sudo ln -sf %s %s && sudo chmod 755 %s",
      shQuote(cli_script),
      target,
      target
    )

    result <- system(cmd, ignore.stdout = TRUE)

    if (result == 0) {
      message(
        "\u2713 CLI installed to ", target, "\n\n",
        "Try: framework new myproject"
      )
    } else {
      stop("Installation failed. Check sudo permissions.")
    }
  }

  invisible(target)
}


#' Uninstall Framework CLI Tool
#'
#' Removes the global `framework` command.
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
    target <- path.expand("~/.local/bin/framework")
  } else {
    target <- "/usr/local/bin/framework"
  }

  if (!file.exists(target)) {
    message("CLI not found at ", target)
    return(invisible(FALSE))
  }

  if (location == "user") {
    file.remove(target)
    message("\u2713 CLI removed from ", target)
  } else {
    cmd <- sprintf("sudo rm -f %s", shQuote(target))
    result <- system(cmd, ignore.stdout = TRUE)

    if (result == 0) {
      message("\u2713 CLI removed from ", target)
    } else {
      stop("Uninstallation failed. Check sudo permissions.")
    }
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
