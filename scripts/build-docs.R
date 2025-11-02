#!/usr/bin/env Rscript
# Build documentation from YAML sources to multiple targets
# Usage: Rscript scripts/build-docs.R

library(yaml)
library(jsonlite)
library(glue)

message("Building documentation from YAML sources...")

# Get all function docs
doc_files <- list.files("docs/content/functions", full.names = TRUE, pattern = "\\.yaml$")

if (length(doc_files) == 0) {
  stop("No YAML documentation files found in docs/content/functions/")
}

# Create output directories
dir.create("gui-dev/public/docs", recursive = TRUE, showWarnings = FALSE)
dir.create("docs/website/content/functions", recursive = TRUE, showWarnings = FALSE)

message(sprintf("Found %d function documentation files", length(doc_files)))

for (doc_file in doc_files) {
  doc <- read_yaml(doc_file)
  func_name <- doc$name

  message(sprintf("  Processing: %s", func_name))

  # ================================================================
  # 1. Generate JSON for GUI
  # ================================================================
  json_path <- glue("gui-dev/public/docs/{func_name}.json")
  write_json(doc, json_path, auto_unbox = TRUE, pretty = TRUE)

  # ================================================================
  # 2. Generate Markdown for public website
  # ================================================================

  # Build parameters table
  params_md <- ""
  if (!is.null(doc$params) && length(doc$params) > 0) {
    params_table <- paste(sapply(doc$params, function(p) {
      required <- if (!is.null(p$required) && p$required) " *(required)*" else ""
      default_val <- if (!is.null(p$default)) sprintf(" (default: `%s`)", p$default) else ""
      sprintf("- **`%s`** (%s)%s%s: %s",
              p$name, p$type, required, default_val, p$description)
    }), collapse = "\n")

    params_md <- glue("
## Parameters

{params_table}
")
  }

  # Build examples
  examples_md <- ""
  if (!is.null(doc$examples) && length(doc$examples) > 0) {
    examples_blocks <- paste(sapply(doc$examples, function(ex) {
      glue("
```r
{ex$code}
```

{ex$description}
")
    }), collapse = "\n\n")

    examples_md <- glue("
## Examples

{examples_blocks}
")
  }

  # Build related/see also
  related_md <- ""
  if (!is.null(doc$see_also) && length(doc$see_also) > 0) {
    related_links <- paste(sapply(doc$see_also, function(r) {
      sprintf("- [`%s()`](%s) - %s", r$name, r$name, r$description)
    }), collapse = "\n")

    related_md <- glue("
## See Also

{related_links}
")
  }

  # Build details section
  details_md <- ""
  if (!is.null(doc$details)) {
    details_md <- glue("
## Details

{doc$details}
")
  }

  # Build notes section
  notes_md <- ""
  if (!is.null(doc$notes) && length(doc$notes) > 0) {
    notes_list <- paste(sapply(doc$notes, function(n) sprintf("- %s", n)), collapse = "\n")
    notes_md <- glue("
## Notes

{notes_list}
")
  }

  # Assemble full markdown
  website_md <- glue("---
title: {doc$title}
category: {doc$category}
tags: {paste(doc$tags, collapse = ', ')}
---

# {doc$title}

{doc$description}

## Usage

```r
{doc$usage}
```
{params_md}

## Returns

{doc$returns}
{details_md}{examples_md}{related_md}{notes_md}
")

  writeLines(website_md, glue("docs/website/content/functions/{func_name}.md"))

  # ================================================================
  # 3. Generate roxygen2 skeleton (optional - for reference)
  # ================================================================
  # Note: Actual R function files already have roxygen comments
  # This generates a reference skeleton for new functions

  params_roxygen <- ""
  if (!is.null(doc$params) && length(doc$params) > 0) {
    params_roxygen <- paste(sapply(doc$params, function(p) {
      sprintf("#' @param %s %s", p$name, p$description)
    }), collapse = "\n")
  }

  examples_roxygen <- ""
  if (!is.null(doc$examples) && length(doc$examples) > 0) {
    # Use first example for roxygen
    ex_code <- gsub("\\n", "\n#'   ", doc$examples[[1]]$code)
    examples_roxygen <- glue("#' @examples\n#'   {ex_code}")
  }

  see_also_roxygen <- ""
  if (!is.null(doc$related) && length(doc$related) > 0) {
    see_also_list <- paste(sprintf("\\code{\\link{%s}}", doc$related), collapse = ", ")
    see_also_roxygen <- sprintf("#' @seealso %s", see_also_list)
  }

  roxygen_skeleton <- glue("#' {doc$title}
#'
#' {gsub('\\n', '\\n#\\' ', doc$description)}
#'
{params_roxygen}
#'
#' @return {doc$returns}
#'
{see_also_roxygen}
#'
{examples_roxygen}
#'
#' @export
{func_name} <- function(...) {{
  # Implementation
}}
")

  # Save skeleton for reference (don't overwrite actual functions!)
  skeleton_dir <- "docs/roxygen-skeletons"
  dir.create(skeleton_dir, showWarnings = FALSE, recursive = TRUE)
  writeLines(roxygen_skeleton, glue("{skeleton_dir}/{func_name}.R"))
}

message("\nDocumentation build complete!")
message(sprintf("  - JSON files: gui-dev/public/docs/ (%d files)", length(doc_files)))
message(sprintf("  - Markdown files: docs/website/content/functions/ (%d files)", length(doc_files)))
message(sprintf("  - Roxygen skeletons: docs/roxygen-skeletons/ (%d files)", length(doc_files)))
message("\nNext steps:")
message("  1. Review generated files")
message("  2. Update actual R function roxygen comments if needed")
message("  3. Rebuild GUI: cd gui-dev && npm run build")
message("  4. Deploy website from docs/website/content/")
