# Generates the expected outputs for the layer-merge conformance fixtures in
# inst/conformance/merge/. Each case's input is hand-written JSON; this script
# runs R's merge (.spec_merge_layers, without package defaults) and writes the
# result next to it. Review the diff before committing: the expected output is
# the contract the Python package and fw are tested against.
#
# Run from the package root:  Rscript data-raw/conformance.R

devtools::load_all(quiet = TRUE)

dir <- file.path("inst", "conformance", "merge")
for (path in list.files(dir, pattern = "\\.json$", full.names = TRUE)) {
  case <- jsonlite::read_json(path, simplifyVector = FALSE)
  case$expected <- framework:::.conformance_merge(case$layers)
  json <- jsonlite::toJSON(case, auto_unbox = TRUE, null = "null", pretty = TRUE)
  writeLines(json, path)
  message("Wrote ", path)
}
