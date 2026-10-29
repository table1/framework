# Framework 2.0 Plan

Status: draft, 2026-10-28. Branch: `v2`.

## Goal

Framework 2.0 replaces the local GUI with two front ends: framework.pub (a
self-hostable web app) and a command-line tool, `fw`. The R package stays the
core of the system. It must work fully without the cloud.

## Principle: one contract, one implementation

A project is described by a **project spec**, a versioned JSON document. The R
package is the only code that turns a spec into files on disk. The cloud (PHP)
and the CLI (TypeScript) produce specs and validate them against a shared JSON
Schema. They never create project files themselves.

```
framework.pub ────┐
fw new (wizard) ──┼──► spec ──► framework::project_create(spec) ──► project
framework::new() ─┘
```

This removes the current split, where `.cloud_setup()` in `R/cloud.R` merges
three cloud payloads (project, settings document, and blueprint) with its own
override rules, separately from how `new()` builds a project from local
settings.

## The spec

### Layers and resolution

A spec is resolved from layers. Each layer uses the same format, so the cloud
settings document and the local user settings file (`settings.yml` in
`fw_config_dir()`, which is `tools::R_user_dir("framework", "config")` unless
`FW_CONFIG_HOME` is set) are interchangeable.

1. Package defaults for the project type (`inst/settings/`).
2. User defaults (the local user settings file, or the cloud settings
   document).
