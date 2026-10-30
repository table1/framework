# framework (development version)

* `bootstrap()` prepares a cloned project: it makes sure `.gitignore`
  ignores `.env`, creates `.env` from `.env.example` and lists empty
  variables (or asks for them when interactive), creates the project folders,
  creates or upgrades `framework.db`, restores packages (renv.lock or
  settings.yml), and installs the enabled git hooks. It never contacts the
  cloud. From a shell: `Rscript -e 'framework::bootstrap(interactive = FALSE)'`
* The pre-commit hook is now a short POSIX `sh` script shared with the
  Python package and `fw` (`inst/hooks/pre-commit`). It finds an R or Python
  runtime and runs the checks enabled in settings.yml, so enabling or
  disabling a hook no longer needs a reinstall. `git_hooks_install()` writes
  it where git looks (worktrees and `core.hooksPath` included), replaces
  hooks Framework wrote earlier without `force`, and keeps any other hook
  unless `force = TRUE`
* `setup("fw_...")` and the new `new(key = ...)` create cloud projects from
  the project's layers (pull v2), resolved with `spec_resolve()`, so cloud
  projects get the same `.framework/spec.json` record as local ones. A
  Python or Stata cloud project stops with a pointer to the right tool
* Registering a new project with Framework Cloud now sends its language (`r`)
* `git_security_audit()` now fails `private_data_exposure` for any tracked
  data file under a folder whose name contains private, confidential, or
  sensitive, even when that folder is not a configured directory (for
  example `inputs/private` added with `git add -f`). Configured folders now
  match on whole path segments, so `inputs/raw` no longer covers
  `inputs/raw_public`. The orphan scan skips `node_modules`
* Global settings refuse values for secret-looking variables in
  `defaults.env` (names containing PASSWORD, SECRET, TOKEN, ACCESS_KEY,
  API_KEY, PRIVATE_KEY, or CREDENTIAL), as specs already do
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
* Self-hosted Framework Cloud servers: `cloud_login(token, url = )` and
  `setup(token, url = )` take a server URL, tokens are stored per server,
  and the server you log in to becomes the default. Projects record their
  server as `FW_CLOUD_URL` in `.env`, so publishing and the ledger go back
  to the server the project came from. Plain `http` is accepted only for
  `localhost` and `127.0.0.1`. `cloud_status()` reports the server in use
  and where that setting came from
* `publish_notebook()` publishes to Framework Cloud when the project has no
  storage bucket and was set up from Framework Cloud, as `publish()` does.
  With neither, both functions name the two ways to fix it
* `publish()` and `publish_notebook()` take `slug` for Framework Cloud:
  `slug = "main-results"` names the document and turns on its readable URL,
  `slug = TRUE` does the same with the name derived from the file, and
  `slug = FALSE` turns it off. Each publish adds a new version, and the
  message shows the version number and the link to share
* Specs record a primary `language` (`r`, `python`, or `stata`; a layers
  file without one means `r`). The R package builds R projects only and
  names the right tool for the others: the Python package, or `fw` for Stata
  scaffolding
* Layer-merge conformance fixtures in `inst/conformance/` pin the merge
  rules shared by the R package, the Python package, and `fw`
* New `config_sync()` copies user settings, the saved Framework Cloud server,
  and token files from the folder the Python package and `fw` use
  (`~/.config/framework`) into R's config folder, when theirs are missing
  from R's or newer. R only reads that folder and never writes to it, and
  `fw_config_dir()` stays on `tools::R_user_dir()` (or `FW_CONFIG_HOME`)
* Fixed (security): projects created with `new()`, `new_project()`, and the
  other `new_*()` helpers got no `.gitignore`, so `.env` (which holds
  database passwords and the Framework Cloud project token) was committed
  in the initial commit. 1.1.0 is affected. Every project now gets the
  `.gitignore` for its type, and creation checks that `.env` is ignored
  before the first commit. `git_security_audit()` has a new
  `secrets_exposure` check that fails when git tracks a `.env` file.
  A later `!.env` line cannot re-include it: the last line that mentions
  `.env` decides, and creation asks git (`git check-ignore`) before the
  first commit and skips the commit if `.env` is still not ignored
* `spec_check()` rejects values for secret-looking environment variables
  (names containing PASSWORD, SECRET, TOKEN, ACCESS_KEY, API_KEY, PRIVATE_KEY, or
  CREDENTIAL). Specs pass through the cloud and into git, so those values
  belong in `.env`
* Fixed: `scaffold()` never set the random seed for new projects, which
  store `seed_on_scaffold` and `seed` under `scaffold:`. A project's own
  seed now also takes precedence over the user-wide `FW_SEED`, as
  documented, and `seed_on_scaffold: false` turns seeding off even when
  `FW_SEED` is set
* Fixed: `data_add()` recorded absolute paths in the data catalog, which
  broke once a project was moved or cloned. Paths inside the project are now
  stored relative to the project root
* `spec.v1.json` requires `render_dirs`, `packages`, `scaffold`, and
  `connections` only for R and Python specs, so Stata specs (scaffolded by
  `fw`) leave them out. In `layers.v1.json`, a layer's `kind` is optional,
  and `source.fw_version` records the `fw` version for Stata projects
* Spec schemas accept what Python projects need: `pypi` package sources and
  wider package names, `.py` data hooks, `jupyter` notebooks, and
  `source.origin: python`. `packages.use_renv`, `scaffold.set_theme_on_scaffold`,
  and `scaffold.ggplot_theme` are optional. R's `spec_check()` still accepts
  only what R can build
* `publish()`, `publish_notebook()`, `publish_dir()`, and `publish_data()`
  refuse a source inside a folder named `private` in the project, which
  holds restricted data. `allow_private = TRUE` publishes it anyway
* S3 uploads retry without the `public-read` ACL when the bucket has ACLs
  disabled (the AWS default for new buckets), leaving access to the bucket
  policy. They used to fail
* Fixed: projects created from a spec wrote `settings/connections.yml`
  without its `connections:` wrapper, so `db_connect()`, `db_list()`,
  `connections_list()`, and storage lookups found no connections. New
  projects get the wrapper, and `settings_read()` repairs projects already
  created that way
* Fixed: `save_table()`, `save_figure()`, `save_model()`, and the other
  `save_*()` helpers never recorded their outputs in `framework.db` when no
  comment was given, and `result_list()` without filters always returned an
  empty table. Both errors were swallowed. Results timestamps are now epoch
  seconds like the data, cache, and meta tables; older text timestamps
  still read
* Fixed: environment sections in `settings.yml` (for example `production:`)
  now replace sequences whole. A sequence of mappings used to be left
  unchanged, so such an override silently did nothing
* Fixed: `settings_write(section =)` finds split files relative to the
  settings file, so it works from a subfolder
* `data_list()` includes `name: path` shorthand catalog entries and returns
  its entries as a data frame (invisibly), as documented
* New `package_add()` records a package in the project's settings (CRAN,
  pinned, GitHub, or Bioconductor, optionally auto-attached) and installs
  it. The `framework-packages` skill and the generated AI context already
  told assistants to use it
* The `framework-outputs` and `framework-workflow` skills, the generated AI
  context, the cheatsheet, and the README now use current function names
  (`save_table()`, `save_figure()`, `save_model()`, `cache_remember()`,
  `db_query()`, `db_execute()`, and `storage_test()`) instead of removed
  ones. A test fails if a skill or the cheatsheet calls a function the
  package doesn't export

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
