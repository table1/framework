#' Security audit for Framework projects
#'
#' Performs a comprehensive security audit of data files in Framework projects,
#' checking for unignored data files, git history leaks, and orphaned data files
#' outside configured directories.
#'
#' @param config_file Path to configuration file (default: "config.yml")
#' @param check_git_history Logical; if TRUE (default), check git history for leaked data files
#' @param history_depth Character or numeric. "all" for full history, "shallow" for recent 100 commits,
#'   or numeric for specific commit count (default: "all")
#' @param auto_fix Logical; if TRUE, automatically update .gitignore (default: FALSE)
#' @param verbose Logical; if TRUE (default), show progress messages
#' @param extensions Character vector of data file extensions to detect (default: common data formats)
#'
#' @return A structured list containing:
#'   \describe{
#'     \item{summary}{Data frame with check names, status (pass/warning/fail), and counts}
#'     \item{findings}{List of data frames with detailed findings for each check}
#'     \item{recommendations}{Character vector of actionable recommendations}
#'     \item{audit_metadata}{List with audit timestamp, Framework version, and config info}
#'   }
#'
#' @details
#' The security audit performs the following checks:
#' \itemize{
#'   \item **gitignore_coverage**: Verifies all private data files are in .gitignore
#'   \item **git_history**: Scans git history for accidentally committed data files
#'   \item **orphaned_files**: Finds data files outside configured directories
#'   \item **private_data_exposure**: Checks if private data is tracked by git
#' }
#'
#' Status levels:
#' \itemize{
#'   \item **pass**: No issues found
#'   \item **warning**: Potential issues that should be reviewed
#'   \item **fail**: Critical security issues requiring immediate action
#' }
#'
#' @examples
#' \dontrun{
#' # Basic audit (report only)
#' audit <- security_audit()
#' print(audit$summary)
#' View(audit$findings$orphaned_files)
#'
#' # Quick scan without git history
#' audit <- security_audit(check_git_history = FALSE)
#'
#' # Verbose with limited git history
#' audit <- security_audit(history_depth = 100, verbose = TRUE)
#'
#' # Auto-fix mode (updates .gitignore)
#' audit <- security_audit(auto_fix = TRUE)
#' }
#'
#' @export
security_audit <- function(config_file = "config.yml",
                           check_git_history = TRUE,
                           history_depth = "all",
                           auto_fix = FALSE,
                           verbose = TRUE,
                           extensions = c("csv", "rds", "tsv", "txt", "dat",
                                        "xlsx", "xls", "sqlite", "db",
                                        "dta", "sav", "zsav", "por",
                                        "sas7bdat", "sas7bcat", "xpt",
                                        "parquet", "feather", "arrow",
                                        "json", "xml", "h5", "hdf5")) {

  # Validate arguments
  checkmate::assert_string(config_file, min.chars = 1)
  checkmate::assert_logical(check_git_history, len = 1)
  checkmate::assert(
    checkmate::check_string(history_depth),
    checkmate::check_number(history_depth, lower = 1)
  )
  checkmate::assert_logical(auto_fix, len = 1)
  checkmate::assert_logical(verbose, len = 1)
  checkmate::assert_character(extensions, min.len = 1)

  # Initialize results structure
  findings <- list(
    gitignore_issues = data.frame(
      file = character(),
      directory = character(),
      severity = character(),
      reason = character(),
      stringsAsFactors = FALSE
    ),
    git_history_issues = data.frame(
      commit = character(),
      file = character(),
      action = character(),
      date = character(),
      stringsAsFactors = FALSE
    ),
    orphaned_files = data.frame(
      path = character(),
      size = numeric(),
      modified = character(),
      extension = character(),
      stringsAsFactors = FALSE
    ),
    private_data_exposure = data.frame(
      file = character(),
      directory = character(),
      git_status = character(),
      stringsAsFactors = FALSE
    )
  )

  recommendations <- character()

  # Check if config exists
  if (!file.exists(config_file)) {
    stop(sprintf("Config file not found: %s", config_file))
  }

  # Check git availability
  git_available <- .check_git_available()
  if (check_git_history && !git_available) {
    warning("Git not available. Skipping git history checks.")
    check_git_history <- FALSE
  }

  if (verbose) {
    message("=== Framework Security Audit ===\n")
  }

  # Read configuration
  config <- tryCatch(
    read_config(config_file),
    error = function(e) {
      stop(sprintf("Failed to read config file: %s", e$message))
    }
  )

  # Get data directories from config
  data_dirs <- .get_data_directories(config, verbose)

  # Check 1: gitignore coverage
  if (verbose) message("Checking .gitignore coverage...")
  gitignore_findings <- .check_gitignore_coverage(data_dirs, extensions, verbose)
  findings$gitignore_issues <- gitignore_findings$issues
  if (nrow(gitignore_findings$issues) > 0) {
    recommendations <- c(recommendations, gitignore_findings$recommendations)
  }

  # Check 2: Private data exposure (git tracking)
  if (verbose) message("Checking for exposed private data...")
  exposure_findings <- .check_private_data_exposure(data_dirs, git_available, verbose)
  findings$private_data_exposure <- exposure_findings$issues
  if (nrow(exposure_findings$issues) > 0) {
    recommendations <- c(recommendations, exposure_findings$recommendations)
  }

  # Check 3: Git history leaks
  if (check_git_history && git_available) {
    if (verbose) message("Scanning git history for data file leaks...")
    history_findings <- .check_git_history(data_dirs, extensions, history_depth, verbose)
    findings$git_history_issues <- history_findings$issues
    if (nrow(history_findings$issues) > 0) {
      recommendations <- c(recommendations, history_findings$recommendations)
    }
  }

  # Check 4: Orphaned data files
  if (verbose) message("Scanning for orphaned data files...")
  orphan_findings <- .scan_for_orphaned_files(data_dirs, extensions, verbose)
  findings$orphaned_files <- orphan_findings$files
  if (nrow(orphan_findings$files) > 0) {
    recommendations <- c(recommendations, orphan_findings$recommendations)
  }

  # Build summary
  summary <- data.frame(
    check = c("gitignore_coverage", "private_data_exposure", "git_history", "orphaned_files"),
    status = c(
      if (nrow(findings$gitignore_issues) == 0) "pass" else if (any(findings$gitignore_issues$severity == "critical")) "fail" else "warning",
      if (nrow(findings$private_data_exposure) == 0) "pass" else "fail",
      if (!check_git_history) "skipped" else if (nrow(findings$git_history_issues) == 0) "pass" else "fail",
      if (nrow(findings$orphaned_files) == 0) "pass" else "warning"
    ),
    count = c(
      nrow(findings$gitignore_issues),
      nrow(findings$private_data_exposure),
      nrow(findings$git_history_issues),
      nrow(findings$orphaned_files)
    ),
    stringsAsFactors = FALSE
  )

  # Auto-fix if requested
  if (auto_fix && (nrow(findings$gitignore_issues) > 0 || nrow(findings$private_data_exposure) > 0)) {
    if (verbose) message("\nApplying auto-fix...")
    .apply_auto_fix(findings, verbose)
    recommendations <- c(recommendations, "Run git status to review .gitignore changes")
  }

  # Build audit result
  result <- list(
    summary = summary,
    findings = findings,
    recommendations = unique(recommendations),
    audit_metadata = list(
      timestamp = Sys.time(),
      framework_version = as.character(packageVersion("framework")),
      config_directories = data_dirs,
      git_available = git_available,
      auto_fix_applied = auto_fix
    )
  )

  # Print summary if verbose
  if (verbose) {
    .print_audit_summary(result)
  }

  # Store audit in framework database
  tryCatch({
    .save_audit_result(result)
  }, error = function(e) {
    # Don't fail audit if database save fails
    if (verbose) message("Note: Could not save audit to framework database")
  })

  invisible(result)
}


