# framework 1.0.0

* First stable release
* Zero CRAN check errors/warnings (1 acceptable note for global config object)
* Complete documentation for all exported functions
* Comprehensive test suite (300+ tests)

# framework 0.10.1

* Fixed non-ASCII characters in R source files for CRAN compatibility
* Fixed documentation for `subdir` parameter in `make_rmd()`, `make_revealjs()`, and `make_presentation()`
* Added missing package declarations to DESCRIPTION Suggests
* Improved `scratch_capture()` examples with `\dontrun{}`

# framework 0.10.0

* Initial preparation for CRAN submission
* Comprehensive data management system with declarative YAML catalogs
* SQLite, PostgreSQL, MySQL, DuckDB database connectivity
* Quarto-first notebook generation with stub templates
* S3-compatible object storage publishing
* Project scaffolding with reproducible environments
* Caching system with expiration support
* Git hooks integration for data security
* GUI for project management (via `gui()`)
