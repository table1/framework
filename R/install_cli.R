#' Install Framework CLI Tool
#'
#' Creates a global `framework` command for creating new projects from the
#' command line. The CLI provides a convenient wrapper around new-project.sh.
#'
#' @param location Installation location: "user" (default) or "system".
#'   - "user": Installs to `~/.local/bin` (no sudo required)
#'   - "system": Installs to `/usr/local/bin` (requires sudo)
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
#' After installation, the `framework` command will be available globally:
#' - `framework new` - Interactive project creation
#' - `framework new myproject` - Create project with defaults
#' - `framework new slides course` - Create course project
#' - `framework version` - Show Framework version
#' - `framework help` - Show help
#'
#' @section User Installation:
#' User installation (`location = "user"`) installs to `~/.local/bin` without
#' requiring sudo. If `~/.local/bin` is not in your PATH, the installer will:
#'
#' 1. Detect your shell (bash, zsh, fish)
#' 2. Offer to automatically add it to your shell config
#' 3. Provide clear instructions for activation
#'
#' The installer is smart enough to detect if the PATH is already configured
#' and won't duplicate entries
#'
#' @section System Installation:
#' System installation (`location = "system"`) installs to `/usr/local/bin`
#' and requires sudo privileges. This makes the command available to all users.
#'
#' @examples
#' \dontrun{
#' # Install for current user (recommended)
#' cli_install()
#'
#' # Install system-wide (requires sudo)
#' cli_install(location = "system")
#'
#' # Then use the CLI
#' system("framework new myproject")
#' }
#'
#' @export
cli_install <- function(location = c("user", "system")) {
  location <- match.arg(location)

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

    # Always check and offer to fix PATH, regardless of current state
    # This ensures users get help even on reinstalls or if their shell config is outdated
    .setup_path_interactive(bin_dir, target)
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
#' @param ref Git reference (branch, tag, or commit). Default: "main"
#'
#' @examples
#' \dontrun{
#' # Update to latest version
#' cli_update()
#'
#' # Update to specific branch
#' cli_update(ref = "develop")
#' }
#'
#' @export
cli_update <- function(ref = "main") {
  message("Updating Framework package and CLI from GitHub...")
  message("")

  # Store old version
  old_version <- tryCatch(
    as.character(packageVersion("framework")),
    error = function(e) "unknown"
  )

  # Update package
  devtools::install_github("table1/framework", ref = ref, upgrade = "ask")

  message("")
  message("\u2713 Framework CLI updated!")

  # Show version info
  new_version <- as.character(packageVersion("framework"))

  if (old_version != "unknown" && old_version != new_version) {
    message("Updated: ", old_version, " \u2192 ", new_version)
  } else {
    message("Current version: ", new_version)
  }

  # Check if CLI is installed
  cli_installed <- Sys.which("framework") != ""
  if (!cli_installed) {
    message("")
    message("Note: CLI not installed. Run framework::cli_install() to install it.")
  }

  invisible(new_version)
}


#' @rdname cli_install
#' @export
install_cli <- cli_install

#' @rdname cli_uninstall
#' @export
uninstall_cli <- cli_uninstall


#' Interactive PATH Setup Helper
#'
#' Offers to automatically add ~/.local/bin to the user's shell PATH.
#'
#' @param bin_dir Directory to add to PATH
#' @param target Full path to installed CLI
#' @keywords internal
.setup_path_interactive <- function(bin_dir, target) {
  message("\u2713 CLI installed to ", target, "\n")

  # Check if bin_dir is in current PATH
  path_dirs <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
  in_path <- bin_dir %in% path_dirs

  # If already in PATH, just confirm success
  if (in_path) {
    message("\nCLI is ready to use!\n\nTry: framework new myproject")
    return(invisible(NULL))
  }

  # Detect shell
  shell <- basename(Sys.getenv("SHELL"))
  if (shell == "") shell <- "bash"  # fallback

  # Determine config file
  shell_config <- switch(
    shell,
    zsh = "~/.zshrc",
    bash = "~/.bashrc",
    fish = "~/.config/fish/config.fish",
    "~/.profile"  # fallback
  )

  shell_config_expanded <- path.expand(shell_config)

  # Export line to add
  export_line <- if (shell == "fish") {
    "set -gx PATH $HOME/.local/bin $PATH"
  } else {
    'export PATH="$HOME/.local/bin:$PATH"'
  }

  # Check if already in config
  already_added <- FALSE
  if (file.exists(shell_config_expanded)) {
    config_content <- readLines(shell_config_expanded, warn = FALSE)
    already_added <- any(grepl(".local/bin.*PATH|PATH.*\\.local/bin", config_content, perl = TRUE))
  }

  if (already_added) {
    message(
      "\nNote: ~/.local/bin is already in your ", shell_config, "\n",
      "but is not active in this session.\n\n",
      "To use the CLI:\n",
      "1. Restart your terminal (recommended), or\n",
      "2. Run in terminal: source ", shell_config, "\n\n",
      "Then try: framework new myproject"
    )
    return(invisible(NULL))
  }

  # Offer to add automatically
  message(
    "\nThe CLI needs ~/.local/bin in your PATH.\n\n",
    "Would you like to automatically add it to ", shell_config, "? (y/n): "
  )

  response <- tolower(trimws(readline()))

  if (response %in% c("y", "yes")) {
    tryCatch(
      {
        # Add to shell config
        cat(
          sprintf("\n# Added by Framework CLI installer\n%s\n", export_line),
          file = shell_config_expanded,
          append = TRUE
        )
        message(
          "\n\u2713 Added to ", shell_config, "\n\n",
          "To activate:\n",
          "1. Restart your terminal (recommended), or\n",
          "2. Run in terminal: source ", shell_config, "\n\n",
          "Then try: framework new myproject"
        )
      },
      error = function(e) {
        message(
          "\n\u2717 Failed to write to ", shell_config, ": ", e$message, "\n\n",
          "Please manually add this line to ", shell_config, ":\n",
          "  ", export_line, "\n\n",
          "Then restart your terminal or run: source ", shell_config
        )
      }
    )
  } else {
    message(
      "\nTo use the CLI, manually add this line to ", shell_config, ":\n",
      "  ", export_line, "\n\n",
      "Then restart your terminal or run: source ", shell_config
    )
  }

  invisible(NULL)
}
