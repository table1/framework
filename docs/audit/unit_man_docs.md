# Audit Notes — Man Pages & Generated Docs

Status: IN PROGRESS (Unit 11)

## Man Pages (`man/*.Rd`)
- Nearly every Rd file still documents `config.yml` as the canonical configuration path (see `man/query_get.Rd`, `man/configure_*`, `man/connection_get.Rd`, etc.). Update parameter descriptions and examples to reflect the `settings.yml`-first discovery logic, calling out backward compatibility where needed.
- The `cli_install` docs expose an `install_cli()` alias that no longer exists in the code; drop the alias from the Rd or add a wrapper function to avoid broken references.
- Several man pages (e.g., `man/data_spec_update.Rd`, `man/remove_init.Rd`, `man/ai_sync_context.Rd`) still describe config split files in terms of `config.yml`. Update the prose to mention `settings.yml` + split files.
- `man/make_notebook.Rd` (generated from `R/make_notebook.R`) should reflect the new default notebook directory (`notebooks/`) and document `directories.notebooks` instead of `options.notebook_dir`.
- Ensure generated Rd files mention non-interactive behaviour where applicable (CLI prompts, password entry), especially now that tests will exercise those scenarios.

## Cheatsheet & Ancillary Docs (`inst/templates/framework-cheatsheet.fr.md`)
- The cheatsheet lists commands for scaffolding and describes the directory structure using `config.yml`. Update the cheat sheet to align with 1.0 defaults (settings file, directories.* structure, AI canonical file).
- Add a revision note or version header so readers know the cheat sheet applies to v1.0.

## README Build Script (`readme-parts/build.R`)
- Confirm the build script regenerates README without manual intervention and consider adding a check/test. Document the workflow in the audit notes if manual steps are required.

---

Next actions: regenerate documentation after updating roxygen comments (config terminology, defaults), refresh the cheat sheet for v1.0, and ensure the README build process is captured in tests/docs. Mark unit DONE once updates are scheduled.
