# Quarto Defaults Implementation Plan

## Overview

Implement a Quarto configuration system that allows users to set global preferences and automatically generates `_quarto.yml` files in render directories on project creation.

## Implementation Steps

### Phase 1: Data Model Design

**Catalog Schema** (`inst/config/settings-catalog.yml`):

- [ ] Add `quarto_defaults` section to catalog
- [ ] Define format-based structure (HTML vs revealjs)
- [ ] Add common global options (self-contained, embed-resources, theme)
- [ ] Add format-specific options:
  - HTML: toc, code-fold, code-tools
  - revealjs: incremental, slide-number, transition
- [ ] Define project-type-specific overrides (course vs presentation)

**Global Config** (`~/.config/framework/config.yml`):

- [ ] Add `quarto:` section mirroring catalog structure
- [ ] Set sensible defaults for HTML rendering
- [ ] Set sensible defaults for revealjs presentations

### Phase 2: Backend Implementation

**New R Functions**:

- [ ] Create `R/quarto_settings.R`:
  - [ ] `quarto_settings_get()` - Read from global config
  - [ ] `quarto_settings_save()` - Write to global config
  - [ ] `quarto_settings_reset()` - Restore catalog defaults

- [ ] Create `R/quarto_generate.R`:
  - [ ] `generate_quarto_yml()` - Main generation function
    - [ ] Accept render directory info (path, type, format)
    - [ ] Combine global preferences + project-type requirements
    - [ ] Return YAML string
  - [ ] `write_quarto_yml()` - Write to filesystem
  - [ ] Helper: `merge_quarto_settings()` - Deep merge logic

**Plumber API Routes** (`inst/plumber.R`):

- [ ] `GET /api/quarto/settings` - Fetch current Quarto settings
- [ ] `PUT /api/quarto/settings` - Save Quarto settings
- [ ] `POST /api/quarto/reset` - Reset to catalog defaults

**Project Creation Integration** (`R/project_create.R`):

- [ ] Modify `create_project()` to call Quarto generation
- [ ] For each enabled render directory:
  - [ ] Determine format (HTML for standard dirs, revealjs for slides)
  - [ ] Generate appropriate `_quarto.yml`
  - [ ] Write to render directory root

### Phase 3: Frontend Implementation

**New Component** (`src/components/settings/QuartoSettingsPanel.vue`):

- [ ] Create panel with two tabs: "HTML Rendering" and "Presentations"
- [ ] HTML tab:
  - [ ] Self-contained toggle
  - [ ] Embed resources toggle
  - [ ] Theme selector (dropdown: default, cosmo, cerulean, etc.)
  - [ ] TOC options (toggle + depth)
  - [ ] Code options (fold, tools toggles)
- [ ] Presentations tab:
  - [ ] Theme selector (revealjs themes)
  - [ ] Incremental bullets toggle
  - [ ] Slide numbers toggle
  - [ ] Transition effects dropdown
- [ ] Reset to Defaults button
- [ ] Save/Cancel actions

**Integration Points**:

- [ ] Add QuartoSettingsPanel to `SettingsView.vue` (Framework Global Defaults)
- [ ] Add QuartoSettingsPanel to `NewProjectView.vue` (project-specific overrides)
- [ ] Add QuartoSettingsPanel to `ProjectDetailView.vue` (edit existing project)
- [ ] Ensure DRY: single component, props-based configuration

**API Integration** (`src/api.js`):

- [ ] Add `getQuartoSettings()` function
- [ ] Add `saveQuartoSettings()` function
- [ ] Add `resetQuartoSettings()` function

### Phase 4: Testing

**Backend Tests** (`tests/testthat/test-quarto.R`):

- [ ] Test `generate_quarto_yml()` with HTML format
- [ ] Test `generate_quarto_yml()` with revealjs format
- [ ] Test merge logic (global + project-type overrides)
- [ ] Test settings save/load cycle
- [ ] Test YAML validity (parseable by quarto)

**Frontend Tests** (`gui-dev/tests/integration/quarto.spec.js`):

- [ ] Test QuartoSettingsPanel rendering
- [ ] Test save/load cycle through API
- [ ] Test reset functionality
- [ ] Test project creation with Quarto files generated

**Integration Tests**:

- [ ] Create test project with course type
- [ ] Verify `_quarto.yml` exists in slides/ and modules/ directories
- [ ] Verify YAML content matches expected structure
- [ ] Create test project with presentation type
- [ ] Verify revealjs configuration applied

### Phase 5: Deployment

- [ ] Run `cd gui-dev && npm run deploy` to build frontend
- [ ] Update README with Quarto settings documentation
- [ ] Update inst/templates/framework-cheatsheet.fr.md with Quarto functions
- [ ] Commit changes with descriptive message
- [ ] Test full workflow end-to-end

## Key Design Decisions

**Format-Based Approach**: Settings organized by output format (HTML vs revealjs) rather than project type, with project-type-specific overrides applied at generation time.

**Single Source of Truth**: QuartoSettingsPanel component reused across all three screens (Global Defaults, New Project, Project Detail) with props controlling context.

**Merge Strategy**: Deep merge of global preferences → project-type defaults → per-project overrides.

**Directory Detection**: Format determined by directory name/type:
- HTML: notebooks, outputs_docs, outputs_docs_public, modules, assignments, course_docs
- revealjs: slides

## Dependencies

- Phase 2 depends on Phase 1 (catalog schema must exist)
- Phase 3 depends on Phase 2 (API routes must exist)
- Phase 4 depends on Phases 2 & 3 (backend + frontend complete)
- Phase 5 depends on Phase 4 (tests passing)

## Success Criteria

- [ ] User can set Quarto preferences in Global Defaults
- [ ] New projects automatically generate `_quarto.yml` in render directories
- [ ] Generated YAML is valid and parseable by Quarto
- [ ] Settings persist across sessions
- [ ] DRY maintained across all three screens
- [ ] All tests passing
