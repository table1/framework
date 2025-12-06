# Component Consolidation Plan

**Created**: 2025-11-16
**Status**: In Progress
**Priority**: High

## Problem

SettingsView (Framework Project Defaults), NewProjectView (New Project), and ProjectDetailView (View/Edit Project) have duplicated settings UI logic, causing drift where updates to one view aren't reflected in others.

**Example**: Presentation directories showed "data" in one view but "inputs/outputs" in another.

## Solution

Extract duplicated settings sections into shared components under `src/components/settings/`. Use incremental extraction to minimize risk.

## Completed Extractions

### PresentationDirectoriesPanel

- **File**: `src/components/settings/PresentationDirectoriesPanel.vue`
- **Status**: ✅ COMPLETED
- **Used in**: SettingsView (line 1127), NewProjectView (line 856)
- **Purpose**: Render optional directories for presentation project type
- **Key Feature**: Catalog-driven (reads from settings-catalog.yml)
- **Prevents**: Drift in directory lists between views
- **Completed**: 2025-11-16

**Implementation Details**:
```vue
Props:
  - modelValue: Object (directories object)
  - catalog: Object (settings catalog from API)
  - readonly: Boolean (optional, for read-only mode)

Emits:
  - update:modelValue

Logic:
  - Computes optional directories from catalog where enabled_by_default === false
  - Renders Toggle + Input for each directory
  - Fully catalog-driven (no hardcoded directory names)
```

## Future Extractions

### Priority 2: PackagesPanel

- **Current state**: PackagesEditor exists but only used in SettingsView
- **Action needed**: Verify if it can replace custom package UIs in NewProjectView/ProjectDetailView
- **Estimated effort**: Medium
- **Benefits**: Eliminates package UI duplication, ensures consistent package management across views

### Priority 3: AuthorInformationPanel

- **Current state**: Exists, used in SettingsView only
- **Action needed**: Replace inline author fields in NewProjectView
- **Estimated effort**: Low
- **Benefits**: Quick win, simple drop-in replacement

### Priority 4: ProjectTypeSelector

- **Current state**: SettingsView has radio buttons, NewProjectView has dropdown
- **Action needed**: Unified component with mode prop (radio vs select)
- **Estimated effort**: Low
- **Benefits**: Consistent project type selection UI

## Architecture Guidelines

### 1. Prefer Catalog-Driven Over Hardcoded

Components should read from the settings catalog whenever possible:

```javascript
// BAD: Hardcoded directory list
const dirs = ['inputs', 'outputs', 'scripts', 'functions']

// GOOD: Read from catalog
const dirs = computed(() => {
  const catalogType = catalog.value.project_types.presentation
  return Object.keys(catalogType.directories).filter(key =>
    catalogType.directories[key].enabled_by_default === false
  )
})
```

### 2. Keep Components Dumb

- Pass all data via props
- Emit updates, don't mutate parent state
- No context awareness (don't check if running in Settings vs NewProject)
- Single responsibility - one purpose per component

### 3. Document Sync Requirements

If hardcoding is absolutely necessary, add clear comments:

```javascript
// SYNC REQUIREMENT: Must match PRESENTATION_OPTIONAL_DIRECTORIES
// in src/constants/projectTypes.js and inst/settings/settings-catalog.yml
// (presentation.directories where enabled_by_default: false)
// Order matters: inputs, outputs, scripts, functions
const presentationOptions = reactive({
  includeInputs: false,
  includeOutputs: false,
  includeScripts: false,
  includeFunctions: false
})
```

### 4. Test Incrementally

- One component extraction at a time
- Manual test all views after each change
- Small, focused git commits
- Don't merge until verified working
- Use the manual testing checklist

## Testing Strategy

### Manual Testing Checklist (PresentationDirectoriesPanel)

**SettingsView:**
- [ ] Navigate to Settings → Project Structure
- [ ] Select "Presentation" project type
- [ ] Verify 4 toggles appear: Inputs, Outputs, Scripts, Functions
- [ ] Toggle each on, verify input field appears
- [ ] Edit directory path, verify it saves
- [ ] Toggle off, verify directory removed
- [ ] Click "Restore Defaults", verify all toggles reset to off
- [ ] Save settings, refresh page, verify persisted

**NewProjectView:**
- [ ] Go to New Project → Structure section
- [ ] Select "Presentation" project type
- [ ] Verify same 4 toggles in same order
- [ ] Toggle each on, verify paths populate
- [ ] Edit paths, verify Overview card updates
- [ ] Create project with inputs+outputs enabled
- [ ] Verify created project has those directories

**Cross-View Consistency:**
- [ ] Change presentation defaults in Settings
- [ ] Create new presentation project
- [ ] Verify new project inherits defaults
- [ ] Both views show identical UI

### Automated Testing

- Integration test already exists: `tests/integration/project-structure.spec.js`
- Verifies presentation directories persist to YAML
- No additional tests needed for UI component itself

## Success Metrics

- [ ] Zero duplicated presentation directory UI code
- [ ] Both views read from same catalog source
- [ ] Clear comments documenting sync requirements
- [ ] Architecture guidelines documented
- [ ] Manual testing checklist passes

## Risk Mitigation

- Test after each integration (don't batch changes)
- Keep git commits small and focused
- Easy rollback if issues found
- User can verify immediately in browser
- Use continuation_id to resume planning if needed

## Implementation Log

### 2025-11-16: Planning Complete
- Completed 6-step planning process using zen planner
- Audited all three views for component duplication
- Prioritized extractions based on user concerns
- Created this documentation

### 2025-11-16: PresentationDirectoriesPanel Completed
- ✅ Created catalog-driven component (`src/components/settings/PresentationDirectoriesPanel.vue`)
- ✅ Integrated into SettingsView - replaced hardcoded toggles and watchers
- ✅ Integrated into NewProjectView - created computed property bridge for data structure
- ✅ Both views now share identical UI logic
- ⏳ Manual testing in progress

**Integration Notes:**
- **SettingsView**: Direct integration, component expects single directories object
- **NewProjectView**: Created `presentationDirectoriesModel` computed property to transform between separate `directories_enabled` + `directories` objects and component's single-object format
- **Data Flow**: Component emits updates → computed setter transforms back → reactive state updates
- **Removed Code**: Deleted `presentationOptions` reactive object and 4 individual watchers from SettingsView

### Next: Manual Testing
- Test presentation directories in Framework Project Defaults
- Test presentation directories in New Project
- Verify consistency between both views
- Complete manual testing checklist

## Test Coverage Tracker (by screen)
- Overview: TODO — confirm automated/DOM coverage; add if missing.
- Basics: TODO — verify UI shows defaults and saves.
- Project Structure: TODO — ensure presentation/other types tested.
- Packages: UPDATED — integration (nested vs legacy) passing; UI smoke added for defaults tab. Still want deeper DOM/interaction coverage.
- Quarto: TODO — defaults and project-level regeneration.
- Git & Hooks: TODO — init + hooks persistence.
- AI Assistants: TODO — defaults/new/edit flow coverage.
- Scaffold Behavior: TODO — toggle/persistence.
- Templates: TODO — modal interactions, save/reset.
- .env Defaults: TODO — env editor grouped/raw, save.
- Connections: TODO — db/s3 mapping, defaults, project override.
