---
id: framework
title: Framework
section: features
position: 2
description: 'Core package capabilities and how the pieces fit together'
---
## Overview

The `framework` package provides a batteries-included toolkit for data teams. `scaffold()` loads your settings, establishes connections, and exposes helpers so your notebooks and scripts can focus on analysis. Surrounding functions cover project setup, data management, viewing results, and publishing work.

Use the package namespace directly or via the `$` operator:

```r
library(framework)
scaffold()

# or call functions explicitly
framework::scaffold()
framework::setup()
```

## Key Capabilities

- **Project bootstrap**: `setup()` collects defaults (author info, directories, git hooks) and writes `settings.yml`. `new_project()` applies those defaults to fresh repos.
- **Data catalog**: Define inputs in `settings.yml`, add uncataloged files from the GUI, and read them via `data_read()` / `data_save()`.
- **Automated connections**: Configure databases and object storage once, then query with `db_query()`, `db_execute()`, or browse S3 buckets with the GUI.
- **Viewing + publishing**: `view()` inspects data frames or complex objects, while `result_save()` and `publish_*()` register artifacts for reports.
- **AI + automation**: AI context templates, git hooks, and helper CLI commands keep assistants and collaborators in sync.

## Typical Workflow

1. **Configure defaults** with `framework::setup()` (directories, packages, git hooks, author info).
2. **Create or open a project**, run `scaffold()` at the top of each notebook/script to load config and activate helpers.
3. **Manage data** through the Data Catalog tab in `framework::gui()` or by editing `settings.yml`.
4. **Query sources**, transform data, and save results, relying on Framework to track dependencies and cache metadata.
5. **Share work** via built-in publishing helpers or by exporting tracked artifacts.

The remaining guides dive into each feature area—use this page as the hub for where tools live.
