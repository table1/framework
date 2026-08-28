# Render smoke tests for the framework package, run inside the Docker
# container (see docker/compose.yml). Exercises project creation and Quarto
# rendering on clean Linux.

`%||%` <- function(a, b) if (is.null(a)) b else a

ok <- function(label, cond) {
  cat(sprintf("[%s] %s\n", if (isTRUE(cond)) "PASS" else "FAIL", label))
  if (!isTRUE(cond)) quit(status = 1, save = "no")
}

work <- tempfile("render-test-")
dir.create(work)
Sys.setenv(FW_CONFIG_HOME = file.path(work, "config"))

suppressMessages(devtools::load_all("/opt/framework", quiet = TRUE))

# 1. Quarto is present
ok("quarto on PATH", nzchar(Sys.which("quarto")))

# 2. Bare project creation works on Linux
bare_dir <- file.path(work, "bare-proj")
new("bare-proj", location = bare_dir, type = "bare", browse = FALSE)
ok("bare project settings.yml", file.exists(file.path(bare_dir, "settings.yml")))

# 3. Full project creation works on Linux
proj_dir <- file.path(work, "full-proj")
new("full-proj", location = proj_dir, type = "project", browse = FALSE)
ok("full project scaffold.R", file.exists(file.path(proj_dir, "scaffold.R")))
ok("full project quarto config", file.exists(file.path(proj_dir, "_quarto.yml")))

# 4. A notebook in the project renders to self-contained HTML
qmd <- file.path(proj_dir, "notebooks", "smoke.qmd")
dir.create(dirname(qmd), recursive = TRUE, showWarnings = FALSE)
writeLines(c(
  "---",
  "title: Render Smoke",
  "format:",
  "  html:",
  "    embed-resources: true",
  "---",
  "",
  "```{r}",
  "summary(cars)",
  "plot(cars)",
  "```"
), qmd)

out_dir <- file.path(work, "rendered")
dir.create(out_dir)
status <- system2("quarto", c("render", qmd, "--output-dir", out_dir, "--to", "html"))
ok("quarto render exit 0", identical(status, 0L))

html <- list.files(out_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
ok("rendered HTML exists", length(html) >= 1)
ok("HTML is self-contained (>100kB)", file.size(html[1]) > 100000)

cat("\nALL RENDER TESTS PASSED\n")
