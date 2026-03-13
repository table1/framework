# Framework Application Architecture

**Date**: 2026-03-13
**Status**: Proposed
**Audience**: Framework app repository bootstrap

## Executive Summary

Framework should move to a **local-first Electron desktop application** with a shared **TypeScript core** and **no local web server**.

The current GUI exists because the browser cannot touch the user's machine directly. In Electron, that limitation goes away. The most efficient path is therefore:

1. Keep the current **Vue UI** as the renderer layer.
2. Remove the **Plumber + localhost + proxy** architecture.
3. Move project management, YAML/JSON manipulation, scaffolding, docs browsing, and file operations into a shared **TypeScript core**.
4. Keep the **desktop app runtime fully in TypeScript** and let the R package remain a separate project-side runtime.

This preserves the strongest parts of Framework's current GUI while removing the architecture that causes most of the friction.

The app should manage Framework projects directly. It should not need to boot R, run Plumber, or proxy browser requests just to edit local files.

## Why This Direction

Framework is not a multi-user server product. It is a local project manager and workflow tool.

That means the app does not need:

- a persistent HTTP API for local-only actions
- port management
- browser sandbox workarounds
- CRAN-driven constraints on the desktop experience
- R as the owner of the GUI lifecycle

Electron is a better fit for the product being built:

- direct filesystem access through the main process
- native dialogs and system integration
- consistent Chromium runtime on Windows, macOS, and Linux
- simple process launching for `quarto`, `git`, editors, and other local tools
- easier packaging into a normal desktop application

## What The Current GUI Actually Does

Based on the current `gui-dev/` app and `inst/plumber.R`, the GUI is primarily a local project-management application. Its main jobs are:

### Global app workflows

- list registered projects
- create new projects
- import existing projects
- edit global defaults for future projects
- browse Framework documentation from `docs.db`

### Project editing workflows

- edit project basics and settings
- manage directory structures and render directories
- edit package defaults and `renv` behavior
- edit connections and `.env` defaults
- edit Quarto settings and regenerate Quarto files
- manage AI assistant files and git hook preferences
- inspect project files, inputs, outputs, results, and notebooks

### Current technical shape

- Vue renderer makes `fetch('/api/...')` calls
- R/Plumber handles filesystem access, config parsing, templates, and project mutations
- docs are served through `docs.db`
- several pieces of business logic already live in JavaScript helpers under `gui-dev/src/utils/`

This is exactly the kind of app that benefits from moving orchestration into TypeScript while leaving the R package focused on the in-project analysis/runtime layer.

## Proposed Product Boundary

### Desktop app owns

- app shell and navigation
- filesystem access
- project discovery and registry management
- YAML/JSON parsing and writing
- templates and scaffolding orchestration
- docs browsing and search
- git/quarto/tool launching
- settings validation and migrations

### The R package owns, but outside the desktop app

- `scaffold()` and other project runtime helpers used inside Framework projects
- data/query/cache/runtime helpers for analysts working in R
- docs/export generation if those artifacts continue to be produced from the package repo
- the in-project developer experience once the user is already working in R

### Things to stop making R own

- desktop app startup
- GUI routing
- config editor backend
- local HTTP transport
- generic file manipulation
- most YAML transformation work
- the GUI runtime altogether

## Recommended Architecture

### High-level model

```text
Vue renderer
    |
preload bridge
    |
Electron main process
    |
Framework TypeScript core
    |
filesystem / sqlite / child processes
                 |
                 +-- optional Quarto adapter
                 +-- optional Git adapter
```

### Principle

The renderer should never perform privileged work directly. It asks for actions through a narrow IPC API. The Electron main process validates requests and delegates to shared TypeScript services.

## Process Model

### Renderer process

- Vue 3 application
- pure UI, routing, forms, state, view composition
- no direct `fs`, `child_process`, or unrestricted shell access
- replaces `fetch('/api/...')` with `window.framework.*` calls

### Preload process

- exposes a small, explicit API surface via `contextBridge`
- validates payload shapes before forwarding to IPC
- prevents the renderer from becoming a Node shell

### Main process

- owns filesystem access
- owns child process execution
- owns dialogs, menus, recent projects, file watching, app settings
- loads shared services from the TypeScript core
- centralizes security, logging, and error handling

### Optional worker/subprocess layer

Use child processes for long-running or tool-specific work:

- `quarto`
- `git`
- package index refresh or docs indexing

These should be spawned intentionally through task-oriented commands, not exposed as arbitrary shell execution.

## Recommended Tech Stack

### Core stack

- `Electron`
- `Vue 3`
- `Vite`
- `TypeScript`
- `pnpm` workspaces

