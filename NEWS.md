# framework 1.1.0

* Skills-based AI context: new projects get a thin canonical `AGENTS.md` plus
  Framework skills installed in `.claude/skills/` (workflow, data, packages,
  outputs, and sensitive-data rules as separate SKILL.md files)
* `AGENTS.md` replaces `CLAUDE.md` as the default canonical AI context file;
  CLAUDE.md and .github/copilot-instructions.md are now thin pointer stubs
* New `ai_skills_update()` refreshes a project's Framework skills after
  upgrading the package
* `ai_regenerate_context()` falls back to `CLAUDE.md` for projects created
  before 1.1.0

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
