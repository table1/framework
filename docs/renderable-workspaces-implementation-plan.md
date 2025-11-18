# Renderable Workspaces Implementation Plan

**Date**: 2025-11-16
**Goal**: Add render output directory configuration for workspaces that produce rendered output (Quarto/RMarkdown notebooks, slides, docs, etc.)

---

## Conceptual Overview

**Key Insight**: Workspaces that render (produce output files) need TWO directories:
1. **Source directory** - where the .qmd/.Rmd files live
2. **Render output directory** - where rendered HTML/PDF files go

**Default pattern**: `outputs/{workspace_name}` (e.g., `notebooks/` → `outputs/notebooks/`)

**Quarto vs RMarkdown**:
- Quarto: Full support via `_quarto.yml` configuration
- RMarkdown: Limited support - hide render output option for RMarkdown projects

---

## Phase 1: Analysis & Documentation

### 1.1 Document Renderable Workspaces by Project Type

**Project (standard)**:
- ✅ Notebooks → renders to `outputs/notebooks/`
- ✅ Docs → renders to `outputs/docs/` or `docs/` (public)

**Project (sensitive)**:
- ✅ Notebooks → renders to `outputs/private/notebooks/` or `outputs/public/notebooks/`
- ✅ Docs → renders to `outputs/private/docs/` or `outputs/public/docs/`

**Course**:
- ✅ Slides → renders to `outputs/slides/`
- ✅ Assignments → renders to `outputs/assignments/`
- ✅ Modules → renders to `outputs/modules/`
- ✅ Course Docs → renders to `outputs/course_docs/`
- ✅ Notebooks → renders to `outputs/notebooks/` (optional workspace)

**Presentation**:
- ✅ Presentation source → renders to `outputs/` or same directory

### 1.2 Document Non-Renderable Workspaces

These workspaces only need a source directory (no output):
- Functions (`functions/`)
- Scripts (`scripts/`)

### 1.3 Define Data Model

**Current structure**:
```javascript
directories: {
  notebooks: "notebooks",
  functions: "functions",
  // ...
}

directories_enabled: {
  notebooks: true,
  functions: true,
  // ...
}
```

**Proposed structure** (Option A - separate keys):
```javascript
directories: {
  notebooks: "notebooks",
  notebooks_output: "outputs/notebooks",
  slides: "slides",
  slides_output: "outputs/slides",
  functions: "functions", // no _output key
  // ...
}

directories_enabled: {
  notebooks: true,
  slides: true,
  functions: true,
  // ...
}
```

**Alternative** (Option B - nested object):
```javascript
directories: {
  notebooks: {
    source: "notebooks",
    output: "outputs/notebooks"
  },
  slides: {
    source: "slides",
    output: "outputs/slides"
  },
  functions: "functions", // simple string for non-renderables
  // ...
}
```

**Decision**: Choose Option A (separate keys) for backward compatibility.

---

## Phase 2: Component Creation

### 2.1 Create RenderableWorkspacesPanel.vue

**Location**: `gui-dev/src/components/settings/RenderableWorkspacesPanel.vue`

**Props**:
```javascript
{
  // Which renderables are enabled
  directoriesEnabled: Object, // { notebooks: true, slides: false }

  // Source directories
  directories: Object, // { notebooks: "notebooks", slides: "slides" }

  // Render output directories
  outputDirectories: Object, // { notebooks: "outputs/notebooks", slides: "outputs/slides" }

  // Metadata from catalog
  catalog: Object,

  // List of renderable workspace keys for this project type
  renderableKeys: Array, // ['notebooks', 'docs'] for project

  // Notebook format (quarto or rmarkdown)
  notebookFormat: String, // "quarto" | "rmarkdown"

  // Extra directories from global settings
  extraDirectories: Array,
  extraDirectoriesEnabled: Object,

  // Project-specific custom directories
  projectCustomDirectories: Array,
  allowCustomDirectories: Boolean,

  // UI control
  flush: Boolean
}
```

**Emits**:
- `update:directoriesEnabled`
- `update:directories`
- `update:outputDirectories`
- `update:extraDirectoriesEnabled`
- `update:projectCustomDirectories`

**UI Structure**:
```
Renderable Workspaces
Functions, notebooks, and slides that render to output directories.

[Toggle] Notebooks
  Source:         / [notebooks            ]
  Renders to:     / [outputs/notebooks    ] (only if quarto)

[Toggle] Slides
  Source:         / [slides               ]
  Renders to:     / [outputs/slides       ] (only if quarto)

--- Custom directories from global settings ---

--- Add Custom Renderable Directories ---
[+ Add Renderable Directory]
```

