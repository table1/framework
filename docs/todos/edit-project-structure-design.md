# Edit Project - Project Structure Design

## Current Status

The Project Structure section in Edit Project view is currently a placeholder.

## Design Constraints

1. **No project type switching** - Once a project is created, its type (project, project_sensitive, presentation, course) cannot be changed
2. **No renaming** - Existing directories cannot be renamed (would require filesystem operations + config updates)
3. **No deletion** - Existing directories cannot be deleted (destructive action, risky)
4. **Additive only** - Users can only ADD new directories to their existing structure

## Proposed UI Design

### Overview Section
```
Project Structure
─────────────────
This project uses the [Standard Project] structure.

You cannot change the project type after creation, but you can add
custom directories below.
```

### Existing Directories (Read-Only)
Display all current directories from the project's config in a read-only list:

```
Current Directories
───────────────────
✓ notebooks          → notebooks/
✓ scripts            → scripts/
✓ functions          → functions/
✓ inputs/raw         → inputs/raw/
✓ inputs/intermediate → inputs/intermediate/
✓ inputs/final       → inputs/final/
✓ outputs/figures    → outputs/figures/
✓ outputs/tables     → outputs/tables/
✓ cache              → outputs/cache/
✓ scratch            → scratch/

(These directories are part of your project structure and cannot be
removed or renamed from the GUI)
```

### Add Custom Directories (Editable)

Use the existing Repeater component to allow adding new directories:

```
Additional Directories
──────────────────────
[+ Add Directory]

Form fields:
- Key: e.g., "analysis_archive"
- Label: e.g., "Analysis Archive"
- Path: e.g., "analysis/archive"

When saved:
1. Add to project's config.yml (directories section)
2. Call API endpoint to create the directory on filesystem
3. Show success toast
4. Refresh directory list
```

## API Requirements

### New Endpoint Needed
```
POST /api/project/:id/directories
{
  "key": "analysis_archive",
  "label": "Analysis Archive",
  "path": "analysis/archive"
}

Response:
{
  "success": true,
  "directory": {
    "key": "analysis_archive",
    "label": "Analysis Archive",
    "path": "analysis/archive",
    "absolute_path": "/full/path/to/project/analysis/archive",
    "created": true
  }
}
```

### R Function Needed
```r
project_add_directory <- function(project_path, key, label, path) {
  # 1. Validate inputs
  # 2. Read project config.yml
  # 3. Add to directories section
  # 4. Write config.yml
  # 5. Create directory on filesystem (dir.create with recursive=TRUE)
  # 6. Return success/error
}
```

## Implementation Steps

1. ✅ Design specification (this document)
2. Create R function: `project_add_directory()`
3. Add API endpoint in `inst/plumber.R`
4. Update ProjectDetailView.vue:
   - Replace placeholder with read-only directory list
   - Add "Additional Directories" section with Repeater
   - Wire up save logic to call new API endpoint
5. Test additive directory creation

## Future Enhancements (Post-1.0)

- **Rename directories**: Would require:
  - Filesystem rename (safe if directory is empty)
  - Config update
  - Update any hardcoded paths in scripts
  - Potential data loss risk

- **Delete directories**: Would require:
  - Check if directory is empty
  - Remove from config
  - Optionally delete from filesystem
  - High risk of data loss

- **Project type migration**: Would require:
  - Complex directory restructuring
  - Data migration between structures
  - Config transformation
  - Very high risk

## Benefits of Current Approach

- **Safe**: Only creates new directories, never modifies/deletes
- **Simple**: Clear mental model (additive only)
- **Non-destructive**: No risk of data loss
- **Flexible**: Users can still customize structure
- **Reversible**: New directories can be manually deleted if needed

## Edge Cases to Handle

1. **Directory already exists**: Show warning, don't overwrite
2. **Invalid path**: Validate path (no absolute paths, no `..`)
3. **Key conflicts**: Check for duplicate keys
4. **Permission errors**: Handle filesystem permission issues gracefully

## Priority

Medium - Useful feature but not blocking. Current placeholder is acceptable for now.
