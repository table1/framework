# CRAN Comments

## Update to 1.1.0

This is an update from 1.0.2. Main changes:

* `plumber` moved from Imports to Suggests. It is only needed for the optional
  local GUI, and its `sodium` dependency (system libsodium) blocked installation
  on some HPC systems. `gui()` checks for plumber with `requireNamespace()`.
* New standard `logs` directory, ignored by the project gitignore templates.
* Skills-based AI context files for new projects.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

- Local: macOS 27.0.1, R 4.6.1 (`R CMD check --as-cran`)

## Downstream dependencies

There are no downstream dependencies.
