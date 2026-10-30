# framework (development version)

* Project specs: `spec_resolve()` merges spec layers over the package
  defaults, `spec_check()` reports problems, `project_create()` accepts a
  resolved spec, and `project_create_from_layers()` creates a project from a
  framework.pub layers file (headless mode for GitHub Actions). JSON Schemas
  for specs and layers ship in `inst/schema/`
* Sensitive projects (`security.sensitive`) get Claude Code deny rules and a
  fail-closed sandbox that keep the agent out of restricted directories
* Quarto notebooks, slides, and presentation projects get a full Quarto
  author block (`orcid`, `url`, and `affiliations` with department, city,
  and country) when author settings have those details. With only name,
  email, and affiliation, the one-line `author: "Name"` is unchanged. The
  spec and layers schemas accept the new author fields
* Opt-in framework.pub cloud integration (planned for 2.0): `cloud_login()`,
  `cloud_logout()`, `cloud_status()`, `cloud_settings()`, `cloud_sync()`,
  `ledger_push()`, `ledger_list()`, `data_verify()`, and `setup()` with a
  project token. Nothing contacts the cloud unless you connect explicitly

# framework 1.1.0

* `plumber` moved from Imports to Suggests. plumber pulls in `sodium`, which
  needs the system libsodium library and often fails to install on HPC
  clusters. The GUI (`gui()`, `setup()`) now asks you to install plumber when
  you launch it; nothing else needs it
* New standard `logs` directory for run logs and cluster job output. All
  project gitignore templates now ignore `**/logs/**` and `slurm-*.out`, and
  `security_audit()` treats `logs` as a private directory
* `scaffold()` git checks are now portable across platforms
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
