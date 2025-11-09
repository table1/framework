#' Configure AI Assistant Support
#'
#' Non-interactive function to configure AI assistant support.
#' Should be called from bash CLI with parameters, not directly from R.
#'
#' @param support "yes", "never", or NULL (show current status)
#' @param assistants Character vector of assistants: "claude", "copilot", "agents"
#'
#' @details
#' Supported AI assistants:
#' - **Claude Code**: Creates `CLAUDE.md` in project root
#' - **GitHub Copilot**: Creates `.github/copilot-instructions.md`
#' - **AGENTS.md**: Creates `AGENTS.md` (cross-platform, industry standard)
#'
#' @examples
#' \dontrun{
#' # Enable AI support with Claude and Copilot
#' configure_ai_agents(support = "yes", assistants = c("claude", "copilot"))
#'
#' # Disable AI support
#' configure_ai_agents(support = "never")
#'
#' # Show current status
#' configure_ai_agents()
#' }
#'
#' @export
configure_ai_agents <- function(support = NULL, assistants = NULL) {
  frameworkrc <- path.expand("~/.frameworkrc")

  # Read current settings
  current_support <- Sys.getenv("FW_AI_SUPPORT", "")
  current_assistants <- Sys.getenv("FW_AI_ASSISTANTS", "")

  # If no parameters, show current status
  if (is.null(support)) {
    if (current_support == "never") {
      status_msg <- "disabled"
    } else if (current_support == "yes") {
      status_msg <- sprintf("enabled (assistants: %s)", current_assistants)
    } else {
      status_msg <- "not configured"
    }
    message("AI assistant support: ", status_msg)
    return(invisible(list(support = current_support, assistants = current_assistants)))
  }

  # Update configuration
  .update_frameworkrc(frameworkrc, support = support, assistants = assistants %||% character(0))

  if (support == "yes" && length(assistants) > 0) {
    message("✓ AI assistant support enabled")
    message("  Assistants: ", paste(assistants, collapse = ", "))
  } else if (support == "never") {
    message("✓ AI assistant support disabled")
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
#' @param project_type Project type for template selection ("project", "project_sensitive", "course", "presentation")
#' @keywords internal
.create_ai_instructions <- function(assistants, target_dir = ".", project_name = NULL, project_type = "project") {
  if (length(assistants) == 0) {
    return(invisible(NULL))
  }

  template_dir <- system.file("templates", package = "framework")

  for (assistant in assistants) {
    if (assistant == "claude") {
      # Select project-type-specific CLAUDE template
      template_name <- switch(
        project_type,
        "project_sensitive" = "CLAUDE-sensitive.fr.md",
        "course" = "CLAUDE-course.fr.md",
        "presentation" = "CLAUDE-presentation.fr.md",
        "CLAUDE-project.fr.md"  # Default for "project" and any other type
      )

      template_file <- file.path(template_dir, template_name)
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


#' Set AI Support Preferences (Non-interactive)
#'
#' Called from bash CLI to set AI preferences.
#' NO prompting - bash handles all user interaction.
#'
#' @param support "yes" or "never"
#' @param assistants Character vector like c("claude", "copilot")
#' @keywords internal
.prompt_ai_support_install <- function(support = "never", assistants = character(0)) {
  return(list(support = support, assistants = assistants))
}


#' Get AI Support Preferences (Non-interactive)
#'
#' Called during init() to check if AI instructions should be created.
#' NO prompting - just returns saved preferences.
#'
#' @keywords internal
.prompt_ai_support_init <- function() {
  # Check saved preferences
  fw_support <- Sys.getenv("FW_AI_SUPPORT", "")

  # If user disabled, don't create files
  if (fw_support == "never") {
    return(character(0))
  }

  # If user enabled, return their assistants
  if (fw_support == "yes") {
    assistants <- Sys.getenv("FW_AI_ASSISTANTS", "")
    if (assistants != "") {
      return(strsplit(assistants, ",")[[1]])
    }
  }

  # Not configured - don't create files
  return(character(0))
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