#' Check if git is available
#' @keywords internal
.check_git_available <- function() {
  git_check <- tryCatch(
    {
      system2("git", "--version", stdout = TRUE, stderr = TRUE)
      TRUE
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )

  # Check if we're in a git repository using git rev-parse
  in_git_repo <- tryCatch(
    {
      result <- system2("git", c("rev-parse", "--git-dir"), stdout = TRUE, stderr = FALSE)
      length(result) > 0
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )

  git_check && in_git_repo
}


#' Get data directories from config
#' @keywords internal
.get_data_directories <- function(config, verbose) {
  # Standard directory keys to check
  dir_keys <- c(
    "data_source_public",
    "data_source_private",
    "data_in_progress_public",
    "data_in_progress_private",
    "data_final_public",
    "data_final_private",
    "results_public",
    "results_private",
    "cache",
    "scratch"
  )

  dirs <- list()
  for (key in dir_keys) {
    # Try to get directory from config
    dir_path <- tryCatch(
      config(paste0("directories.", key), config_file = "config.yml"),
      error = function(e) NULL
    )

    if (!is.null(dir_path) && nchar(dir_path) > 0) {
      dirs[[key]] <- dir_path
    }
  }

  # Add common fallback directories if not in config
  fallback_dirs <- list(
    data_source_private = "data/source/private",
    data_in_progress_private = "data/in_progress/private",
    data_final_private = "data/final/private",
    results_private = "results/private"
  )

  for (key in names(fallback_dirs)) {
    if (!key %in% names(dirs) && dir.exists(fallback_dirs[[key]])) {
      dirs[[key]] <- fallback_dirs[[key]]
    }
  }

  if (verbose && length(dirs) > 0) {
    message(sprintf("Monitoring %d data directories", length(dirs)))
  }

  dirs
}


#' Check gitignore coverage for data files
#' @keywords internal
.check_gitignore_coverage <- function(data_dirs, extensions, verbose) {
  issues <- data.frame(
    file = character(),
    directory = character(),
    severity = character(),
    reason = character(),
    stringsAsFactors = FALSE
  )

  recommendations <- character()

  # Read .gitignore if it exists
  if (!file.exists(".gitignore")) {
    recommendations <- c(recommendations, "Create a .gitignore file to protect sensitive data")
    return(list(issues = issues, recommendations = recommendations))
  }

  gitignore_patterns <- readLines(".gitignore", warn = FALSE)

  # Check each private data directory
  private_dirs <- data_dirs[grepl("private", names(data_dirs))]

  for (dir_name in names(private_dirs)) {
    dir_path <- private_dirs[[dir_name]]

    if (!dir.exists(dir_path)) {
      next
    }

    # Check if directory itself is ignored
    is_ignored <- .check_path_ignored(dir_path, gitignore_patterns)

    if (!is_ignored) {
      issues <- rbind(issues, data.frame(
        file = dir_path,
        directory = dir_name,
        severity = "critical",
        reason = "Private data directory not in .gitignore",
        stringsAsFactors = FALSE
      ))
    }

    # Check files within directory
    files <- list.files(dir_path, recursive = TRUE, full.names = TRUE)
    for (file in files) {
      if (.is_data_file(file, extensions)) {
        if (!.check_path_ignored(file, gitignore_patterns)) {
          issues <- rbind(issues, data.frame(
            file = file,
            directory = dir_name,
            severity = "critical",
            reason = "Private data file not in .gitignore",
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }

  if (nrow(issues) > 0) {
    recommendations <- c(
      recommendations,
      "Add private data directories to .gitignore",
      "Review all private data files for git tracking"
    )
  }

  list(issues = issues, recommendations = recommendations)
}


#' Check if private data is tracked by git
#' @keywords internal
.check_private_data_exposure <- function(data_dirs, git_available, verbose) {
  issues <- data.frame(
    file = character(),
    directory = character(),
    git_status = character(),
    stringsAsFactors = FALSE
  )

  recommendations <- character()

  if (!git_available) {
    return(list(issues = issues, recommendations = recommendations))
  }

  # Get all tracked files
  tracked_files <- tryCatch(
    system2("git", c("ls-files"), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )

  if (length(tracked_files) == 0) {
    return(list(issues = issues, recommendations = recommendations))
  }

  # Check each private directory
  private_dirs <- data_dirs[grepl("private", names(data_dirs))]

  for (dir_name in names(private_dirs)) {
    dir_path <- private_dirs[[dir_name]]

    if (!dir.exists(dir_path)) {
      next
    }

    # Check if any tracked files are in this private directory
    exposed_files <- tracked_files[startsWith(tracked_files, dir_path)]

    for (file in exposed_files) {
      issues <- rbind(issues, data.frame(
        file = file,
        directory = dir_name,
        git_status = "tracked",
        stringsAsFactors = FALSE
      ))
    }
  }

  if (nrow(issues) > 0) {
    recommendations <- c(
      recommendations,
      "CRITICAL: Private data files are tracked by git!",
      "Run: git rm --cached <file> to untrack files",
      "Add files to .gitignore before committing"
    )
  }

  list(issues = issues, recommendations = recommendations)
}


#' Check git history for leaked data files
#' @keywords internal
.check_git_history <- function(data_dirs, extensions, history_depth, verbose) {
  issues <- data.frame(
    commit = character(),
    file = character(),
    action = character(),
    date = character(),
    stringsAsFactors = FALSE
  )

  recommendations <- character()

  # Build pattern for data file extensions
  ext_pattern <- paste0("\\.(", paste(extensions, collapse = "|"), ")$")

  # Determine depth argument
  depth_arg <- if (is.numeric(history_depth)) {
    as.character(history_depth)
  } else if (history_depth == "shallow") {
    "100"
  } else {
    NULL  # All history
  }

  # Build git log command
  git_args <- c(
    "log",
    "--all",
    "--pretty=format:%H|%ai|%s",
    "--name-status"
  )

  if (!is.null(depth_arg)) {
    git_args <- c(git_args, paste0("-", depth_arg))
  }

  # Get git log
  log_output <- tryCatch(
    system2("git", git_args, stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )

  if (length(log_output) == 0) {
    return(list(issues = issues, recommendations = recommendations))
  }

  # Parse git log output
  current_commit <- NULL
  current_date <- NULL

  for (line in log_output) {
    # Check if this is a commit line
    if (grepl("^[a-f0-9]{40}\\|", line)) {
      parts <- strsplit(line, "\\|")[[1]]
      current_commit <- substr(parts[1], 1, 8)  # Short hash
      current_date <- parts[2]
    } else if (grepl("^[AMD]\t", line) && !is.null(current_commit)) {
      # This is a file change line
      parts <- strsplit(line, "\t")[[1]]
      action <- parts[1]
      file <- parts[2]

      # Check if it's a data file in a private directory
      if (grepl(ext_pattern, file, ignore.case = TRUE)) {
        # Check if file is in any private directory
        is_private <- any(sapply(names(data_dirs)[grepl("private", names(data_dirs))], function(dir_name) {
          startsWith(file, data_dirs[[dir_name]])
        }))

        if (is_private || grepl("(private|secret|confidential)", file, ignore.case = TRUE)) {
          issues <- rbind(issues, data.frame(
            commit = current_commit,
            file = file,
            action = switch(action,
                          "A" = "added",
                          "M" = "modified",
                          "D" = "deleted",
                          action),
            date = current_date,
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }

  if (nrow(issues) > 0) {
    recommendations <- c(
      recommendations,
      "CRITICAL: Private data files found in git history!",
      "Consider using git-filter-repo or BFG Repo-Cleaner to remove sensitive data",
      "Consult: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository"
    )
  }

  list(issues = issues, recommendations = recommendations)
}


#' Scan for orphaned data files outside configured directories
#' @keywords internal
.scan_for_orphaned_files <- function(data_dirs, extensions, verbose) {
  orphaned <- data.frame(
    path = character(),
    size = numeric(),
    modified = character(),
    extension = character(),
    stringsAsFactors = FALSE
  )

  recommendations <- character()

  # Build pattern for data files
  ext_pattern <- paste0("\\.(", paste(extensions, collapse = "|"), ")$")

  # Directories to exclude from scan
  exclude_dirs <- c(
    ".git", ".Rproj.user", "renv", "packrat",
    ".framework_cache", ".quarto", "_cache", "_files"
  )

  # Get all configured directory paths
  configured_paths <- unlist(data_dirs, use.names = FALSE)

  # Scan project root
  all_files <- list.files(".", recursive = TRUE, full.names = TRUE, include.dirs = FALSE)

  for (file in all_files) {
    # Skip excluded directories
    if (any(sapply(exclude_dirs, function(d) grepl(paste0("^\\./", d), file)))) {
      next
    }

    # Check if it's a data file
    if (grepl(ext_pattern, file, ignore.case = TRUE)) {
      # Check if it's in any configured directory
      in_configured_dir <- any(sapply(configured_paths, function(d) {
        startsWith(file, paste0("./", d)) || startsWith(file, d)
      }))

      if (!in_configured_dir) {
        file_info <- file.info(file)
        orphaned <- rbind(orphaned, data.frame(
          path = sub("^\\./", "", file),
          size = file_info$size,
          modified = as.character(file_info$mtime),
          extension = tools::file_ext(file),
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  if (nrow(orphaned) > 0) {
    recommendations <- c(
      recommendations,
      sprintf("Found %d data file(s) outside configured directories", nrow(orphaned)),
      "Move orphaned files to appropriate data directories",
      "Add data file locations to config.yml if they represent new data storage"
    )
  }

  list(files = orphaned, recommendations = recommendations)
}


#' Check if path is ignored by .gitignore patterns
#' @keywords internal
.check_path_ignored <- function(path, gitignore_patterns) {
  # Normalize path
  path <- gsub("^\\./", "", path)

  is_ignored <- FALSE

  # Check each pattern
  for (pattern in gitignore_patterns) {
    # Skip comments and empty lines
    if (grepl("^\\s*#", pattern) || grepl("^\\s*$", pattern)) {
      next
    }

    # Handle negation patterns
    is_negation <- startsWith(pattern, "!")
    if (is_negation) {
      pattern <- substring(pattern, 2)
    }

    # Store original pattern for directory matching
    orig_pattern <- pattern

    # Convert gitignore pattern to regex
    pattern <- gsub("\\.", "\\\\.", pattern)  # Escape dots
    pattern <- gsub("\\*\\*/", "(.*/)?", pattern)  # ** matches any subdirectory
    pattern <- gsub("\\*", "[^/]*", pattern)  # * matches anything except /

    # Handle trailing slash (directory pattern)
    if (grepl("/$", orig_pattern)) {
      # Remove trailing / and match the directory path or anything under it
      dir_pattern <- sub("/$", "", pattern)
      # Match: exact directory name, or directory/ or directory/anything
      pattern <- paste0(dir_pattern, "(/.*)?")
    }

    # Check if path matches
    if (grepl(paste0("^", pattern, "$"), path)) {
      if (is_negation) {
        is_ignored <- FALSE  # Negation overrides previous ignores
      } else {
        is_ignored <- TRUE
      }
    }
  }

  is_ignored
}


#' Check if file is a data file based on extension
#' @keywords internal
.is_data_file <- function(file, extensions) {
  ext <- tolower(tools::file_ext(file))
  ext %in% extensions
}


#' Apply auto-fix for common issues
#' @keywords internal
.apply_auto_fix <- function(findings, verbose) {
  gitignore_path <- ".gitignore"

  # Create .gitignore if it doesn't exist
  if (!file.exists(gitignore_path)) {
    writeLines("", gitignore_path)
  }

  existing <- readLines(gitignore_path, warn = FALSE)

  # Collect directories to add
  dirs_to_add <- character()

  # Add any private directories not in gitignore
  for (i in seq_len(nrow(findings$gitignore_issues))) {
    issue <- findings$gitignore_issues[i, ]
    if (issue$severity == "critical" && !issue$file %in% dirs_to_add) {
      dirs_to_add <- c(dirs_to_add, issue$file)
    }
  }

  # Add exposed private data directories
  for (i in seq_len(nrow(findings$private_data_exposure))) {
    issue <- findings$private_data_exposure[i, ]
    dir_path <- dirname(issue$file)
    if (!dir_path %in% dirs_to_add) {
      dirs_to_add <- c(dirs_to_add, dir_path)
    }
  }

  if (length(dirs_to_add) > 0) {
    # Add header if not present
    if (!any(grepl("# Framework Security Audit", existing))) {
      new_entries <- c(
        "",
        "# Framework Security Audit - Auto-generated",
        paste0(dirs_to_add, "/"),
        paste0(dirs_to_add, "/**")
      )

      writeLines(c(existing, new_entries), gitignore_path)

      if (verbose) {
        message(sprintf("Added %d director%s to .gitignore",
                       length(dirs_to_add),
                       if (length(dirs_to_add) == 1) "y" else "ies"))
      }
    }
  }

  invisible(NULL)
}


#' Print audit summary
#' @keywords internal
.print_audit_summary <- function(result) {
  message("\n=== Security Audit Summary ===\n")

  for (i in seq_len(nrow(result$summary))) {
    check <- result$summary[i, ]
    status_icon <- switch(check$status,
                         "pass" = "\u2713",
                         "warning" = "\u26A0",
                         "fail" = "\u2717",
                         "skipped" = "-")

    status_label <- switch(check$status,
                          "pass" = "PASS",
                          "warning" = "WARNING",
                          "fail" = "FAIL",
                          "skipped" = "SKIPPED")

    message(sprintf("%s %s: %s (%d issues)",
                   status_icon,
                   status_label,
                   gsub("_", " ", check$check),
                   check$count))
  }

  # Show detailed findings for issues
  has_issues <- FALSE

  if (nrow(result$findings$gitignore_issues) > 0) {
    has_issues <- TRUE
    message("\n--- Gitignore Coverage Issues ---")
    for (i in seq_len(nrow(result$findings$gitignore_issues))) {
      issue <- result$findings$gitignore_issues[i, ]
      message(sprintf("  %d. [%s] %s",
                     i,
                     toupper(issue$severity),
                     issue$file))
      message(sprintf("     Directory: %s", issue$directory))
      message(sprintf("     Reason: %s\n", issue$reason))
    }
  }

  if (nrow(result$findings$private_data_exposure) > 0) {
    has_issues <- TRUE
    message("\n--- Private Data Exposure (Git Tracked) ---")
    for (i in seq_len(nrow(result$findings$private_data_exposure))) {
      issue <- result$findings$private_data_exposure[i, ]
      message(sprintf("  %d. %s (tracked in git)",
                     i,
                     issue$file))
      message(sprintf("     Directory: %s\n", issue$directory))
    }
  }

  if (nrow(result$findings$git_history_issues) > 0) {
    has_issues <- TRUE
    message("\n--- Git History Leaks ---")
    for (i in seq_len(min(10, nrow(result$findings$git_history_issues)))) {
      issue <- result$findings$git_history_issues[i, ]
      message(sprintf("  %d. %s (%s in commit %s)",
                     i,
                     issue$file,
                     issue$action,
                     issue$commit))
      message(sprintf("     Date: %s\n", issue$date))
    }
    if (nrow(result$findings$git_history_issues) > 10) {
      message(sprintf("     ... and %d more issues in git history\n",
                     nrow(result$findings$git_history_issues) - 10))
    }
  }

  if (nrow(result$findings$orphaned_files) > 0) {
    has_issues <- TRUE
    message("\n--- Orphaned Data Files ---")
    for (i in seq_len(min(10, nrow(result$findings$orphaned_files)))) {
      issue <- result$findings$orphaned_files[i, ]
      size_kb <- round(issue$size / 1024, 1)
      message(sprintf("  %d. %s (%s KB, .%s)",
                     i,
                     issue$path,
                     size_kb,
                     issue$extension))
    }
    if (nrow(result$findings$orphaned_files) > 10) {
      message(sprintf("     ... and %d more orphaned files\n",
                     nrow(result$findings$orphaned_files) - 10))
    }
    message("")
  }

  # Show recommendations
  if (length(result$recommendations) > 0) {
    message("\n=== Recommendations ===\n")
    for (i in seq_along(result$recommendations)) {
      message(sprintf("  %d. %s", i, result$recommendations[i]))
    }
  }

  # Overall status
  has_failures <- any(result$summary$status == "fail")
  has_warnings <- any(result$summary$status == "warning")

  message("")
  if (has_failures) {
    message("\u2717 AUDIT FAILED - Critical security issues found")
    message("\nTo view detailed findings:")
    message("  audit <- security_audit()")
    message("  View(audit$findings$gitignore_issues)")
    message("  View(audit$findings$private_data_exposure)")
  } else if (has_warnings) {
    message("\u26A0 AUDIT PASSED WITH WARNINGS - Review findings")
    message("\nTo view detailed findings:")
    message("  audit <- security_audit()")
    message("  View(audit$findings$orphaned_files)")
  } else {
    message("\u2713 AUDIT PASSED - No security issues found")
  }
  message("")
}


#' Save audit result to framework database
#' @keywords internal
.save_audit_result <- function(result) {
  if (!file.exists("framework.db")) {
    return(invisible(NULL))
  }

  # Store summary statistics
  .set_metadata("last_security_audit", as.character(result$audit_metadata$timestamp))

  overall_status <- if (any(result$summary$status == "fail")) {
    "fail"
  } else if (any(result$summary$status == "warning")) {
    "warning"
  } else {
    "pass"
  }

  .set_metadata("last_audit_status", overall_status)
  .set_metadata("last_audit_issues", sum(result$summary$count))

  invisible(NULL)
}
