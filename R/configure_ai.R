#' Configure AI Assistant Support
#'
#' Interactive function to configure which AI coding assistants Framework
#' should create instruction files for. Updates preferences in `~/.frameworkrc`.
#'
#' This function allows you to:
#' - Enable or disable AI assistant support
#' - Choose which assistants to create files for (Claude Code, GitHub Copilot, AGENTS.md)
#' - Change your default preferences at any time
#'
#' Your preferences are stored in `~/.frameworkrc` and will be used as defaults
#' when creating new Framework projects.
#'
#' @details
#' Supported AI assistants:
#' - **Claude Code**: Creates `CLAUDE.md` in project root
#' - **GitHub Copilot**: Creates `.github/copilot-instructions.md`
#' - **AGENTS.md**: Creates `AGENTS.md` (cross-platform, industry standard)
#'
#' @examples
#' \dontrun{
#' # Interactively configure AI assistant support
#' configure_ai_agents()
#' }
#'
#' @export
configure_ai_agents <- function() {
  frameworkrc <- path.expand("~/.frameworkrc")

  # Read current settings
  current_support <- Sys.getenv("FW_AI_SUPPORT", "")
  current_assistants <- Sys.getenv("FW_AI_ASSISTANTS", "")

  # Determine current state
  if (current_support == "never") {
    status_msg <- "disabled (never ask again)"
  } else if (current_support == "yes") {
    status_msg <- sprintf("enabled (assistants: %s)", current_assistants)
  } else {
    status_msg <- "not configured"
  }

  message("\nFramework AI Assistant Support Configuration")
  message("═══════════════════════════════════════════════\n")
  message("Current status: ", status_msg, "\n")

  message("What would you like to do?")
  message("  1. Change which assistants to use by default")
  message("  2. Disable AI assistant support (never ask again)")
  message("  3. Re-enable AI assistant support")
  message("  4. Cancel\n")

  choice <- readline("Enter choice (1-4): ")

  if (choice == "1") {
    # Change assistant selection
    message("\nWhich AI assistants do you use? (Select all that apply)")
    message("  1. Claude Code (CLAUDE.md)")
    message("  2. GitHub Copilot (.github/copilot-instructions.md)")
    message("  3. AGENTS.md (cross-platform, industry standard)")
    message("  4. All of the above\n")

    selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")

    assistants <- .parse_assistant_selection(selection)

    if (length(assistants) == 0) {
      message("\nNo assistants selected. Configuration unchanged.")
      return(invisible(FALSE))
    }

    .update_frameworkrc(frameworkrc, support = "yes", assistants = assistants)

    message("\n✓ Configuration updated!")
    message("  AI support: enabled")
    message("  Assistants: ", paste(assistants, collapse = ", "))

  } else if (choice == "2") {
    # Disable
    .update_frameworkrc(frameworkrc, support = "never", assistants = character(0))

    message("\n✓ AI assistant support disabled")
    message("  Framework will not ask about AI assistants when creating projects.")
    message("  Run configure_ai_agents() anytime to re-enable.")

  } else if (choice == "3") {
    # Re-enable
    if (current_support != "never") {
      message("\nAI support is already enabled.")
      return(invisible(FALSE))
    }

    message("\nWhich AI assistants do you use? (Select all that apply)")
    message("  1. Claude Code (CLAUDE.md)")
    message("  2. GitHub Copilot (.github/copilot-instructions.md)")
    message("  3. AGENTS.md (cross-platform, industry standard)")
    message("  4. All of the above\n")

    selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")

    assistants <- .parse_assistant_selection(selection)

    if (length(assistants) == 0) {
      message("\nNo assistants selected. Configuration unchanged.")
      return(invisible(FALSE))
    }

    .update_frameworkrc(frameworkrc, support = "yes", assistants = assistants)

    message("\n✓ AI assistant support re-enabled!")
    message("  Assistants: ", paste(assistants, collapse = ", "))

  } else {
    message("\nCancelled. No changes made.")
    return(invisible(FALSE))
  }

  invisible(TRUE)
}


