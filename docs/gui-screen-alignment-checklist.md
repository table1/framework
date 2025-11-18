# Framework GUI Screen Alignment Checklist

**Purpose**: Systematically ensure alignment between Framework defaults → new projects → view/edit project screens.

**Last Updated**: 2025-11-17

---

## Workflow Process

For each screen below, complete these steps in order:

1. **Component Assessment** - Identify shared components and consolidation opportunities
2. **Shared Components** - Document which shared components are used
3. **R API Tests** - Verify data fetching/hydration returns all necessary data correctly
4. **UI Tests** - Verify UI correctly reflects data from API (Vite tests)
5. **Network Tests** - Verify correct POST requests with all data, saving works
6. **Manual UI Review** - Assess visual consistency with design system
7. **Manual Workflow Test** - End-to-end user flow validation

**Legend**: ✅ Complete | 🔄 In Progress | ⏸️ Blocked | ❌ Failed | ⬜ Not Started

---

## Screen Checklist

### 1. Overview

**Purpose**: Settings dashboard with summary cards for each settings section (Basics, Project Structure, Notebooks & Scripts, AI Assistants, Git & Hooks, Packages, .env Defaults). Each card shows current value and clicks through to edit screen.

**Location**: `http://localhost:5175/#/settings/overview` → `SettingsView.vue` (activeSection === 'overview')

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ✅ | Fixed: green → sky blue for enabled states |
| 2. Shared Components Used | ✅ | OverviewCard.vue is only shared component |
| 3. R API Tests | ✅ | Uses shared endpoints (GET /settings/get, /catalog) |
| 4. UI Tests (Vite) | ✅ | Skip - would duplicate shared fetch logic tests |
| 5. Network Tests (POST) | ✅ | N/A (read-only view, no POST needed) |
| 6. Manual UI Review | ✅ | Confirmed: consistency is good |
| 7. Manual Workflow Test | ✅ | Confirmed: navigation and display working correctly |

**Shared Components Inventory**:
- [x] `OverviewCard.vue` (clickable summary cards) - Used 7 times, well-structured

**Data Displayed**:
- Basics card: `settings.projects_root`, `settings.author.name`
- Project Structure card: `settings.defaults.project_type`
- Notebooks & Scripts card: `settings.defaults.notebook_format`
- AI Assistants card: `settings.ai_config.enabled` (enabled/disabled)
- Git & Hooks card: `settings.git.auto_init` (status message)
- Packages card: `settings.packages.length` (count)
- .env Defaults card: `defaultEnvVariableCount` (computed count)

**Findings**:
```
STEP 1 - COMPONENT ASSESSMENT (✅ Complete):
- Uses OverviewCard.vue component consistently (7 instances)
- Clean structure with title prop + click handler + slot content
- FIXED: Changed text-green-600 → text-sky-600 for enabled states (AI Assistants, Git & Hooks)
- No consolidation needed - each card displays unique data
- Fallback patterns ("Not set", "No defaults set") are appropriate inline

STEP 2 - SHARED COMPONENTS (✅ Complete):
- OverviewCard.vue is the only shared component (used 7 times)
- Component is well-designed: simple, reusable, single responsibility
- No additional shared components needed for this screen

STEP 3 - R API TESTS (✅ Complete):
- Endpoints: GET /api/settings/get (plumber.R:254), GET /api/settings/catalog (plumber.R:373)
- These endpoints are shared across ALL settings sections (Overview, Basics, Packages, etc.)
- Already tested indirectly via test-api-settings.R (POST endpoint tests verify round-trip)
- No Overview-specific endpoint logic to test
- Conclusion: Dedicated tests not needed (would be redundant)

STEP 4 - UI TESTS (✅ Skipped):
- Overview uses standard fetch logic shared across all settings sections
- Testing would duplicate coverage of shared data fetching code
- Component rendering tested manually (see Step 6)

STEP 5 - NETWORK TESTS (✅ Complete/N/A):
- Overview is read-only (no POST requests)
- All network calls are GET requests to shared endpoints
- No save/update functionality to test

STEP 6 - MANUAL UI REVIEW (✅ Complete):
- Visual consistency confirmed across all cards
- Card styling, hover states, and summary text display correctly
- Sky blue accent colors applied correctly (after fix)

STEP 7 - MANUAL WORKFLOW TEST (✅ Complete):
- All 7 overview cards display with correct data
- Click navigation to sections working correctly
- Hover states and interactivity working as expected

🎉 OVERVIEW SCREEN COMPLETE - All steps passed!
```

---

### 2. Basics

**Purpose**: Core project metadata (name, author, type, description)

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /projects/:id`, `GET /settings/basics` |
| 4. UI Tests (Vite) | ⬜ | Component: Settings basics panel |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /projects/:id/basics` or `POST /settings/basics` |
| 6. Manual UI Review | ⬜ | Check: form layout, input consistency |
| 7. Manual Workflow Test | ⬜ | Flow: Edit name → save → verify persistence |

