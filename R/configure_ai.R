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
#' Internal function called during project_create() to create AI assistant instruction
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

  # Get project name from directory if not provided
  if (is.null(project_name)) {
    project_name <- basename(normalizePath(target_dir))
  }

  # Generate AI context content dynamically
  # Try to use ai_generate() if config exists, otherwise use template
  config <- tryCatch(
    config_read(file.path(target_dir, "settings.yml")),
    error = function(e) NULL
  )

  if (!is.null(config)) {
    # Use dynamic generation
    content <- ai_generate(
      project_path = target_dir,
      project_name = project_name,
      project_type = project_type,
      config = config
    )
  } else {
    # Fall back to template
    content <- .load_ai_template(project_type, project_name)
  }

  # Define file paths for each assistant
  ai_files <- list(
    claude = "CLAUDE.md",
    agents = "AGENTS.md",
    copilot = ".github/copilot-instructions.md"
  )

  for (assistant in assistants) {
    if (assistant %in% names(ai_files)) {
      target_file <- file.path(target_dir, ai_files[[assistant]])

      # Create directory if needed (for copilot)
      file_dir <- dirname(target_file)
      if (!dir.exists(file_dir)) {
        dir.create(file_dir, recursive = TRUE, showWarnings = FALSE)
      }

      # Write content
      writeLines(content, target_file)
      message("  \u2713 Created ", ai_files[[assistant]])
    }
  }

  invisible(NULL)
}


#' Load AI context template for a project type
#'
#' @param project_type Project type
#' @param project_name Project name for placeholder substitution
#' @return Character string with template content
#' @keywords internal
.load_ai_template <- function(project_type, project_name = "My Project") {
  template_dir <- system.file("templates", package = "framework")

  # New naming convention: ai-context.{type}.fr.md
  template_name <- sprintf("ai-context.%s.fr.md", project_type)
  template_file <- file.path(template_dir, template_name)

  # Fall back to generic project template

  if (!file.exists(template_file)) {
    template_file <- file.path(template_dir, "ai-context.project.fr.md")
  }

  # Final fallback to old template
  if (!file.exists(template_file)) {
    template_file <- file.path(template_dir, "AI_CANONICAL.fr.md")
  }

  if (!file.exists(template_file)) {
    return(sprintf("# %s\n\nFramework project.\n", project_name))
  }

  content <- paste(readLines(template_file, warn = FALSE), collapse = "\n")

  # Replace placeholders
  content <- gsub("\\{ProjectName\\}", project_name, content)

  content
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
#' Called during project_create() to check if AI instructions should be created.
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
