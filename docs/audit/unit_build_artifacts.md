# Audit Notes — Build Outputs & Legacy Artifacts

Status: IN PROGRESS (Unit 12)

## Repository Artifacts
- `framework_0.1.0.tar.gz` lives at repo root even though we’re preparing v1.0. Either regenerate for 1.0 or remove the tarball from version control—ideally we shouldn’t commit built packages.
- `framework.Rcheck/` (and subfiles) are present; add to `.gitignore` (already there) and delete from the repo so future builds start clean.
- Check for lingering caches under `_rendered/`, `data/cached/`, or other directories. Currently empty, but add README/.gitkeep files to explain their purpose after cleanup.

## Scripts & Build Workflow
- `build.sh` runs `devtools::document()` + `R CMD build/check/install` but doesn’t clean up artifacts or update README. Decide whether to keep the script (and have it prune `*.tar.gz` / `.Rcheck`) or remove it in favor of documented release steps.
- `Makefile clean` target deletes `*.tar.gz` and `.Rcheck/`; consider running it as part of release prep to avoid committing build outputs.

---

Next actions: purge committed build artifacts, ensure `.gitignore` covers them, and document the release workflow so tarballs aren’t reintroduced. Mark unit DONE once cleanup is complete.
