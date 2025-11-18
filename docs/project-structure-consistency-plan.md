# Project Structure Consistency Plan

**Date**: 2025-11-16
**Status**: Analysis Complete, Implementation Pending

---

## Overview

The Project Structure section has **unique characteristics** across the three main contexts, but contains **reusable sub-patterns** that should be extracted into canonical components.

---

## Context-Specific UI (Keep As-Is)

### 1. **SettingsView** - Project Type Selector (Screenshot 1)
**Location**: `/settings/project-structure`

**UI Pattern**: Clickable cards for each project type
- Standard Project
- Privacy Sensitive Project
- Presentation
- Course

**Decision**: ✅ **KEEP UNIQUE** - This is the entry point for configuring defaults per project type

---

### 2. **NewProjectView** - Radio Button Selector (Screenshot 2)
**Location**: New Project → Project Structure tab

**UI Pattern**: Radio buttons for project type selection
- Research Project
- Privacy Sensitive Project
- Presentation
- Course/Teaching

**Decision**: ✅ **KEEP UNIQUE** - This is the initial project type selection during creation

---

## Reusable Patterns (Need Canonical Components)

### ✅ Pattern 1: Workspaces Section (Screenshot 3)

**Appears In**:
- SettingsView (for each project type defaults)
- NewProjectView (after selecting project type)
- ProjectDetailView (editing existing project)

**Components**:
1. **Toggleable core directories** with path inputs:
   - Functions (Toggle → Input with placeholder)
   - Notebooks (Toggle → Input with placeholder)
   - Scripts (Toggle → Input with placeholder)

2. **Extra directories from global settings** (toggleable)

3. **Add Custom Workspace Directories** section:
   - Repeater component
   - Key, Label, Path inputs
   - "Add Workspace Directory" button

**Status**: ✅ **WorkspaceDirectoriesPanel.vue CREATED**

---

### ✅ Pattern 2: Inputs Section

**Appears In**:
- SettingsView (for project/project_sensitive types)
- NewProjectView (for project/project_sensitive types)
- ProjectDetailView (for project/project_sensitive types)

**Components**:
1. **Toggleable input directories** with path inputs:
   - Raw Inputs
   - Intermediate Inputs
   - Final Inputs
   - Docs

2. **Add Custom Input Directories** section (Repeater)

**Status**: ✅ **COMPONENT CREATED**: `InputDirectoriesPanel.vue`

---

### ✅ Pattern 3: Outputs Section

**Appears In**:
- SettingsView (for project type)
- NewProjectView (for project type)
- ProjectDetailView (for project type)

**Components**:
1. **Toggleable output directories**:
   - Notebooks
   - Tables
   - Figures
   - Models
   - Reports

2. **Temporary directories** (Cache, Scratch) - controlled by `showTemporary` prop

3. **Add Custom Output Directories** (Repeater)

**Status**: ✅ **COMPONENT CREATED**: `OutputDirectoriesPanel.vue`

**Note**: Component supports both regular and privacy-sensitive projects through flexible prop configuration.

---

### ✅ Pattern 4: Presentation Directories (Canonical)

**Appears In**:
- SettingsView (for presentation type)
- NewProjectView (for presentation type)
- ProjectDetailView (if project is presentation type)

**Components**:
1. **Presentation source file** (Input) - Handled separately (not a directory)
2. **Optional directories** (Toggle → Input):
   - Inputs
   - Outputs
   - Scripts
   - Functions

**Status**: ✅ **COMPLETE**: `PresentationDirectoriesPanel.vue` handles optional directories. Source file is managed separately as it's not a directory. Component uses different v-model pattern (single object vs separate enabled/paths props).

---

### ✅ Pattern 5: Course Directories

**Appears In**:
- SettingsView (for course type)
- NewProjectView (for course type)
- ProjectDetailView (if project is course type)

**Components**:
1. **Toggleable core directories**:
   - Modules
   - Assignments
   - Resources
   - Slides

2. **Add Custom Directories** (Repeater)

**Status**: ✅ **COMPONENT CREATED**: `CourseDirectoriesPanel.vue`

---

## Data Flow

### Props Pattern (All Directory Panels)

```typescript
{
  // Which directories are enabled/toggled on
  directoriesEnabled: {
    functions: true,
    notebooks: true,
    scripts: false
  },

  // Path for each directory
  directories: {
    functions: 'functions',
    notebooks: 'notebooks',
    scripts: 'scripts'
  },

  // Metadata from settings catalog (labels, hints, defaults)
  catalog: {
    functions: {
      label: 'Functions',
      hint: 'R files here are sourced by scaffold()',
      default: 'functions',
      enabled_by_default: true
    },
    // ...
  },

  // Extra directories from global settings (optional)
  extraDirectories: [...],
  extraDirectoriesEnabled: {...},

  // Project-specific custom directories (optional)
  projectCustomDirectories: [...],

  // UI control
  allowCustomDirectories: true,
  flush: false
}
```

### Emit Pattern

```javascript
// When user toggles a directory
emit('update:directoriesEnabled', { ...current, functions: true })

// When user changes a path
emit('update:directories', { ...current, functions: 'R' })

// When user adds/removes custom directories
emit('update:projectCustomDirectories', [...])
```

---

## Implementation Plan

### Phase 3A: Create Remaining Directory Panels ✅ COMPLETE

1. ✅ **WorkspaceDirectoriesPanel** - DONE
2. ✅ **InputDirectoriesPanel** - DONE
3. ✅ **OutputDirectoriesPanel** - DONE (supports both regular and privacy-sensitive via props)
4. ✅ **CourseDirectoriesPanel** - DONE
5. ✅ **PresentationDirectoriesPanel** - DONE (source file handled separately)

### Phase 3B: Integration

1. Replace inline code in **NewProjectView**:
   - Workspaces section (lines 344-431)
   - Inputs section (lines 434+)
   - Outputs section (find lines)

2. Replace inline code in **ProjectDetailView**:
   - Workspaces section (around line 321)
   - Inputs section
   - Outputs section

3. Replace inline code in **SettingsView**:
   - Project type workspaces
   - Project type inputs
   - Project type outputs
   - Presentation directories
   - Course directories

### Phase 3C: Testing

1. Test directory toggles in all 3 contexts
2. Test custom directory addition/removal
3. Test path changes propagate correctly
4. Test different project types
5. Test save/load functionality

---

## Expected Impact

**Lines of Code Eliminated**: ~400-500 lines
**Consistency Achieved**: 7 out of 8 sections (87.5%)
**Maintenance Burden**: Significantly reduced - directory UI only needs changes in one place

---

## Current Status

| Component | Status | Created | Integrated |
|-----------|:------:|:-------:|:----------:|
| WorkspaceDirectoriesPanel | ✅ | Yes | Pending |
| InputDirectoriesPanel | ✅ | Yes | Pending |
| OutputDirectoriesPanel | ✅ | Yes | Pending |
| CourseDirectoriesPanel | ✅ | Yes | Pending |
| PresentationDirectoriesPanel | ✅ | Yes | Yes (Already Done) |

---

## Notes

- **Context-specific UI preserved**: The project type selector UIs remain unique (card-based in Settings, radio in New Project)
- **Reusable patterns extracted**: The actual directory management UI is canonical
- **Flexibility maintained**: Components support different project types, custom directories, and readonly modes
- **Data-driven**: Components use catalog metadata for labels/hints/defaults rather than hardcoding

---

**Next Steps**: Create remaining panels (Input, Output, Course) and integrate across all 3 contexts.
