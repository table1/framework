# docs/site is the r.framework.pub docs site (format: inst/schema/docs-site.md).
# docs/ is not in the package tarball, so these run from a checkout only.

site_dir <- function() testthat::test_path("..", "..", "docs", "site")

read_guide <- function(path) {
  lines <- readLines(path, warn = FALSE)
  ends <- which(lines == "---")
  list(
    meta = yaml::yaml.load(paste(lines[(ends[1] + 1):(ends[2] - 1)], collapse = "\n")),
    body = lines[-seq_len(ends[2])]
  )
}

test_that("the guides follow the docs-site format", {
  skip_if_not(dir.exists(site_dir()), "docs/site is not in the package tarball")
  site <- yaml::read_yaml(file.path(site_dir(), "site.yml"))
  expect_identical(site$product, "r")
  section_ids <- vapply(site$sections, `[[`, "", "id")

  paths <- list.files(file.path(site_dir(), "guides"), "\\.md$", full.names = TRUE)
  expect_gt(length(paths), 0)
  guides <- lapply(paths, read_guide)
  ids <- vapply(guides, function(g) g$meta$id, "")
  expect_identical(anyDuplicated(ids), 0L)
  expect_identical(ids, sub("\\.md$", "", basename(paths)))

  problems <- character()
  problem <- function(id, ...) problems <<- c(problems, paste0(id, ": ", ...))
  for (g in guides) {
    m <- g$meta
    if (!grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", m$id)) problem(m$id, "id is not URL-safe")
    for (field in c("title", "description")) {
      if (!is.character(m[[field]]) || !nzchar(m[[field]])) problem(m$id, "no ", field)
    }
    if (!isTRUE(m$section %in% section_ids)) problem(m$id, "unknown section ", m$section)
    if (!is.numeric(m$position)) problem(m$id, "no position")

    # Outside code blocks: no h1, and every guide link has a target
    fence <- NULL
    for (line in g$body) {
      opener <- regmatches(line, regexpr("^`{3,}", line))
      info <- trimws(sub("^`+", "", line))
      if (length(opener) == 1) {
        if (is.null(fence)) {
          fence <- opener
          if (!nzchar(info)) problem(m$id, "code fence without a language")
        } else if (opener == fence && !nzchar(info)) {
          fence <- NULL
        }
        next
      }
      if (!is.null(fence)) next
      if (grepl("^# ", line)) problem(m$id, "h1 heading: ", line)
      targets <- regmatches(line, gregexpr("\\]\\(guide:[^)#]+", line))[[1]]
      for (t in setdiff(sub("^\\]\\(guide:", "", targets), ids)) {
        problem(m$id, "links to missing guide ", t)
      }
      if (grepl("\\]\\(/", line)) problem(m$id, "site-absolute link: ", line)
    }
    if (!is.null(fence)) problem(m$id, "unclosed code fence")
  }
  expect_identical(problems, character())
})

test_that("docs_export() writes a reference that passes the shared schema", {
  skip_if_not_installed("jsonvalidate")
  root <- normalizePath(testthat::test_path("..", ".."))
  skip_if_not(file.exists(file.path(root, "NAMESPACE")) && dir.exists(file.path(root, "man")),
              "man/ and NAMESPACE are needed to build the reference")
  dir <- withr::local_tempdir()
  # docs_export() reads man/ and NAMESPACE from the working directory
  withr::local_dir(root)
  db <- file.path(dir, "docs.db")
  ref <- file.path(dir, "reference.json")
  docs_export(db, package_version = "2.0.0", verbose = FALSE, reference_path = ref)

  schema <- system.file("schema", "docs-reference.v1.json", package = "framework")
  v <- jsonvalidate::json_schema$new(schema, engine = "ajv")
  expect_true(v$validate(paste(readLines(ref), collapse = "\n")))

  r <- jsonlite::read_json(ref)
  entries <- stats::setNames(r$entries, vapply(r$entries, `[[`, "", "name"))
  b <- entries$bootstrap
  expect_identical(b$id, "bootstrap")
  expect_identical(b$category, "project-management")
  expect_identical(b$parameters[[1]]$default, "\".\"")
  expect_true("new" %in% unlist(b$see_also))
  expect_identical(entries$ai_sync_context$lifecycle, "deprecated")
  expect_false(any(startsWith(names(entries), ".")))
  expect_false(any(vapply(r$entries, function(e) identical(e$category, "other"), TRUE)))
})