**Shared Components Inventory**:
- [ ] `ProjectTypeSelector.vue`
- [ ] `AuthorInformationPanel.vue`
- [ ] Form inputs (Button, Input, Select, etc.)
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 3. Project Structure

**Note**: This section has 4 sub-types with potentially different configurations

#### 3a. Standard Project

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/directories?type=project` |
| 4. UI Tests (Vite) | ⬜ | Component: Directory configuration panel |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/directories` |
| 6. Manual UI Review | ⬜ | Check: consistent directory input fields |
| 7. Manual Workflow Test | ⬜ | Flow: Change `notebooks` dir → save → verify |

**Shared Components Inventory**:
- [ ] `WorkspaceDirectoriesPanel.vue`
- [ ] `InputDirectoriesPanel.vue`
- [ ] `OutputDirectoriesPanel.vue`
- [ ] `RenderableWorkspacesPanel.vue`
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

#### 3b. Privacy Sensitive Project

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | Compare with Standard Project |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/directories?type=project_sensitive` |
| 4. UI Tests (Vite) | ⬜ | Verify sensitive-specific fields shown |
| 5. Network Tests (POST) | ⬜ | Verify sensitive fields saved correctly |
| 6. Manual UI Review | ⬜ | Check: visual indicators for sensitive data |
| 7. Manual Workflow Test | ⬜ | Flow: Toggle sensitivity → verify dir changes |

**Shared Components Inventory**:
- [ ] (Same as Standard Project?)
- [ ] Additional sensitive-specific components: _________________

**Findings**:
```
(Add notes here)
```

---

#### 3c. Presentation

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | Compare with Standard/Sensitive |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/directories?type=presentation` |
| 4. UI Tests (Vite) | ⬜ | Verify presentation-specific dirs shown |
| 5. Network Tests (POST) | ⬜ | Verify presentation dirs saved |
| 6. Manual UI Review | ⬜ | Check: presentation icon/labels consistent |
| 7. Manual Workflow Test | ⬜ | Flow: Create presentation project → verify structure |

**Shared Components Inventory**:
- [ ] `PresentationDirectoriesPanel.vue`
- [ ] Presentation-specific components: _________________

**Findings**:
```
(Add notes here)
```

---