**Special handling**:
- If `notebookFormat === 'rmarkdown'`, hide the "Renders to" input
- Show hint: "RMarkdown renders to source directory"

### 2.2 Update WorkspaceDirectoriesPanel.vue

**Changes**:
- This component should now ONLY handle non-renderable workspaces (functions, scripts)
- Remove notebooks, docs, slides, etc. from its scope
- Rename to clarify: Keep as `WorkspaceDirectoriesPanel` but update description to "Non-renderable workspaces"

**New props**:
```javascript
{
  // Same as before, but filtered to only non-renderables
  workspaceKeys: Array, // ['functions', 'scripts'] - explicit list
  // ... rest unchanged
}
```

### 2.3 Update CourseDirectoriesPanel.vue

**Option 1**: Keep CourseDirectoriesPanel but make it use RenderableWorkspacesPanel internally
**Option 2**: Deprecate CourseDirectoriesPanel entirely, use RenderableWorkspacesPanel directly

**Decision**: Use RenderableWorkspacesPanel directly - course materials ARE renderables.

### 2.4 Update Settings Catalog

Need to add render output defaults to settings catalog:

**Location**: `inst/config/settings-catalog.yml`

Add `output` field to renderable directories:
```yaml
project_types:
  project:
    directories:
      notebooks:
        label: "Notebooks"
        hint: "Quarto or R Markdown notebooks for analysis."
        default: "notebooks"
        output: "outputs/notebooks"  # NEW
        enabled_by_default: true
        renderable: true  # NEW

      functions:
        label: "Functions"
        hint: "R files sourced by scaffold()."
        default: "functions"
        enabled_by_default: true
        renderable: false  # NEW
```

---

## Phase 3: Integration

### 3.1 NewProjectView Integration

**For 'project' type**:
1. Replace current WorkspaceDirectoriesPanel with:
   - RenderableWorkspacesPanel for notebooks, docs
   - WorkspaceDirectoriesPanel for functions, scripts

2. Pass `project.notebook_format` to RenderableWorkspacesPanel

3. Track both `directories` and `output_directories` in project state

**For 'project_sensitive' type**:
- Same pattern, but consider private/public split for outputs

**For 'course' type**:
- RenderableWorkspacesPanel for slides, assignments, modules, course_docs
- WorkspaceDirectoriesPanel for functions, scripts
- Remove separate Course Materials section

**For 'presentation' type**:
- Already using PresentationDirectoriesPanel
- Consider if we need render output here

### 3.2 SettingsView Integration

Similar to NewProjectView, but for project type defaults:
- Replace directory sections with new components
- Pass global default for notebook_format

### 3.3 ProjectDetailView Integration

When viewing/editing an existing project:
- Show RenderableWorkspacesPanel for renderables
- Show WorkspaceDirectoriesPanel for non-renderables
- Load output directories from project config

---

## Phase 4: Backend Support (R)

### 4.1 Update init() Function

**File**: `R/init.R`

**Changes**:
- Accept `output_directories` parameter
- Write output directory config to project config.yml
- Create output directories during initialization

### 4.2 Update Quarto Configuration

**File**: `R/quarto.R` (or relevant Quarto helper)

**Changes**:
- Generate `_quarto.yml` with correct `output-dir` settings
- Use `output_directories` from config
- Skip for RMarkdown projects

Example `_quarto.yml`:
```yaml
project:
  type: default
  output-dir: outputs/notebooks  # from config

format:
  html:
    toc: true
```

### 4.3 Update scaffold() Function

**File**: `R/scaffold.R`

**Changes**:
- Ensure output directories are created if they don't exist
- Respect both source and output directory configs

---

## Phase 5: Testing

### 5.1 Manual Testing Checklist

**New Project - Quarto**:
- [ ] Create new project (type: project)
- [ ] Verify notebooks shows source + output directories
- [ ] Change output directory path
- [ ] Toggle notebooks off/on
- [ ] Save and verify config.yml has both directories

**New Project - RMarkdown**:
- [ ] Create new project with RMarkdown
- [ ] Verify render output is HIDDEN for notebooks
- [ ] Verify hint message shows

**Course Type**:
- [ ] Create course project
- [ ] Verify slides, assignments, modules show as renderables
- [ ] Verify functions, scripts are separate (non-renderable)
- [ ] No inputs/outputs sections

