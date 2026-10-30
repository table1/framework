# Author details for settings and Quarto front matter.
#
# The basic fields are name, email, and affiliation (a plain string). The
# optional fields follow Quarto's author schema: orcid, url, and affiliations,
# a list of {name, department, city, country}. framework.pub's Profile tab
# fills these in, and keeps affiliation set to the first affiliation's name.

.author_affiliation_fields <- c("name", "department", "city", "country")

# Keep the known fields with non-empty values. Basic fields are always present
# (possibly ""); optional fields only when set.
#' @keywords internal
.author_normalize <- function(author) {
  author <- author %||% list()
  str_or <- function(x) if (is.character(x) && length(x) == 1 && !is.na(x)) x else ""

  out <- list(
    name = str_or(author$name),
    email = str_or(author$email),
    affiliation = str_or(author[["affiliation"]])
  )
  for (field in c("orcid", "url")) {
    value <- str_or(author[[field]])
    if (nzchar(value)) out[[field]] <- value
  }

  affiliations <- lapply(author$affiliations %||% list(), function(aff) {
    if (is.character(aff) && length(aff) == 1) aff <- list(name = aff)
    if (!is.list(aff)) return(NULL)
    aff <- lapply(aff[intersect(.author_affiliation_fields, names(aff))], str_or)
    aff <- aff[nzchar(unlist(aff))]
    if (!nzchar(aff$name %||% "")) return(NULL)
    aff
  })
  affiliations <- Filter(Negate(is.null), affiliations)
  if (length(affiliations) > 0) {
    out$affiliations <- affiliations
    if (!nzchar(out$affiliation)) out$affiliation <- affiliations[[1]]$name
  }

  out
}

# Overlay one author onto another. Strings replace when non-empty, and
# affiliations replace as a whole list (modifyList would keep the old list,
# because it can't match unnamed entries).
#' @keywords internal
.author_merge <- function(base, override) {
  base <- .author_normalize(base)
  override <- override %||% list()
  for (field in c("name", "email", "affiliation", "orcid", "url")) {
    value <- override[[field]]
    if (is.character(value) && length(value) == 1 && !is.na(value) && nzchar(value)) {
      base[[field]] <- value
    }
  }
  if (!is.null(override$affiliations)) {
    base$affiliations <- override$affiliations
    # The summary string follows the new list unless the override sets it.
    if (!nzchar(override[["affiliation"]] %||% "")) base$affiliation <- ""
  }
  .author_normalize(base)
}

# The author a new notebook should carry: project settings first, then the
# global settings, field by field.
#' @keywords internal
.author_resolve <- function(project_author = NULL) {
  global <- tryCatch(read_frameworkrc(use_defaults = TRUE)$author, error = function(e) NULL)
  # The package's default global settings carry placeholders; never write them.
  for (field in names(.author_placeholders)) {
    if (identical(global[[field]], .author_placeholders[[field]])) global[[field]] <- ""
  }
  .author_merge(global, project_author)
}

.author_placeholders <- list(
  name = "Your Name",
  email = "your.email@example.com",
  affiliation = "Your Institution"
)

.author_has_details <- function(author) {
  any(c("orcid", "url", "affiliations") %in% names(author))
}

.yaml_quote <- function(x) {
  sprintf('"%s"', gsub('"', '\\"', gsub("\\", "\\\\", x, fixed = TRUE), fixed = TRUE))
}

# Quarto front matter lines for the author. With only the basic fields this is
# the one line written before (`author: "Name"`); with orcid, url, or
# affiliations it is a full author block.
#' @keywords internal
.author_front_matter <- function(author, default_name = "Your Name") {
  author <- .author_normalize(author)
  name <- if (nzchar(author$name)) author$name else default_name

  if (!.author_has_details(author)) {
    return(sprintf("author: %s", .yaml_quote(name)))
  }

  lines <- c("author:", sprintf("  - name: %s", .yaml_quote(name)))
  for (field in c("email", "orcid", "url")) {
    value <- author[[field]] %||% ""
    if (nzchar(value)) lines <- c(lines, sprintf("    %s: %s", field, .yaml_quote(value)))
  }

  affiliations <- author$affiliations %||% list()
  if (length(affiliations) == 0 && nzchar(author[["affiliation"]])) {
    affiliations <- list(list(name = author[["affiliation"]]))
  }
  if (length(affiliations) > 0) {
    lines <- c(lines, "    affiliations:")
    for (aff in affiliations) {
      lines <- c(lines, sprintf("      - name: %s", .yaml_quote(aff$name)))
      for (field in setdiff(.author_affiliation_fields, "name")) {
        if (nzchar(aff[[field]] %||% "")) {
          lines <- c(lines, sprintf("        %s: %s", field, .yaml_quote(aff[[field]])))
        }
      }
    }
  }

  lines
}

# Replace a stub's `author: "{{ author }}"` line with the author front matter.
#' @keywords internal
.author_fill_stub <- function(lines, author, default_name = "Your Name") {
  hit <- grep('^author:\\s*"\\{\\{\\s*author\\s*\\}\\}"\\s*$', lines)
  if (length(hit) == 0) return(lines)
  block <- .author_front_matter(author, default_name)
  i <- hit[1]
  c(lines[seq_len(i - 1)], block, lines[seq.int(i + 1, length.out = length(lines) - i)])
}