### Supporting libraries

- `yaml` or `eemeli/yaml` for comment-preserving YAML work where needed
- `zod` for IPC payload validation and config schema validation
- `better-sqlite3` for `docs.db` and any small local metadata database
- `chokidar` for file watching
- `electron-builder` for packaging
- `vitest` for unit tests
- `playwright` for desktop/e2e smoke coverage where practical

### Why this stack

- closest path from the existing Vue GUI
- one dominant implementation language for app logic
- strong cross-platform packaging story
- stable Chromium runtime, especially valuable on Linux

## New Repository Shape

Create a separate repository for the app and CLI.

```text
framework-app/
  apps/
    desktop/                 # Electron + Vue app
    cli/                     # Framework CLI built from shared core
  packages/
    core/                    # project logic, YAML, scaffolding, migrations
    contracts/               # zod schemas, IPC message types, DTOs
    docs/                    # docs.db access, search, metadata helpers
    node-adapters/           # fs, git, quarto, process utilities
    ui-shared/               # optional shared composables/components later
  resources/
    templates/               # copied or synced Framework templates
    catalogs/                # settings catalogs, static metadata
  scripts/
  package.json
  pnpm-workspace.yaml
```

## Shared Core Responsibilities

`packages/core` should become the real application engine.

It should own:

- reading and writing `settings.yml`
- reading and writing global app settings
- project registry management
- project creation/import/delete/untrack
- directory structure expansion and validation
- templates and file generation
- `.env` editing and grouping
- package/config/connection normalization
- package metadata lookups and local caching
- migrations between config versions
- project scans for notebooks, results, inputs, outputs, and docs metadata

The CLI and the desktop app should both call the same core functions.

## Compatibility Strategy

The desktop app should initially remain compatible with the existing Framework project format.

That means:

- keep `settings.yml` as the project contract
- keep existing project structures working
- keep global config compatible where practical
- keep `docs.db` as the first documentation source
- keep template outputs compatible with the current R package expectations

This avoids a destructive rewrite and allows the app and R package to coexist during migration.

## Contract Strategy

The critical architectural rule is that the app and the R package should share a project contract, not a runtime.

That contract should include:

- `settings.yml` shape and semantics
- global settings structure
- template inputs and outputs
- docs artifacts such as `docs.db`
- directory naming and project conventions

The desktop app should become the owner of GUI and project-management logic. The R package should consume the same contract inside projects.

This avoids coupling the app to R while also avoiding semantic drift.

## How Current GUI Features Map To The New App

| Current capability | New owner | Notes |
|---|---|---|
| Projects list/import/create | `core` + desktop | direct filesystem and registry operations |
| New Project Defaults screen | `core` + desktop | no server required |
| Project settings editor | `core` + desktop | YAML becomes a native concern |
| Project structure editor | `core` + desktop | existing JS mapping utilities can seed this |
| `.env` editor | `core` + desktop | pure local file editing |
| Connections editor | `core` + desktop | schema validation in TS |
| Packages editor/search | `core` + desktop | search may use static index or remote sources later |
| Quarto config editing | `core` + desktop | regeneration can call Quarto or write files directly |
| AI assistant files | `core` + desktop | direct file operations |
| Git hooks settings | `core` + desktop | direct file operations |
| Docs browser | `docs` package + desktop | query `docs.db` directly with SQLite |
| File browser / project inspection | desktop + node adapters | no browser workaround needed |
| R package runtime behavior | `framework` package | app writes compatible project config; R consumes it later |

## IPC Design

Replace REST endpoints with task-oriented IPC channels.

Good examples:

- `projects:list`
- `projects:create`
- `projects:import`
- `projects:get`
- `projects:updateSettings`
- `projects:updateEnv`
- `projects:scanFiles`
- `settings:getGlobal`
- `settings:saveGlobal`
- `docs:listCategories`
- `docs:getFunction`
- `tools:runQuarto`

Avoid generic low-level channels like:

- `fs:readAnyFile`
- `shell:runCommand`

The IPC surface should describe application intents, not arbitrary machine powers.

## Suggested State Management In The Renderer

The current large views should be gradually decomposed.

Recommended split:

- routes and page composition in Vue views
- app state in a store such as Pinia
- data access in service/composable layers calling `window.framework`
- form normalization pushed into shared utilities where possible

This will make the current massive `SettingsView.vue`, `NewProjectView.vue`, and `ProjectDetailView.vue` easier to carry forward.

## Security Model

Electron can be safe if the boundaries are clear.

Required defaults:

