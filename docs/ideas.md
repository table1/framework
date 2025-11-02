# Directory Hygiene Helper

- Build a `framework prune-empty` CLI (or `framework::prune_empty()` helper) that scans the project for empty directories created by the scaffold.
- Present an interactive prompt (batch flag optional) that lists candidates grouped by top-level bucket (`inputs/`, `outputs/`, etc.).
- Let users choose which directories to remove; skip anything added manually to the allowlist (e.g., `.gitkeep` presence or a comment in `framework.yml`).
- Support a dry-run mode that logs what would be removed alongside the total disk footprint recovered.
- Consider hooking into scaffold or release workflow to suggest a cleanup when no tracked files exist in the generated namespace.

# Manifest + Helper Concepts

- `data_add(path, key = NULL, manifest = "data.yml")`: derive `key` from basename when omitted, strip project root, and append metadata (`path`, timestamp, optional description) under nested keys based on subdirectories (e.g., `inputs/raw/unit_1/file.csv` → `unit_1`).
- Mirror helpers (`slides_add()`, `assignment_add()`, etc.) so each starter pack component has an ergonomic way to register artifacts.
- Provide companion utilities (`data_list()`, `data_remove()`) to inspect and prune manifest entries without hand-editing YAML.
