# Directory Sync Detection

## Problem

When users create directories manually (outside the Framework GUI or configuration), the system doesn't know about them. This can lead to:

1. **Out-of-sync state**: Directories exist on disk but not in `settings.yml`
2. **Missing configuration**: Directories in `settings.yml` but not on disk
3. **User confusion**: GUI shows different structure than what's actually on disk

## Proposed Solution

### Function: `directories_sync()`

Create a function to detect and reconcile differences between:
- **Config source of truth**: Directories defined in `settings.yml` (standard + extra_directories)
- **Filesystem reality**: Actual directories in the project

### Features

1. **Detection**:
   ```r
   directories_sync(check = TRUE)
   # Returns list of:
   # - directories in config but not on disk
   # - directories on disk but not in config
   # - suggestions for reconciliation
   ```

2. **Interactive reconciliation**:
   ```r
   directories_sync(interactive = TRUE)
   # Prompts user:
   # - Add missing directories to config?
   # - Create missing directories on disk?
   # - Update extra_directories in settings.yml?
   ```

3. **Auto-sync**:
   ```r
   directories_sync(auto = TRUE, direction = "config_to_disk")
   # direction options:
   # - "config_to_disk": Create missing directories
   # - "disk_to_config": Add untracked directories to settings.yml
   # - "both": Bidirectional sync with prompts
   ```

### GUI Integration

**Project Detail View - Directory Sync Warning**:

- Add a visual indicator when directories are out of sync
- Show warning banner: "⚠️ Project structure is out of sync with filesystem"
- Quick diff viewer showing:
  ```
  Missing on disk:
  - outputs/models
  - scratch

  Not in config:
  - analysis
  - temp
  ```
- Actions:
  - "Add to config" - Update settings.yml with untracked directories
  - "Create missing" - Create directories that exist in config
  - "Show details" - Open detailed diff modal

### Implementation Notes

- Run sync check when project is loaded in GUI
- Cache sync state (don't re-check on every render)
- Provide CLI command: `framework sync:directories`
- Add `--dry-run` option to preview changes
- Respect .gitignore patterns when scanning filesystem
- Exclude certain patterns by default (node_modules, .git, etc.)

### Related

- See `docs/project-structure-consistency-plan.md` for broader structure validation
- Consider integration with git hooks to detect manual directory creation
