DRY audit – Packages, Quarto, Git & Hooks, AI Assistants, Scaffold Behavior, Templates, .env Defaults, Connections

Scope
- Compared Screens: defaults (`src/views/SettingsView.vue`), new project (`src/views/NewProjectView.vue`), existing project (`src/views/ProjectDetailView.vue`).
- Shared components already in use: `PackagesEditor`, `GitHooksPanel`, `ScaffoldBehaviorPanel`, `ConnectionsPanel`, `EnvEditor`, `AIAssistantsPanel` (defaults missing), `QuartoSettingsPanel` (defaults only), template modals (defaults only).

Findings by screen
- Packages: Defaults use bespoke UI instead of `PackagesEditor`, so behavior diverges from new/edit screens (`SettingsView.vue:256-315` vs `NewProjectView.vue:250-256`, `ProjectDetailView.vue:469-492`). Normalization/serialization logic is duplicated across screens (`SettingsView.vue:2367-2393`, `NewProjectView.vue:545-569` and `1438-1467`, `ProjectDetailView.vue:2160-2198`). Recommendation: render `PackagesEditor` on defaults with a small wrapper for settings shape, and centralize map-to/from-API helpers.
- Quarto: Only defaults expose `QuartoSettingsPanel` (`SettingsView.vue:318-322`); new/edit only set notebook format (`NewProjectView.vue:120-127`) and offer a one-off regenerate button (`ProjectDetailView.vue:243-277`). Global Quarto defaults are not surfaced or applied in project screens. Recommendation: reuse the panel (or a pared-down variant) for project-level overrides, or clearly scope Quarto defaults to apply on creation.
- Git & Hooks: Good component reuse (`SettingsView.vue:217-235`, `NewProjectView.vue:279-285`, `ProjectDetailView.vue:533-540`) but each screen owns its own computed mappers and payload shims. Align schema mapping in a shared composable to keep defaults/new/edit in sync (e.g., hook flags and git identity handling at `SettingsView.vue:2360-2369`, `NewProjectView.vue:586-592`, `ProjectDetailView.vue:2535-2558`).
- AI Assistants: New/edit share `AIAssistantsPanel` (`NewProjectView.vue:260-276`, `ProjectDetailView.vue:495-528`) and new projects hydrate from defaults (`NewProjectView.vue:571-579`), but defaults have no rendered AI section even though the nav advertises one (`SettingsView.vue:409-416`). Defaults cannot currently be edited; add an AI block using the same panel so changes propagate to creation/edit flows.
- Scaffold Behavior: Consistently uses `ScaffoldBehaviorPanel` across screens (`SettingsView.vue:243-253`, `NewProjectView.vue:137-150`, `ProjectDetailView.vue:568-579`). No DRY gaps noted beyond shared mapper optionality.
- Templates: Templates appear in the defaults nav (`SettingsView.vue:429`) but no `activeSection === 'templates'` block renders; only the modal is defined (`SettingsView.vue:329-339`). New/edit have no template access (expected), but the defaults screen currently hides template editing entirely. Decide whether to restore a shared template editor section or remove the nav entry.
- .env Defaults: All screens use `EnvEditor` (`SettingsView.vue:121-149`, `NewProjectView.vue:231-247`, `ProjectDetailView.vue:584-600`), but env parsing/grouping helpers are duplicated in defaults and new project (`SettingsView.vue:2245-2310`, `NewProjectView.vue:787-824`) while project edit relies on API-provided groups. Recommend centralizing env parse/group/serialize helpers so defaults/new/edit share identical behavior and regroup rules.
- Connections: `ConnectionsPanel` is shared across screens (`SettingsView.vue:114-133`, `NewProjectView.vue:221-228`, `ProjectDetailView.vue:453-465`), yet normalization to/from API objects is repeated (`SettingsView.vue:2375-2392`, `NewProjectView.vue:1438-1467`, `ProjectDetailView.vue:1995-2022` and `2179-2198`). Move the object↔array mapping (and the framework_db exclusion) into a single helper to keep payload shapes aligned.

Cross-cutting
- Helper duplication: env parse/group and connections/package normalization functions are re-implemented per view; a shared composable would cut risk of schema drift.
- Missing sections: Defaults screen lists AI and Templates in the sidebar but renders neither, so defaults cannot be updated for those areas and the coupling with new/edit pages is broken.

Testing status
- Settings (Overview, Basics, Project Structure, Packages): `tests/integration/settings-ui-smoke.spec.js` passing; minor Button variant/ToastContainer warnings only.
- New Project (Basics defaults, Packages defaults, Structure visible): `tests/integration/new-project-ui-smoke.spec.js` passing with fetch mocked.
- Project Detail (Basics sidebar, Packages, Structure, .env): `tests/integration/project-detail-ui-smoke.spec.js` passing with fetch mocked.
- R/testthat (packages/renv/project create/api-split-vs-inline filters): passing via `devtools::load_all(); testthat::test_dir('tests/testthat', filter='packages|renv|project_create|api-split-vs-inline')`.
