## Core Workflow

### 1. Initialize Your Session

```r
library(framework)
scaffold()  # Loads packages, functions, config, standardizes working directory
```

### 2. Load Data

Use `data_load()` to read data with automatic integrity tracking. Every read is logged in the framework database with a SHA-256 hash, so you'll be notified if source data changes.

**Configure in `config.yml`:**

```yaml
data:
  source:
    private:
      survey:
        path: data/source/private/survey.csv
        type: csv
        locked: true  # Errors if file changes
```

**Then load with dot notation:**

```r
df <- data_load("source.private.survey")
```

**Or point directly to a file:**

You can still read files without having them in your configuration. This approach still provides data integrity tracking:

```r
df <- data_load("data/example.csv")       # Framework detects type
df <- data_load("data/stata_file.dta")    # Stata
df <- data_load("data/spss_file.sav")     # SPSS
```

### 3. Do your analysis

Do your work.