#### 3d. Course

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | Compare with other types |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/directories?type=course` |
| 4. UI Tests (Vite) | ⬜ | Verify course-specific dirs shown |
| 5. Network Tests (POST) | ⬜ | Verify course dirs saved |
| 6. Manual UI Review | ⬜ | Check: course icon/labels consistent |
| 7. Manual Workflow Test | ⬜ | Flow: Create course project → verify structure |

**Shared Components Inventory**:
- [ ] `CourseDirectoriesPanel.vue`
- [ ] Course-specific components: _________________

**Findings**:
```
(Add notes here)
```

---

### 4. Packages

**Purpose**: Configure R packages for project

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/packages`, `GET /packages/available` |
| 4. UI Tests (Vite) | ⬜ | Component: Package editor/selector |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/packages` |
| 6. Manual UI Review | ⬜ | Check: package list styling, add/remove UX |
| 7. Manual Workflow Test | ⬜ | Flow: Add package → save → verify in config.yml |

**Shared Components Inventory**:
- [ ] `PackagesEditor.vue`
- [ ] Package list/table components
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 5. AI Assistants

**Purpose**: Configure AI assistant preferences

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/ai`, `GET /ai/assistants` |
| 4. UI Tests (Vite) | ⬜ | Component: AI assistants panel |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/ai` |
| 6. Manual UI Review | ⬜ | Check: toggle switches, assistant icons |
| 7. Manual Workflow Test | ⬜ | Flow: Enable assistant → save → verify in config |

**Shared Components Inventory**:
- [ ] `AIAssistantsPanel.vue`
- [ ] Toggle/switch components
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 6. Git & Hooks

**Purpose**: Configure Git integration and Framework hooks

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/git`, `GET /hooks/list` |
| 4. UI Tests (Vite) | ⬜ | Component: Git & hooks panel |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/git`, `POST /hooks/enable` |
| 6. Manual UI Review | ⬜ | Check: hook status indicators, git config forms |
| 7. Manual Workflow Test | ⬜ | Flow: Enable hook → verify .git/hooks/ updated |

**Shared Components Inventory**:
- [ ] Git configuration form
- [ ] Hook list/toggle components
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 7. Connections

**Purpose**: Configure database connections

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/connections`, `GET /connections/test` |
| 4. UI Tests (Vite) | ⬜ | Component: Connections editor |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/connections` |
| 6. Manual UI Review | ⬜ | Check: connection form fields, test button UX |
| 7. Manual Workflow Test | ⬜ | Flow: Add DB → test → save → verify in config |

**Shared Components Inventory**:
- [ ] Connection form components
- [ ] Connection type selector (SQLite/PostgreSQL)
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 8. .env Defaults

**Purpose**: Configure default environment variables

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/env` |
| 4. UI Tests (Vite) | ⬜ | Component: .env editor |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/env` |
| 6. Manual UI Review | ⬜ | Check: key-value input styling, validation |
| 7. Manual Workflow Test | ⬜ | Flow: Add env var → save → verify in .env |

**Shared Components Inventory**:
- [ ] Key-value pair editor
- [ ] Secure input fields (for secrets)
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

### 9. Scaffold Behavior

**Purpose**: Configure scaffold.R execution options

| Step | Status | Notes |
|------|--------|-------|
| 1. Component Assessment | ⬜ | |
| 2. Shared Components Used | ⬜ | |
| 3. R API Tests | ⬜ | Endpoint: `GET /settings/scaffold` |
| 4. UI Tests (Vite) | ⬜ | Component: Scaffold options panel |
| 5. Network Tests (POST) | ⬜ | Endpoint: `POST /settings/scaffold` |
| 6. Manual UI Review | ⬜ | Check: option toggles, help text clarity |
| 7. Manual Workflow Test | ⬜ | Flow: Change option → save → verify behavior |

**Shared Components Inventory**:
- [ ] Option toggles/checkboxes
- [ ] Help text/tooltips
- [ ] Other: _________________

**Findings**:
```
(Add notes here)
```

---

## Cross-Screen Analysis

### Shared Component Consolidation Opportunities

**Current Shared Components**:
- ✅ `ProjectCard.vue`
- ✅ `ProjectTypeIcon.vue`
- ✅ `ProjectAuthor.vue`
- ✅ `ProjectCreatedDate.vue`
- ✅ `InfoCard.vue`
- ✅ UI primitives (Button, Select, Input, etc.)

**Candidates for Extraction**:
- [ ] Directory input field (repeated across Project Structure screens)
- [ ] Key-value pair editor (used in .env, connections?)
- [ ] Setting section container/panel
- [ ] Form validation wrapper
- [ ] Save/cancel button group
- [ ] Other: _________________

### Design System Consistency Checks

**Typography**:
- [ ] Heading sizes consistent (h1, h2, h3)
- [ ] Font weights match design system
- [ ] Line heights appropriate

**Spacing**:
- [ ] Consistent padding in panels
- [ ] Consistent margins between sections
- [ ] Consistent gap in flex/grid layouts

**Colors**:
- [ ] Background colors consistent
- [ ] Border colors consistent
- [ ] Text colors (primary, secondary, muted) consistent
- [ ] Error/warning/success states consistent

**Icons**:
- [ ] All using Font Awesome Sharp Light
- [ ] Icon sizes consistent
- [ ] Icon colors consistent
- [ ] SVG props exposed (svgFill, svgStroke)

**Forms**:
- [ ] Input field styling consistent
- [ ] Label styling consistent
- [ ] Error message styling consistent
- [ ] Button styling consistent (primary, secondary, danger)

---

## Testing Infrastructure

### R API Test Coverage

**Test File**: `tests/testthat/test-gui-api.R` (create if needed)

**Endpoints to Test**:
- [ ] `GET /projects` - List all projects
- [ ] `GET /projects/:id` - Get project details
- [ ] `GET /settings/*` - Get all settings sections
- [ ] `POST /settings/*` - Update all settings sections
- [ ] `POST /projects/new` - Create new project
- [ ] `GET /packages/available` - List available packages
- [ ] `GET /connections/test` - Test connection
- [ ] Other: _________________

### Vite UI Test Coverage

**Test Directory**: `gui-dev/tests/integration/` and `gui-dev/tests/unit/`

**Components to Test**:
- [ ] `SettingsView.vue` - All panels render correctly
- [ ] `NewProjectView.vue` - Form validation and submission
- [ ] `ProjectDetailView.vue` - Data hydration and display
- [ ] `ProjectsView.vue` - Project list and filtering
- [ ] All shared components listed above
- [ ] Other: _________________

### Test Setup Status

**Current Status**:
- ✅ Vitest configured (`gui-dev/tests/setup.js`)
- ✅ Test utils available (mount, wrappers)
- ⬜ API mock server setup
- ⬜ Test data fixtures created
- ⬜ Integration test suite complete

---

## Progress Summary

**Overall Completion**: ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ (0/11 screens complete)

**By Category**:
- Component Assessment: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
- R API Tests: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
- UI Tests: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
- Network Tests: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
- Manual UI Review: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
- Manual Workflow: 0/11 ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜

**Blockers/Issues**:
```
(Document any blockers discovered during work)
```

**Next Steps**:
```
1. Start with Overview screen
2. Create test fixtures for mock data
3. Set up API mock server for UI tests
4. ...
```

---

## Notes & Decisions

### Architecture Decisions
```
(Document key decisions made during alignment work)
```

### Discovered Issues
```
(Log issues found but not yet fixed)
```

### Improvement Ideas
```
(Future enhancements or refactoring opportunities)
```
