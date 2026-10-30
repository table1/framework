# The layer-merge fixtures shared with the Python package and fw.

conformance_dir <- function() {
  dir <- system.file("conformance", "merge", package = "framework")
  if (!nzchar(dir)) dir <- testthat::test_path("..", "..", "inst", "conformance", "merge")
  dir
}

# Compare parsed JSON: key order ignored, {} equal to [], conflicts as a set.
normalize_json <- function(x) {
  if (is.list(x)) {
    if (length(x) == 0) return(list())
    if (!is.null(names(x))) {
      x <- x[order(names(x))]
    }
    return(lapply(x, normalize_json))
  }
  x
}

test_that("R's layer merge matches every conformance fixture", {
  files <- list.files(conformance_dir(), pattern = "\\.json$", full.names = TRUE)
  expect_gte(length(files), 5)

  for (path in files) {
    case <- jsonlite::read_json(path, simplifyVector = FALSE)
    actual <- jsonlite::fromJSON(
      jsonlite::toJSON(framework:::.conformance_merge(case$layers), auto_unbox = TRUE, null = "null"),
      simplifyVector = FALSE
    )
    expected <- case$expected
    sort_conflicts <- function(c) c[order(vapply(c, function(e) e$path, ""))]
    actual$conflicts <- sort_conflicts(actual$conflicts)
    expected$conflicts <- sort_conflicts(expected$conflicts)
    expect_identical(normalize_json(actual), normalize_json(expected), info = basename(path))
  }
})
