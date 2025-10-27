# README & Docs Copy Audit

## Unit: README.md — 1.0 Messaging Refresh
Status: TODO
- `README.md:5` still warns that the package is in “Active Development”; rewrite for a 1.0 launch-ready tone and surface the new stability promise.
- `README.md:17-52` mixes CLI installation with the legacy `framework-project` template; verify the one-liner in Option 2 points at the correct repo for 1.0, clarify when to choose each path, and ensure `framework new` examples match supported arguments.
- `README.md:71-120` (project type table + scaffold outputs) could use a concise summary table and first-run expectations; trim redundancy between “What Gets Created” and “Project Types”.
- Add an explicit “Stable API from v1.0 onward” callout and link to changelog/release notes so new users know where to track breaking changes.

## Unit: README.md — Core Workflow Narrative
Status: TODO
- Step numbering is inconsistent (`### 2.5`, duplicate “### 3. Load Data” after notebooks); renumber and tighten flow into a single 1 → 6 progression.
- `README.md:198-234` should either fold “Do your analysis” into step text or expand with a short example; currently it adds no guidance.
- Highlight where configuration lives vs. ad-hoc paths (`README.md:288-321`), and split advanced YAML examples into collapsible/secondary sections to keep the main flow focused.
- Audit for repeated explanations of `data_load()` and consolidate into one authoritative subsection with cross-references.

## Unit: README.md — Security & Reproducibility Sections
Status: TODO
- `README.md:451-598` is dense; consider moving the long-form encryption walkthrough into `docs/security.md` (or similar) and summarize the value props in the README.
- Clarify sodium dependency install steps (`README.md:528-533`) and mention Windows-specific guidance if needed.
- Move CI integration snippet closer to the security audit intro or into a dedicated “CI Usage” doc to keep the README approachable.
- Ensure renv guidance (`README.md:600-640`) indicates the default posture for v1.0 (opt-in vs. required) and links to any migration docs.

## Unit: docs/README.md — Navigation Improvements
Status: TODO
- Expand the “Directory Structure” to include the many standalone design notes (e.g., `cli.md`, `readme-sync.md`) so newcomers see them.
- Document how `docs/analysis/`, `docs/debug/`, and `docs/features/` interplay; right now only features/debug are described.
- Add contribution guidance for when to append vs. create a new doc, and cross-link to `readme-parts-guide.md`.
- Consider a table or index for high-priority documents to reduce scanning time.

## Unit: readme-parts/README.md — Process Clarification
Status: TODO
- Note that part ordering must stay contiguous (1…6) and codify formatting conventions (e.g., trailing newlines) to prevent build drift.
- Provide a reminder to re-run `Rscript readme-parts/build.R` after editing and to verify diffs before committing.
- Add guidance for handling shared sections with `framework-project` during release freezes (who updates first, conflict resolution).

## Unit: docs/features/README.md — Feature Lifecycle Guidance
Status: TODO
- Clarify whether the `_COMPLETED` suffix is required after merge or optional, and document archiving strategy for stale proposals.
- Add a concise example of how checklists should look once partially complete to guide contributions.
- Cross-link to any automation (e.g., CI reminders) or the roadmap so contributors understand how proposals graduate into implementation.

## Unit: inst/project_structure/*/README.md — Starter Templates
Status: TODO
- Review each template README to ensure terminology aligns with 1.0 (e.g., `settings.yml` vs. `settings.yml`, `scaffold.R` vs. `init.R`).
- Add one or two sentences about how each template differs so users choose the right starting point.
- Include direct references to the main docs (Quick Start, workflow) for onboarding consistency.

## Unit: tests/docker/README.md — Tooling Polish
Status: TODO
- Replace raw `docker-compose` commands with `docker compose` (space) once compatibility is confirmed, or note both variants.
- Add estimated startup times and health-check expectations; note Windows-specific guidance if applicable.
- Document teardown expectations for SQL Server (e.g., resetting SA password, cleaning volumes) and reference any helper scripts.
- Validate the env var names in the sample `config.test.yml` match the actual test harness.
