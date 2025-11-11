# Framework Privacy Sensitive Project - Claude Code Instructions

## Project Overview

This is a Framework-based R project for **sensitive data analysis** with enhanced privacy controls and strict gitignore policies.

**CRITICAL**: This project handles sensitive data. All data directories are gitignored by default. Only public, de-identified outputs should be committed.

Framework provides:
- Strict privacy controls with public/private separation
- Encryption support for sensitive files
- Defense-in-depth gitignore strategy
- Data integrity tracking and audit trails
- Blinded results for unbiased analysis

## Directory Structure - PRIVACY FOCUSED

### Data Directories (ALL GITIGNORED)
- `inputs/` - **ALL INPUT DATA GITIGNORED** (nothing committed by default)
- `inputs_private/` - Highly sensitive inputs requiring special handling
- `work/` - Intermediate analysis files (gitignored)
- `cache/` - Cached computations (gitignored)
- `scratch/` - Temporary files (gitignored, auto-cleaned)

### Working Directories
- `notebooks/` - Analysis notebooks (commit these, but ensure no data in output cells)
- `scripts/` - Automation scripts (committed)
- `functions/` - Custom R functions (committed, auto-sourced by scaffold())
- `outputs_public/` or `outputs/public/` - **ONLY place for shareable outputs** (committed)
- `outputs_private/` or `outputs/private/` - Sensitive outputs (**NEVER committed**)

### Configuration
- `config.yml` - Project configuration (**review before committing - no secrets!**)
- `.env` - Secrets, API keys, credentials (**ALWAYS gitignored, NEVER commit**)
- `framework.db` - Metadata tracking (gitignored for sensitive projects)

## Security Workflow - MANDATORY

### 1. Start Session
```r
library(framework)
scaffold()
```

### 2. Load Encrypted Data (RECOMMENDED)
```r
# Save encrypted (first time)
data_save(sensitive_data, "patient_records", encrypt = TRUE)
# Prompts for strong passphrase

# Load encrypted
data <- data_load("patient_records")
# Prompts for passphrase to decrypt
```

### 3. Save Results - PUBLIC VS PRIVATE

**PUBLIC (de-identified, shareable):**
```r
# Summary statistics (aggregated, no PII)
result_save(summary_table, "demographics-summary", type = "table")
# → outputs_public/tables/ (WILL BE COMMITTED)

# Aggregate plots (no individual data points)
result_save(aggregate_plot, "fig-outcomes", type = "plot")
# → outputs_public/figures/ (WILL BE COMMITTED)
```

**PRIVATE (sensitive, never shared):**
```r
# Individual-level results
result_save(patient_outcomes, "individual-results", type = "data", private = TRUE)
# → outputs_private/docs/ (GITIGNORED)

# Diagnostic plots with identifiers
result_save(diagnostic_plot, "private-diagnostics", type = "plot", private = TRUE)
# → outputs_private/docs/ (GITIGNORED)
```

### 4. Blinded Analysis
```r
# Mark results as blinded to prevent accidental viewing
result_save(treatment_assignments, "treatment-groups", blind = TRUE)
# Cannot be loaded until explicitly unblinded

# When ready to unblindit
result_get("treatment-groups", unblind = TRUE)
```

## Security Best Practices - CRITICAL

### Data Privacy Rules
1. **NEVER commit raw data** - All `inputs/` directories are gitignored
2. **NEVER commit `.env`** - Store all secrets here, not in code
3. **NEVER put credentials in config.yml** - Use environment variables
4. **ALWAYS use encryption** for highly sensitive files
5. **DOUBLE-CHECK git status** before every commit:
   ```bash
   git status
   git diff --cached
   ```

### Encryption Workflow
```r
# Encrypt sensitive data
data_save(confidential_df, "patient_data", encrypt = TRUE)

# Load encrypted data
data <- data_load("patient_data")  # Prompts for passphrase

# Framework uses sodium package for industry-standard encryption
```

### Defense-in-Depth Gitignore
- **Root .gitignore** - Excludes all data directories
- **Nested .gitignore files** - Additional protection in `inputs/`, `outputs_private/`
- **Explicit patterns** - Prevents accidental `git add -f`

### Before Committing - CHECKLIST
```bash
# 1. Check what's staged
git status

# 2. Review actual diff
git diff --cached

# 3. Verify no data files
git diff --cached --name-only | grep -E 'inputs|outputs_private|\.env|\.rds|\.csv'

# 4. If clean, commit
git commit -m "your message"
```

## Framework Functions for Sensitive Data

### Data Management
- `data_load(name)` - Load with integrity checks
- `data_save(data, name, encrypt = TRUE)` - **Always encrypt sensitive data**
- `data_integrity_check(name)` - Verify no tampering
- `data_list()` - View catalog (does NOT show data contents)

### Private Results
```r
# Save to private outputs (gitignored)
result_save(obj, "name", private = TRUE)

# Blinded results (cannot view until unblinded)
result_save(obj, "name", blind = TRUE)
result_get("name", unblind = TRUE)  # Explicit unblinding required
```

### Audit Trail
```r
# Framework tracks all data operations in framework.db
# Query to see history
con <- DBI::dbConnect(RSQLite::SQLite(), "framework.db")
DBI::dbGetQuery(con, "SELECT * FROM data ORDER BY created_at DESC")
```

## Configuration for Sensitive Projects

```yaml
default:
  project_type: project_sensitive

  directories:
    notebooks: notebooks
    functions: functions
    inputs_private: inputs_private
    outputs_private: outputs_private
    outputs_public: outputs_public

  # Document data sources (but not credentials!)
  data:
    patient_records:
      path: inputs_private/patients.rds
      encrypted: true
      description: "De-identified patient data for outcomes analysis"
      # DO NOT include connection strings or credentials here
      # Use .env for secrets
```

## Tips for AI Assistants - SENSITIVE DATA PROJECT

When working with this sensitive data project:

1. **ALWAYS suggest encryption** for sensitive datasets
2. **NEVER suggest committing data files** - all inputs are gitignored
3. **Use private = TRUE** for any results with individual-level data
4. **Suggest aggregation** before saving public results
5. **Recommend blinding** for treatment assignments or randomization
6. **Verify public outputs** contain only aggregate, de-identified data
7. **Remind about .env** for any API keys or credentials
8. **Check gitignore coverage** before suggesting new file patterns
9. **Suggest audit trails** - query framework.db to track data operations
10. **Security first, always** - When in doubt, mark private

## Regulatory Compliance Notes

For HIPAA/GDPR/IRB compliance projects:
- All PHI/PII must be in gitignored directories
- Use `encrypt = TRUE` for any datasets with identifiers
- Log all data access in framework.db
- Only commit de-identified, aggregated public outputs
- Document data handling procedures in notebooks
- Use blinding for randomized trials

## Framework Package
- GitHub: https://github.com/table1/framework
- Author: Erik Westlund
- License: MIT
