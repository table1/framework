# Framework Release Workflow

This checklist mirrors the automation baked into `Makefile` and ensures we ship a clean artefact each time.

1. **Start fresh**
   ```bash
   make clean
   ```
   Removes any stray `*.tar.gz` or `*.Rcheck/` directories.

2. **Update documentation**
   ```bash
   make docs
   ```
   Regenerates roxygen docs (`devtools::document()`). Commit any changes under `man/` or `NAMESPACE`.

3. **Run tests and package checks**
   ```bash
   make test   # testthat::test_dir('tests')
   make check  # R CMD check . --no-manual
   ```
   Fix failures before moving forward. The GitHub Actions workflow (`.github/workflows/ci.yml`) runs the same commands plus lintr and shellcheck on every PR.

4. **Build the release tarball**
   ```bash
   make build
   ```
   Produces `framework_<version>.tar.gz` in the repo root. Upload this to CRAN or attach it to the release tag.

5. **Optional quick smoke install**
   ```bash
   make install-quick
   ```
   Installs from the working tree without rebuilding the tarball.

6. **Final release target**
   ```bash
   make release
   ```
   Convenience target equivalent to `clean docs test check`; use it as the final gate before tagging.

7. **Tag and push**
   ```bash
   git tag v<version>
   git push origin main --tags
   ```

Keeping these steps in version control means every maintainer follows the same path from commit to release.
