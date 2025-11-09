# Settings Refactor Tracker

## Current State Audit (Step 1)

### Global Configuration Keys (`~/.frameworkrc.json`)

- `projects_root` (added default `~/framework-projects`)
- `author` → `name`, `email`, `affiliation`
- `defaults`
  - `project_type`
  - `notebook_format`
  - `ide`
  - `use_git`
  - `use_renv`
  - `seed`
  - `seed_on_scaffold`
  - `ai_support`
  - `ai_assistants`
  - `ai_canonical_file` (stored, but CLI also references `ai_canonical_default`)
  - `packages` (`name`, `auto_attach`)
  - `directories` (notebooks, scripts, functions, inputs_*, outputs_*, cache, scratch)
  - `git_hooks` (`ai_sync`, `data_security`)
- `projects` (array of registered projects with `id`, `path`, `created`, metadata populated on read)
- `active_project` (optional)

### Project Wizard Inputs (`ProjectWizard.vue`)

- `directory`
- `name`
- `type` (project, course, presentation; privacy toggle promotes `project_sensitive`)
- `sensitive` (only for data projects)
- `use_git`
- `use_renv`
- `attach_defaults`

### CLI Capabilities (`inst/bin/framework-global` excerpt)

- Reads/sets IDE preference (`defaults.ide`)
- Reads/sets AI support (`defaults.ai_support`, `defaults.ai_assistants`)
- Exposes `framework::configure_global` for general updates
- No existing commands to edit template files (.gitignore, AI stubs, notebook skeletons)

### API Endpoints (`inst/plumber.R`)

- `/api/settings/get` → returns entire global config
- `/api/settings/save` → `configure_global(settings=list(...))`
- `/api/project/create` uses payload fields `project_dir`, `project_name`, `type`, `sensitive`, `use_git`, `use_renv`, `attach_defaults`, etc.

### Gaps Identified

- Need richer defaults for: IDE/workflow location, project directory templates per type, notebook template/stub, AI stub editing, git identity, .gitignore defaults, secret scanning toggle.
- Settings UI currently single-page with limited explanation; lacks tab/section structure.
- Wizard does not currently surface/allow editing of advanced defaults.
- CLI lacks helpers to open/edit template files.

---

## TODO (Step Sequencing)

1. **Design IA** – Define new tabs/subsections (Editor & Workflow, Project Structure, Scientific Notebooks, AI Assistants, Git/Version Control, Packages & Dependencies, Privacy & Security) and required config fields/templates. _Pending_
2. **Backend Enhancements** – Extend configuration schema & validation; helper functions for template file locations; API/CLI plumbing. ✅
   - Added `projects_root`, `project_types`, `git`, and `privacy` defaults.
   - Template management helpers (`framework_template_path`, etc.) + `/api/templates/*` endpoints.
   - CLI command `framework settings:edit-template <name>`.
3. **Settings UI Refactor** – Implement new layout, copy, explanations, and controls (include stubs editing affordances). ✅
   - Rebuilt `SettingsView` with tabbed navigation, expanded “Project Defaults” per type, richer copy, and template editors.
4. **Project Wizard Updates** – Pull new defaults, allow inline edits, expose advanced settings. _In progress_
5. **CLI Support** – Add commands to open/edit notebook & AI stubs, default gitignore, etc. _Depends on backend design_
6. **Testing & Polish** – Regression coverage for API, CLI, and frontend flows.

## Design Notes (Step 2 Draft)

### Proposed Navigation

- **Author Information** – Grey well with explanatory copy. Roads into CLI profile mapping.
- **Editor & Workflow**
  - IDE preference (`defaults.ide`)
  - Default random seed (`defaults.seed`, `defaults.seed_on_scaffold`)
  - Default projects root (`projects_root`)
  - Future: editor integrations (VS Code tasks, Posit support)
- **Project Structure**
  - New `project_types` config per type: directories, quarto render targets, metadata
  - Ability to reset to defaults per type
- **Scientific Notebooks**
  - Default notebook format (`defaults.notebook_format`)
  - Notebook stub template editing (stored under `~/.config/framework/templates/notebook.qmd`)
  - Quarto options shared across types
- **AI Assistants**
  - Multi-assistant selections with descriptions (Claude, GitHub Copilot, Multi-agent/OpenAI)
  - Canonical file explanation and edit link
  - Toggle for AI file sync (`defaults.git_hooks.ai_sync`?) or new field
  - Template editing for canonical file (restore default)
- **Git & Version Control**
  - Default git enable (`defaults.use_git`)
  - Git user.name/email overrides
  - Git hook options (`defaults.git_hooks`)
- **Packages & Dependencies**
  - renv defaults (`defaults.use_renv`)
  - Default packages list with auto-attach toggles; UI for add/remove
  - Maybe CRAN mirror? (TBD)
- **Privacy & Security**
  - Secret scanning default (`defaults.git_hooks.data_security` or new field)
  - Default `.gitignore` template editing (restore default)
  - Sensitive project guidance

### Template/File Handling

- Store user-editable templates in `~/.config/framework/templates/`
  - `notebook.qmd`
  - `ai/CLAUDE.md`, `ai/AGENTS.md`, etc.
  - `gitignore`
- Provide helper functions in R to read/write these safely.
- Expose CLI commands `framework settings:edit notebook`, `framework ai:edit canonical`, `framework settings:edit gitignore`.

### Data Model Changes

- Extend global defaults with `project_types` list keyed by type.
- Each entry: `directories`, `quarto`, `notebook_template`, `description`.
- Maintain backward compatibility by promoting legacy `defaults.directories` when `project_types` missing.
- Store `projects_root` (already added) under top-level.
