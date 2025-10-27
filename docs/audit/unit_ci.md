# Audit Notes — Continuous Integration & Automation

Status: IN PROGRESS (Unit 13)

## Current State
- No CI configuration is present (no `.github/workflows/`, scripts, or Make targets for automated testing/checking). Given the scope of the package, add at least a GitHub Actions workflow (R CMD check, lintr, testthat) before releasing 1.0.
- Release workflow isn’t documented; add instructions (possibly in `docs/README.md` or a CONTRIBUTING guide) covering package checks, README rebuild, docs regen, and tarball cleanup.
- CLI shell scripts aren’t validated automatically. Consider adding a lint step (shellcheck) to the CI pipeline to catch regressions in `inst/bin/*.sh`.

---

Next actions: design and commit a CI workflow (R CMD check + linting + shellcheck), document the release process, and revisit once automation is in place. Mark unit DONE once CI scaffolding is planned or merged.