- `contextIsolation: true`
- `nodeIntegration: false`
- all privileged access through preload
- strict IPC schemas with validation
- no arbitrary shell execution from renderer input
- path normalization and traversal protection on all file operations
- allowlisted tool launches for `git`, `quarto`, editors, and other explicitly supported tools

## Packaging And Distribution

### First shipping target

Ship the desktop shell with no R dependency.

The app should:

- work without R installed
- detect `git` and `quarto` when those integrations matter
- show health/doctor diagnostics
- explain missing non-app dependencies clearly

### Later option

If adoption justifies it, add more opinionated toolchain management later:

- detect and help install Quarto or Git
- optionally help users install or update the Framework R package for project use
- consider deeper R-aware workflows only after the app flow is proven

Running R inside the app from day one would add a lot of complexity without improving the core project-management experience.

## Efficient Migration Plan

### Phase 1: App bootstrap

- create `framework-app` repository
- set up Electron + Vue + Vite + TypeScript
- add `pnpm` workspaces
- establish preload bridge and IPC pattern
- port the current global shell navigation and theming

### Phase 2: Shared core and compatibility

- implement global settings read/write in TS
- implement project registry read/write in TS
- implement project create/import/delete/untrack in TS
- reuse current project format and settings catalog
- add compatibility fixtures to ensure the app writes what the R package expects

### Phase 3: Port the highest-value screens

- Projects
- New Project
- New Project Defaults
- Project Detail basics/settings/packages/connections/env

These deliver most of the product value without any server.

### Phase 4: Docs and project inspection

- query `docs.db` directly
- rebuild docs browser in desktop flow
- add file browser and project scans for notebooks/results/inputs/outputs

### Phase 5: Optional tool integrations

- add Quarto execution helpers
- add Git actions where useful

### Phase 6: CLI

- ship CLI from the same core
- support commands like `init`, `import`, `doctor`, `open`, `validate`, and `make-notebook`

## What To Reuse From The Current Codebase

Reuse aggressively:

- most Vue UI components
- route/page structure where still sensible
- styling and component vocabulary
- existing JS utilities in `gui-dev/src/utils/`
- settings catalog and templates
- docs export pipeline output (`docs.db`) as an input artifact

Do not reuse blindly:

- REST endpoint assumptions
- browser-only fetch/service patterns
- giant single-file page logic without refactoring
- R as the backend for generic file mutations

## What Stays In The Framework R Package

In the medium term, the R package should remain focused on project-side runtime features:

- `scaffold()` and project runtime helpers
- data read/write helpers
- query helpers and database integrations
- caching, results, and workflow helpers
- docs generation if that remains easiest in R

The package should stop trying to be a desktop delivery mechanism. The desktop app should not need to run R in order to manage Framework projects.

## Risks And Mitigations

### Risk: rewrite ballooning into a platform rewrite

Mitigation:

- preserve file formats and project contracts first
- move orchestration, not everything, into TS
- keep the app scope centered on project management, not full runtime parity

### Risk: semantic drift between the app and the R package

Mitigation:

- treat project files and templates as the shared contract
- add compatibility fixtures from real Framework projects
- test the app against current `settings.yml` structures and templates

### Risk: Electron security getting sloppy

Mitigation:

- narrow preload API
- schema validation everywhere
- app-intent IPC design

### Risk: current Vue pages are too large to port cleanly

Mitigation:

- split logic into stores, services, and composables during migration
- port highest-value pages first

### Risk: package/runtime management becoming the whole project

Mitigation:

- do not pull R into the app runtime in v1
- ship desktop value before toolchain perfection

## Recommended MVP

The first release should focus on replacing the current browser/server workflow, not on reproducing every edge feature.

### MVP screens

- Projects list
- New Project
- Project detail: overview, basics, structure, packages, connections, `.env`
- New Project Defaults
- Documentation browser
- Diagnostics / Doctor screen

### MVP capabilities

- create/import/open/untrack/delete projects
- edit global and project settings
- write templates and config files
- scan project files locally
- launch editor / folder / terminal
- optionally run Quarto- or Git-related actions when installed

If this is smooth, the product already beats the current GUI experience.

## Final Recommendation

Build Framework App as a separate **Electron + Vue + TypeScript** repository with a shared core and no local web server.

Use the current GUI as a UI starting point, not as a backend architecture to preserve.

The most efficient path is:

1. keep the existing Vue investment
2. replace REST with IPC
3. move local project logic into TypeScript
4. keep the desktop app runtime out of R
5. let the R package remain the in-project runtime engine
6. ship a desktop app that feels native because it acts on the local machine directly

That gives Framework a cleaner product boundary, a better user experience, and a much more scalable foundation for both desktop and CLI workflows.
