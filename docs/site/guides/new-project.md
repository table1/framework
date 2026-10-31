---
id: new-project
title: Making a New Project
section: getting_started
position: 5
description: 'Create a new Framework project'
---
## Create a Project

After running `setup()`, create a new project from the GUI or command line.

### Using the GUI

Click **+ New Project** in the GUI sidebar, or run:

```r
framework::gui()
```

### Using the Command Line

```r
framework::new_project()
```

This prompts for a project name and location, then creates a fully configured project using your saved defaults.

You can also specify the name and location directly:

```r
new_project("my-analysis", "~/code/my-analysis")
```

## Project Types

Framework supports four project types, each with its own function:

### Standard Project

The default. Full-featured structure for data analysis:

```r
new_project("my-analysis")
```

### Sensitive Data Project

Enhanced privacy controls with separate private/public flows:

```r
new_project_sensitive("medical-study")
```

### Presentation

Minimal structure for RevealJS slides:

```r
new_presentation("quarterly-review")
```

### Course

Structured for teaching materials with slides, assignments, and modules:

```r
new_course("stats-101")
```

## What Gets Created

When you create a project, Framework:

1. Creates the directory structure based on your defaults
2. Generates a `settings.yml` with your configuration
3. Sets up `.gitignore` with sensible defaults
4. Creates IDE workspace files (VS Code/Positron)
5. Adds AI assistant configuration (CLAUDE.md) if enabled
6. Initializes git if configured
   - If git identity isn’t configured, the initial commit is skipped with a note
   - Set `git config user.name` and `git config user.email` to enable auto-commit

---

<div style="display: flex; justify-content: space-between">

[← settings.yml](guide:settings-yml)

[Core Concepts: scaffold() →](guide:scaffold)

</div>
