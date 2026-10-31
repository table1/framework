---
id: functions
title: Functions
section: features
position: 5
description: 'Organizing reusable functions in Framework projects'
---
## Overview

Framework auto-loads functions from a `functions/` directory, allowing you to maintain a library of semantically organized utility functions that are always of available to you.

## Benefits of Auto-loading

**Semantic organization**: Group functions by purpose (cleaning, plotting, modeling) without worrying about load order.

**No boilerplate**: No `source()` calls at the top of every script that break when you rename or reorganize your project.

**Consistent environment**: Every notebook and script gets the same functions via `scaffold()`.

## The Functions Directory

Put reusable functions in `functions/`:

```text
my-project/
├── functions/
│   ├── data_cleaning.R
│   ├── plotting.R
│   └── stats_helpers.R
├── notebooks/
└── scripts/
```

When you call `scaffold()`, all `.R` files in `functions/` are automatically sourced. Your scripts just work:

```r
library(framework)
scaffold()

clean_data <- my_cleaning_function(raw_data)
```

## Configuring the Functions Directory

The default is `functions/`, but you can customize it in `settings.yml`:

```yaml
directories:
  functions: R
```

Or use multiple directories:

```yaml
directories:
  functions:
    - functions
    - helpers
    - lib
```

---

<div style="display: flex; justify-content: space-between">

[← Data Management](guide:data-management)

[Templates →](guide:templates)

</div>