3. Blueprint fragments, in order (see "Blueprints and facets").
4. Per-project overrides (wizard answers, or the cloud project's payload).

Resolution happens only in R. The cloud sends unresolved layers and R merges
them. A function such as `framework::spec_resolve()` exposes the merge so the
CLI can preview the result by calling R.

### Draft schema

The fields follow the current `project_create()` arguments.

```yaml
spec_version: 1
name: "Vaccine uptake study"
type: project_sensitive        # project | project_sensitive | course | presentation | bare
author: { name: "", email: "", affiliation: "" }
directories: { notebooks: notebooks, logs: logs, ... }
extra_directories: []
render_dirs: { notebooks: outputs/private/notebooks }
packages: { use_renv: false, default_packages: [] }
git: { use_git: true, hooks: {}, gitignore_content: "" }
ai: { enabled: true, assistants: [claude], canonical_content: "" }
scaffold: { seed_on_scaffold: false, seed: "", set_theme_on_scaffold: true, ggplot_theme: theme_minimal }
quarto: {}
connections: { default_database: framework, default_storage_bucket: null, databases: {}, storage_buckets: {} }
files: {}                      # path -> { content, template }
skills: {}                     # name -> { content, files } or { package: true }
security: { sensitive: true }  # drives sensitive gitignore rules and security_audit()
env: {}                        # variable names; secret-looking names must be empty
data_hooks: {}                 # see "Restricted data hooks"
source:                        # where the spec came from, recorded in the project
  origin: cloud                # cloud | cli | r
  blueprint: { key: r01-analysis, version: 3 }
  study_plan: { id: "...", version: 2 }
```

The location is a parameter of creation and is not part of the spec. The
resolved spec is written into the new project (for example `.framework/spec.json`)
so the project records how it was made.

### Merge rules

`spec_resolve()` applies the layers in order. The rules depend on the field.

- Maps such as `directories`, `connections.databases`, and `files` merge by
  key, and a later layer wins.
- A map entry set to `null` removes it, so a later layer can drop a directory.
  Top-level keys cannot be null. To clear a section, a layer sets it to an
  empty object or list.
- An empty JSON array and an empty JSON object are treated the same, because
  PHP cannot distinguish them after reading from the database.
- Lists of plain values such as `ai.assistants` are combined
  in order without duplicates.
- Lists of objects that carry a `key` (`extra_directories`) or a `name`
  (`packages.default_packages`) merge by that field, and a later layer wins.
- In `files` templates (`template: true`), R replaces `{{variable}}` for a
  fixed set of variables: `project_name`, `author`, `author_email`,
  `affiliation`, and `date`. Other text in braces, such as Quarto's
  `{{< include >}}` shortcodes, is left alone. The older `{ProjectName}`
  syntax is retired.
- An `AGENTS.md` entry in `files` takes precedence over the generated stub. The
  stub is written only when nothing else provides the file.
- Text such as `git.gitignore_content` is concatenated, with a comment naming
  the layer each block came from.
- `spec_resolve()` returns a list of conflicts (keys set by more than one
  fragment) so the blueprint builder can show them.

### Sensitive projects

`security.sensitive` marks a project as handling restricted data. R uses this
flag, instead of `type == "project_sensitive"`, to choose the sensitive
gitignore rules and the stricter `security_audit()` checks. The
`project_sensitive` base type and the restricted-data facet both set it, so
adding the facet to an ordinary project makes it sensitive (decided
2026-10-29).

### Connections

The spec uses one connection shape: `default_database`,
`default_storage_bucket`, `databases`, and `storage_buckets`. This is the shape
the GUI writes and the runtime reads. `spec_resolve()` converts the older
`{options: {default_connection}, connections: {...}}` shape from the package
defaults.

### Schema files

There are two schemas.

- The **layer schema** describes a partial spec in which every field is
  optional. The cloud validates each layer it sends against it.
- The **resolved schema** describes a complete spec with required fields. R
  validates the merged result against it before creating anything.

The canonical copies live in this repository under `inst/schema/`
(`layer.v1.json` and `spec.v1.json`). They change in the same commits as
`spec_resolve()` and `project_create()`. framework-cloud and the CLI each keep
a copy pinned to a framework release tag, with a CI check that the copy matches
the file at that tag. Each repository states which `spec_version` it accepts.
The cloud validates with opis/json-schema and the CLI with ajv. Each published
version is served at a stable URL, such as
`https://framework.pub/schema/spec/v1.json`, which is also the schema's `$id`.

## Blueprints and facets

A blueprint is a base project type plus an ordered list of facets. A facet is
a small reusable layer, such as "restricted data", "manuscript", "Quarto
slides", "targets pipeline", or "Python". Users remix a blueprint by forking it
and adding or removing facets.

- The blueprint layer is an ordered list of fragments, and R merges them. The
  cloud never flattens facets into one layer.
- The spec's `source` block records each fragment's key and version.
- A fragment can carry text files (AGENTS.md, skills, notebook and script
  templates, and gitignore text) in `files`. R writes them and substitutes
  placeholders. Blueprint files are templates only, never project code or data.
- The cloud's blueprint builder previews the result by running
  `spec_resolve()` and `project_create()` under webR, writing into webR's
  in-memory file system and listing the files. All of Framework's imports are
  available in the webR package repository. `project_create()` needs a preview
  mode that skips git, renv, and opening the folder.

## AI context: skills over AGENTS.md

Framework moves task-specific guidance out of AGENTS.md and into skills.

- **AGENTS.md is the user's file.** When it is missing, `project_create()`
  writes a short stub with the project name, one sentence saying this is a
  Framework project with Framework skills, the rule that every notebook and
  script starts with `scaffold()`, and an empty Project Notes section.
  Framework never rewrites it afterward. The spec controls this with
  `ai.agents_md: stub | none`. The CLAUDE.md stub, written only when claude
  is selected, imports AGENTS.md.
- **No skills table.** Agents find skills by name and description, so the
  table in AGENTS.md is removed. The `scaffold()` rule also goes into the
  framework-workflow skill's description so the skill loads whenever an agent
  writes a notebook or script. The stub keeps that one rule because it
  applies to every file, including work where no skill loads.
- **Retired functions.** `ai_regenerate_context()`, `ai_sync_context()`, and
  the `@framework:regenerate` sections are deprecated in 2.0 and removed in a
  later release.
- **Install locations follow `ai.assistants`.** A table in the package maps
  each assistant to its skills folder and its stub file. Adding an assistant
  later means adding one row, and the schema's list of allowed assistants comes
  from the same table.

  | Assistant | Skills folder | Stub file |
  |-----------|---------------|-----------|
  | claude | `.claude/skills/` | `CLAUDE.md` (imports AGENTS.md) |
  | codex | `.agents/skills/` | none (Codex reads AGENTS.md) |
  | copilot | `.agents/skills/` | `.github/copilot-instructions.md` (points to AGENTS.md) |

  Copilot's own folder is `.github/skills/`, but it also reads
  `.agents/skills/`, so it shares Codex's folder.

  Selecting both writes both folders. When `ai.assistants` is empty or
  missing, Framework writes `.agents/skills/` only, because it is the location
  shared by more tools and an empty list is not a request for Claude-specific
  files. AGENTS.md is written whenever `ai.agents_md` is `stub`. Framework
  writes real copies, not symlinks, because Windows checkouts often turn
  symlinks into plain files. A test on 2026-10-29 showed Claude Code 2.1.312
  does not load project skills from `.agents/skills/`, which is why Claude needs
  its own folder. Recheck this in later versions.
- **Wording.** Skills state each rule once, in plain language, with its
  reason. For example, `data_read()` records a hash, so base readers bypass
  integrity tracking. Capitalized emphasis such as "CRITICAL" and "MUST" is
  removed.
- **Skills as fragment content.** Skills use their own spec key, because
  their folders depend on `ai.assistants` and only R resolves that:
  `skills: {<name>: {content, files}}`. `content` is the full SKILL.md text
  including frontmatter, and the optional `files` map holds extra files
  (scripts or references) by path relative to the skill folder. A skill can
  instead be `{package: true}`, which means "use the copy shipped with the
  installed package". The restricted-data facet uses that form for
  framework-sensitive-data, so updating the package updates the skill. Skills
  merge like other maps: by name, a later layer wins, and `null` removes one.
  R checks that each skill's frontmatter `name` matches its key and writes it
  to every folder the assistant table requires. The base skills ship in
  `inst/templates/skills/`. The cloud's skill library is seeded from a release
  tag.
- **Updating.** `ai_skills_update()` already exists (1.1.0). In 2.0 it reads
  `.framework/spec.json` to decide which skills the project should have. It
  updates every skills folder that already exists in the project, plus any
  folder that `ai.assistants` in the spec requires. A folder added by hand is
  therefore kept up to date, and a folder the user deleted is not recreated
  unless the spec asks for it. Skills without the `framework-` prefix are left
  alone. It records each installed skill's hash and skips (with a message) any
  Framework skill the user has edited, unless `force = TRUE`.

## Front ends

### R package

- `project_create(spec, location)` is the single implementation.
- `framework::new()` asks for a name, a type, and a location, and takes
  everything else from user defaults. It does not attempt a full wizard.
- `framework::new(key)` fetches layers from the cloud and calls
  `project_create()`. This replaces `setup("fw_...")`. The host comes from
  the `FW_CLOUD_URL` environment variable, then `cloud_url` in the user
  settings, then `https://framework.pub`, so a self-hosted instance works
  without code changes. The environment variable is checked first so that a
  single run or a CI job can point at a staging or local instance without
  editing settings. This order differs from the usual Framework pattern
  (settings first, then `FW_*`) on purpose.
- `framework::bootstrap()` prepares an existing project after `git clone`. It
  works without the cloud.

### fw CLI

`fw` handles interactive questions and project lifecycle, similar to `gh`.

- `fw login`, `fw logout`, and `fw status`
- `fw new` runs a wizard, writes a spec, and calls
  `Rscript -e 'framework::project_create(...)'`
- `fw new <key>` uses a spec from the cloud
- `fw bootstrap <repo>` clones a repository and runs `framework::bootstrap()`
- `fw projects` lists registered projects

The CLI is written in TypeScript and compiled to a single binary with
`bun build --compile`, because many HPC nodes do not have Node installed.

### framework.pub

- Account, user settings, blueprints, and the project registry.
- Study plans: versioned documents that a project links to by version.
- Optional document sharing and provenance records.
- It never stores data or project code. It does store the text files that
  blueprints and facets carry (AGENTS.md, skills, notebook, script, and
  presentation templates, and gitignore text), since these are templates
  (decided 2026-10-29). Provenance records hold only what the user
  chooses to push, and pushing is off by default for sensitive projects.

### Pull API

Phase 3 adds `GET /api/v2/projects/pull`. It returns the four layers in spec
format, with `spec_version` and the blueprint and study-plan versions. The
current v1 endpoint (`ProjectPullController`) stays unchanged until the R
package on `main` and `v2` has moved to v2, and can then be removed. No
released version uses v1, because CRAN 1.1.0 was built without the cloud code.
Blueprints need a version column, which is a phase 3 migration.

### Self-hosting

A self-hosted instance needs only what `new(key)` uses on day one:

- accounts with magic-link sign-in, using any SMTP server (or the log mailer
  for a single user)
- the settings document
- blueprints, seeded from the package defaults
- the project registry and project pull tokens
- the v2 pull endpoint

Document publishing, the ledger and provenance records, GitHub OAuth, R2
storage, Prometheus metrics, and passkeys are optional and off by default.
Passkeys need a stable hostname because the relying-party ID comes from
`APP_URL`.

Deployment is one Postgres database and the existing `docker-compose.yml`, with
a self-host env template that is separate from the framework.pub production
template.

## bootstrap()

`bootstrap()` makes a cloned project ready to run.

1. Restore packages (renv when enabled, otherwise install from `settings.yml`).
2. Create `.env` from `.env.example` when it is missing.
3. Run data hooks for directories that are empty.
4. Verify data hashes against the data catalog.
5. Run `scaffold()`.

The cloud can add metadata such as which hooks to expect or whom to ask for
access, but `bootstrap()` does not require it.

## Restricted data hooks

Each restricted directory can name a function that the project owns. Framework
calls the function and then checks the results against the data catalog hashes.
Credentials, paths, and files never reach the cloud.

```yaml
data_hooks:
  inputs_private_raw: functions/fetch_raw.R::fetch_raw
```

## AI safety with restricted data

Framework supports using AI agents in projects with restricted data, including
on the machine that holds the data. Agents commonly run on HPC compute nodes
(for example JHPCE), so the agent and the data are often in the same place.
Framework's guardrails are therefore the primary protection. JHPCE is one
example of this workflow, and nothing here is specific to it.

The risk is that an agent reads a restricted file, or runs R code that prints
rows, and the values are sent to the model provider.

- **Agent deny rules.** When `security.sensitive` is true, `project_create()`
  writes each selected assistant's permission settings so the agent cannot
  read restricted directories (for Claude Code, `permissions.deny` rules in
  `.claude/settings.json`). The rules come from the directory keys marked
  private. Support in Codex and Copilot needs to be checked.
- **Value-free output for agents.** When Framework detects that an agent
  started the R process, `data_read()` and related printing show column names,
  types, and row counts without values.
- **Skills** explain these rules to the agent. They are guidance, while the
  deny rules are enforcement.

## Simulated data

Simulated data lets people and agents write code without access to restricted
data. The usual pattern is to develop against simulated data, push to GitHub,
pull on the machine with the real data, and run there.

- **Data dictionary.** For each restricted dataset, Framework generates a
  dictionary of column names, types, factor levels, missingness rates, and
  value ranges, without row values. A person reviews it before it is
  committed, because factor levels and ranges can identify people. Framework
  never commits or pushes a dictionary automatically.
- **Generation.** Simulated data is generated from the dictionary by default.
  Generators that learn from the real rows, such as `synthpop`, are an explicit
  opt-in with a disclosure warning.
- **Switching.** `data_read()` returns real or simulated data depending on the
  machine. The choice comes from a `config` environment section in
  `settings.yml` (for example `default` for simulated data and `jhpce` for real
  data), so analysis code does not change between machines.
- The dictionary also gives agents the structure of the data without its
  values.

Open question: whether a dictionary needs sign-off beyond the analyst (for
example a data steward), and whether Framework records who approved it.

## Retiring the GUI

- 2.0 removes `gui()`, `inst/plumber.R`, `inst/gui/`, and `gui-dev/`, and drops
  `plumber` from Suggests.
- `setup()` becomes a short prompt for author details, or points to framework.pub.
- The GUI's 26 project-editing endpoints are replaced by editing `settings.yml`
  directly and by the existing `configure_*()` functions.

## Phases

1. **Spec in R.** Write the layer and resolved schemas, `spec_resolve()`, and
   `project_create(spec)`. Rebuild `new()` and the current cloud path on top of
   them. Record `.framework/spec.json` in new projects.
2. **bootstrap() and data hooks.** Both are cloud-independent.
3. **Cloud emits layers in spec format.** Add the v2 pull endpoint in
   `framework-cloud` and keep v1. Add blueprint versions, study plans, and a
   self-host env template.
4. **fw CLI.** `login`, `new`, `bootstrap`, and `projects`.
5. **Remove the GUI and plumber.**

## Open questions

- Does `fw new` without a key need the R package installed first, or should
  `fw` install it?