#' Create AI Assistant Instruction Files
#'
#' Internal function called during init() to create AI assistant instruction
#' files based on user preferences.
#'
#' @param assistants Character vector of assistants: "claude", "copilot", "agents"
#' @param target_dir Target directory (default: current directory)
#' @param project_name Project name for template substitution
#' @keywords internal
.create_ai_instructions <- function(assistants, target_dir = ".", project_name = NULL) {
  if (length(assistants) == 0) {
    return(invisible(NULL))
  }

  template_dir <- system.file("templates", package = "framework")

  for (assistant in assistants) {
    if (assistant == "claude") {
      # Copy CLAUDE.md
      template_file <- file.path(template_dir, "CLAUDE.fr.md")
      target_file <- file.path(target_dir, "CLAUDE.md")

      if (file.exists(template_file)) {
        file.copy(template_file, target_file, overwrite = FALSE)
        message("  ✓ Created CLAUDE.md")
      }

    } else if (assistant == "copilot") {
      # Copy copilot-instructions.md (create .github/ dir if needed)
      github_dir <- file.path(target_dir, ".github")
      if (!dir.exists(github_dir)) {
        dir.create(github_dir, showWarnings = FALSE)
      }

      template_file <- file.path(template_dir, "copilot-instructions.fr.md")
      target_file <- file.path(github_dir, "copilot-instructions.md")

      if (file.exists(template_file)) {
        file.copy(template_file, target_file, overwrite = FALSE)
        message("  ✓ Created .github/copilot-instructions.md")
      }

    } else if (assistant == "agents") {
      # Copy AGENTS.md
      template_file <- file.path(template_dir, "AGENTS.fr.md")
      target_file <- file.path(target_dir, "AGENTS.md")

      if (file.exists(template_file)) {
        file.copy(template_file, target_file, overwrite = FALSE)
        message("  ✓ Created AGENTS.md")
      }
    }
  }

  invisible(NULL)
}


#' Prompt for AI Support During CLI Install
#'
#' Called during cli_install() to set initial AI preferences.
#'
#' @keywords internal
.prompt_ai_support_install <- function() {
  message("\n")
  message("Do you want Framework to create instruction files for AI coding assistants?")
  message("These files help assistants understand your project structure and keep data secure.")

  response <- readline("Enable AI assistant support? (y/n): ")

  if (tolower(trimws(response)) %in% c("n", "no")) {
    # User doesn't want AI support
    return(list(support = "never", assistants = character(0)))
  }

  # User wants AI support - ask which assistants
  message("\nWhich AI assistants do you use? (Select all that apply)")
  message("  1. Claude Code (CLAUDE.md)")
  message("  2. GitHub Copilot (.github/copilot-instructions.md)")
  message("  3. AGENTS.md (cross-platform, industry standard)")
  message("  4. All of the above\n")

  selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")

  assistants <- .parse_assistant_selection(selection)

  if (length(assistants) == 0) {
    message("\nNo assistants selected. AI support will be disabled.")
    return(list(support = "never", assistants = character(0)))
  }

  return(list(support = "yes", assistants = assistants))
}