**Settings Defaults**:
- [ ] Navigate to Settings → Project Defaults
- [ ] Verify renderable workspaces section appears
- [ ] Change defaults, save
- [ ] Create new project, verify defaults applied

**Existing Projects**:
- [ ] Open existing project without output directories in config
- [ ] Verify graceful handling (defaults applied)
- [ ] Save and verify output directories added to config

### 5.2 Edge Cases

- [ ] Empty catalog handling
- [ ] Null output_directories object
- [ ] Mixed Quarto/RMarkdown (shouldn't happen, but handle)
- [ ] Very long directory paths (UI wrapping)
- [ ] Special characters in paths

---

## Phase 6: Documentation

### 6.1 Update README

**Section**: "Project Structure"

Add explanation of render output directories:
```markdown
### Renderable Workspaces

Workspaces that produce rendered output (Quarto notebooks, slides, etc.)
have two directories:

- **Source directory**: Where your .qmd/.Rmd files live
- **Output directory**: Where rendered HTML/PDF files are saved

Default pattern: `outputs/{workspace_name}`

Note: Render output directories are only configurable for Quarto projects.
```

### 6.2 Update Cheatsheet

**File**: `inst/templates/framework-cheatsheet.fr.md`

Add render output info to directory structure section.

### 6.3 Update CLAUDE.md

Document this feature for future AI assistants working on the codebase.

---

## Phase 7: Cleanup

### 7.1 Remove Obsolete Code

- [ ] Remove old inline directory management code (already done for 'project' type)
- [ ] Remove unused helper functions
- [ ] Clean up commented-out code

### 7.2 Update UI Consistency Doc

**File**: `docs/ui-consistency.md`

Update to reflect new components and consistency improvements.

---

## Implementation Order

1. ✅ Start with analysis and data model definition (Phase 1)
2. ✅ Create RenderableWorkspacesPanel component (Phase 2.1)
3. ✅ Update WorkspaceDirectoriesPanel to only handle non-renderables (Phase 2.2)
4. ✅ Update settings catalog with output fields (Phase 2.4)
5. ✅ Integrate into NewProjectView for 'project' type (Phase 3.1)
6. ✅ Test 'project' type thoroughly (Phase 5.1)
7. ✅ Integrate into 'course' type (Phase 3.1)
8. ✅ Test 'course' type thoroughly (Phase 5.1)
9. ✅ Integrate into SettingsView (Phase 3.2)
10. ✅ Backend support - update init() and Quarto config (Phase 4)
11. ✅ Final testing all project types (Phase 5)
12. ✅ Documentation (Phase 6)
13. ✅ Deploy (Phase 7)

---

## Open Questions

1. **Should presentation source file also have a render output directory?**
   - Presentations typically render to the same directory
   - Could add optional output directory

2. **How to handle privacy-sensitive projects?**
   - Render outputs should respect private/public split
   - Maybe: `outputs/private/notebooks` vs `outputs/public/notebooks`

3. **Should we migrate existing projects?**
   - Option A: Auto-migrate on first load (add output directories to config)
   - Option B: Only apply to new projects
   - **Decision**: Auto-apply defaults if missing (graceful enhancement)

4. **What about custom renderable directories from global settings?**
   - If user adds custom directory in global settings, how do we know if it's renderable?
   - **Decision**: Add `renderable: true/false` flag to custom directory definition

---

## Success Criteria

- [ ] All renderables show split-view (source + output) for Quarto projects
- [ ] RMarkdown projects hide render output options gracefully
- [ ] Course type structure is cleaner and more consistent with project type
- [ ] No inputs/outputs sections for course type
- [ ] Settings defaults work for all project types
- [ ] Existing projects load without errors
- [ ] New projects have correct directory structure
- [ ] Quarto `_quarto.yml` uses configured output directories
- [ ] ~400+ lines of duplicate code eliminated
- [ ] UI is consistent across all 3 contexts (New Project, Settings, View/Edit)

---

## Estimated Effort

- **Phase 1 (Analysis)**: 1 hour
- **Phase 2 (Components)**: 3-4 hours
- **Phase 3 (Integration)**: 2-3 hours
- **Phase 4 (Backend)**: 2 hours
- **Phase 5 (Testing)**: 2 hours
- **Phase 6 (Docs)**: 1 hour
- **Phase 7 (Cleanup)**: 1 hour

**Total**: ~12-15 hours

---

## Notes

- This is a significant UX improvement that makes the relationship between source and output explicit
- Aligns with Framework's Quarto-first philosophy
- Makes course project structure much cleaner
- Provides foundation for future enhancements (e.g., render on save, preview links)
