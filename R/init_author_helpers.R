.resolve_project_author <- function(target_dir = ".") {
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)

  if (!is.null(target_dir) && nzchar(target_dir) && target_dir != ".") {
    if (dir.exists(target_dir)) {
      setwd(target_dir)
    }
  }

  cfg <- tryCatch(read_config(), error = function(e) NULL)
  author_name <- cfg$author$name
  if (is.null(author_name) || !nzchar(author_name)) {
    author_name <- "Your Name"
  }
  author_name
}

.replace_author_placeholders <- function(target_dir = ".") {
  author_name <- .resolve_project_author(target_dir)

  if (is.null(author_name) || !nzchar(author_name)) {
    return(invisible(NULL))
  }

  notebook_files <- list.files(
    path = target_dir,
    pattern = "\\.(qmd|QMD|Rmd|rmd)$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(notebook_files) == 0) {
    return(invisible(NULL))
  }

  pattern <- 'author:\\s*("Your Name"|!expr config\\$author\\$name|"`r config\\$author\\$name`")'
  replacement <- sprintf('author: "%s"', author_name)

  for (file in notebook_files) {
    lines <- readLines(file, warn = FALSE)
    new_lines <- gsub(pattern, replacement, lines)
    if (!identical(lines, new_lines)) {
      writeLines(new_lines, file)
    }
  }

  invisible(NULL)
}