#' Prompt for AI Support During Project Init
#'
#' Called during init() to ask about AI instructions for this project.
#'
#' @keywords internal
.prompt_ai_support_init <- function() {
  # Check if user has disabled AI support
  fw_support <- Sys.getenv("FW_AI_SUPPORT", "")

  if (fw_support == "never") {
    # Don't ask, user has opted out
    return(character(0))
  }

  if (fw_support != "yes") {
    # User hasn't configured yet - ask now for the first time
    message("\n")
    message("Do you want Framework to create instruction files for AI coding assistants?")
    message("These files help assistants understand your project structure and keep data secure.")

    response <- readline("Enable AI assistant support? (y/n): ")

    if (tolower(trimws(response)) %in% c("n", "no")) {
      # User doesn't want AI support - save preference
      frameworkrc <- path.expand("~/.frameworkrc")
      .update_frameworkrc(frameworkrc, "never", character(0))
      message("\n✓ AI assistant support disabled. Run configure_ai_agents() to change later.")
      return(character(0))
    }

    # User wants AI support - ask which assistants
    message("\nWhich AI assistants do you use? (Select all that apply)")
    message("  1. Claude Code (CLAUDE.md)")
    message("  2. GitHub Copilot (.github/copilot-instructions.md)")
    message("  3. AGENTS.md (cross-platform, industry standard)")
    message("  4. All of the above\n")

    selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")
    assistants <- .parse_assistant_selection(selection)

    if (length(assistants) == 0) {
      message("\nNo assistants selected. Skipping AI assistant support for this project.")
      return(character(0))
    }

    # Save preferences for future projects
    frameworkrc <- path.expand("~/.frameworkrc")
    .update_frameworkrc(frameworkrc, "yes", assistants)
    message("\n✓ AI preferences saved. These will be used as defaults for future projects.")

    return(assistants)
  }

  # User has enabled AI support - ask if they want it for this project
  message("\n")
  response <- readline("Create AI assistant instruction files for this project? (y/n) [y]: ")

  if (tolower(trimws(response)) == "n") {
    return(character(0))
  }

  # Get user's default assistants
  default_assistants <- Sys.getenv("FW_AI_ASSISTANTS", "")

  if (default_assistants == "") {
    # No defaults set, ask
    message("\nWhich AI assistants do you use? (Select all that apply)")
    message("  1. Claude Code (CLAUDE.md)")
    message("  2. GitHub Copilot (.github/copilot-instructions.md)")
    message("  3. AGENTS.md (cross-platform, industry standard)")
    message("  4. All of the above\n")

    selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")
    return(.parse_assistant_selection(selection))
  }

  # Show defaults and ask if they want to change
  assistants <- strsplit(default_assistants, ",")[[1]]
  message(sprintf("\nUsing your defaults: %s", paste(assistants, collapse = ", ")))

  change_response <- readline("Change? (y/n) [n]: ")

  if (tolower(trimws(change_response)) %in% c("y", "yes")) {
    message("\nWhich AI assistants do you use? (Select all that apply)")
    message("  1. Claude Code (CLAUDE.md)")
    message("  2. GitHub Copilot (.github/copilot-instructions.md)")
    message("  3. AGENTS.md (cross-platform, industry standard)")
    message("  4. All of the above\n")

    selection <- readline("Enter numbers (e.g., 1,3 or 4 for all): ")
    return(.parse_assistant_selection(selection))
  }

  return(assistants)
}


#' Parse Assistant Selection from User Input
#'
#' Helper to convert user input like "1,3" or "4" into assistant names.
#'
#' @param selection User input string
#' @return Character vector of assistant names
#' @keywords internal
.parse_assistant_selection <- function(selection) {
  selection <- trimws(selection)

  if (selection == "4") {
    return(c("claude", "copilot", "agents"))
  }

  # Parse comma-separated numbers
  numbers <- as.integer(strsplit(selection, ",")[[1]])
  numbers <- numbers[!is.na(numbers)]

  assistants <- character(0)

  if (1 %in% numbers) assistants <- c(assistants, "claude")
  if (2 %in% numbers) assistants <- c(assistants, "copilot")
  if (3 %in% numbers) assistants <- c(assistants, "agents")

  return(unique(assistants))
}


#' Update ~/.frameworkrc with AI Preferences
#'
#' Helper to update the frameworkrc file with AI support settings.
#'
#' @param frameworkrc_path Path to .frameworkrc file
#' @param support "yes", "never", or ""
#' @param assistants Character vector of assistant names
#' @keywords internal
.update_frameworkrc <- function(frameworkrc_path, support, assistants) {
  # Read existing content
  if (file.exists(frameworkrc_path)) {
    lines <- readLines(frameworkrc_path, warn = FALSE)
  } else {
    lines <- character(0)
  }

  # Remove existing AI config lines
  lines <- lines[!grepl("^FW_AI_SUPPORT=", lines)]
  lines <- lines[!grepl("^FW_AI_ASSISTANTS=", lines)]

  # Add new config
  if (support != "") {
    lines <- c(
      lines,
      sprintf('FW_AI_SUPPORT="%s"', support)
    )
  }

  if (length(assistants) > 0) {
    lines <- c(
      lines,
      sprintf('FW_AI_ASSISTANTS="%s"', paste(assistants, collapse = ","))
    )
  }

  # Write back
  writeLines(lines, frameworkrc_path)

  # Update current environment
  Sys.setenv(FW_AI_SUPPORT = support)
  if (length(assistants) > 0) {
    Sys.setenv(FW_AI_ASSISTANTS = paste(assistants, collapse = ","))
  }

  invisible(NULL)
}
