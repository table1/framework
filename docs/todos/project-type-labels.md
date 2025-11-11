# Project Type Labels - Architecture Issue

## Problem

Project type labels are currently stored in user's local config (`~/.config/framework/settings.yml`) and can be edited through the GUI. This creates several issues:

1. Labels can drift from package defaults
2. Changes to package defaults don't propagate to existing users
3. Labels are duplicated across multiple files (settings-catalog.yml, global-settings-default.yml, user config)

## Example

When we renamed "Sensitive Data Project" → "Privacy Sensitive Project", we had to update:
- `inst/config/settings-catalog.yml`
- `inst/config/global-settings-default.yml`
- User's local `~/.config/framework/settings.yml`

The user's local config overrode everything until manually updated.

## Proposed Solution

Labels should NOT be user-configurable. They should always come from the package defaults:
- Keep labels only in `inst/config/settings-catalog.yml` (single source of truth)
- Remove labels from user configs
- User configs should only store directories, scaffold settings, etc.
- When loading settings, merge user directories with package labels

## Benefits

- Consistent naming across all users
- Package updates can change labels
- Simpler config files
- Less duplication

## Priority

Low - current workaround is acceptable, but should be addressed before 1.0
