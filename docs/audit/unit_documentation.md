# Audit Notes — Documentation Set

Status: IN PROGRESS (Unit 09)

## Global Messaging & Versioning
- Many docs still describe the framework as pre-1.0 or reference “config.yml” as the default entry point. With the 1.0 release moving configuration to `settings.yml` + `settings/` split files, sweep the doc set (README variants, cheatsheet, CLI docs, philosophy) to align terminology and highlight the stabilized API.
- Documentation doesn’t currently call out key 1.0 changes (directory schema, AI defaults, CLI hybrid pattern). Consider a “What’s new” or migration note in `docs/README.md` or top-level README.

## CLI Documentation (`docs/cli.md`, `docs/cli-dev-mode.md`, `hybrid-cli-pattern.md`)
- `docs/cli.md:47` references `framework::install_cli()` (typo) and assumes `cli_install()` always succeeds via symlink; update instructions to cover Windows/WSL caveats and non-interactive installs.
- CLI docs still describe the old single-script architecture; the shipped CLI now uses `framework-shim` + `framework-global`. Update diagrams/text to mention project detection logic and the `framework-global` command set (`settings:*`, `ai:*`, etc.).
- Dev-mode instructions depend on `framework-project` being at `~/code/framework-project`. Document that assumption or show how to override via env vars.

## Notebook & Stub Docs (`docs/make_notebook.md`, `readme-parts-guide.md`)
- `docs/make_notebook.md:37, 108, 142` states the default notebook directory is `work/` and configuration lives under `config.yml -> options.notebook_dir`. In 1.0 the default is `notebooks/` and config lives under `directories.notebooks`. Update the examples plus the “Configuration Options” section to match.
- Stub placeholder examples still hard-code `Your Name`; mention that the generator now pulls from `settings.yml` author fields and adjust code snippets accordingly.

## Database & Config Guides (`docs/database-getting-started.md`, `database-final-summary.md`, `multi-database-support.md`, `philosophy.md`, etc.)
- All database guides embed YAML fragments pointing to `config.yml`. Revise to use `settings.yml` or call out that both filenames are discovered automatically. Highlight the `directories` structure when referencing cache/results paths.
- The configuration overhaul notes (`docs/config_system_overhaul.md`) predate the move back to consolidated `settings.yml`. Verify that the design doc matches the implemented state or append a postscript describing the final decision.

## README & Sync Content (`docs/README.md`, `docs/readme-sync.md`, `readme-parts-guide.md`)
- References to “keep root clean – use `docs/` not project root” are fine, but instructions for regenerating README still mention the old part layout (six sections). Ensure the guide reflects the current part list (01_header … 11_roadmap) and calls out `settings.yml` wherever relevant.

## Philosophy & Feature Docs (`docs/philosophy.md`, `docs/features/*.md`)
- Many examples describe single `config.yml` with nested `options`/`directories` sections; bring these snippets up to date with the new defaults (e.g., `directories.cache`, `ai.canonical_file`).
- Feature docs referencing scaffolding workflow still show `work/` and `config.yml`—update or mark as historical where appropriate.

## Miscellaneous
- `docs/CLAUDE.md` instructs assistants to `write_config(config, "config.yml")`; revise to encourage `settings.yml` or `settings_file <- framework:::._get_settings_file()` style helpers so AI-generated patches follow current structure.
- Add explicit cross-links from CLI docs to the security audit section (since hooks now integrate with CLI commands) once both are updated.

---

Next actions: run a documentation sweep replacing `config.yml` references where appropriate, refresh CLI/how-to articles with the hybrid CLI behavior, and adjust notebook/stub docs to match the 1.0 directory schema. Mark unit DONE once the updates are planned or in progress.
