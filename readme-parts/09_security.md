## Data Integrity & Security

- **Hash tracking**: All data files tracked with SHA-256 hashes
- **Locked data**: Flag files as read-only, errors on modification
- **Encryption**: AES encryption for sensitive data/results
- **Gitignore by default**: Private directories auto-ignored
- **Security audits**: Comprehensive security scanning with `security_audit()`

### Security Auditing

Framework includes `security_audit()` to detect data leaks and security issues:

```r
# Run comprehensive security audit
audit <- security_audit()

# Quick audit (skip git history)
audit <- security_audit(check_git_history = FALSE)

# Auto-fix issues (updates .gitignore)
audit <- security_audit(auto_fix = TRUE)

# Limit git history depth for faster scanning
audit <- security_audit(history_depth = 100)
```

**What it checks:**
- **Gitignore coverage**: Verifies private data directories are in `.gitignore`
- **Private data exposure**: Detects if private data files are tracked by git
- **Git history leaks**: Scans commit history for accidentally committed sensitive data
- **Orphaned files**: Finds data files outside configured directories

**Example output:**
```r
=== Security Audit Summary ===

✓ PASS: gitignore coverage (0 issues)
✓ PASS: private data exposure (0 issues)
✗ FAIL: git history (2 issues)
⚠ WARNING: orphaned files (3 issues)

=== Recommendations ===

 : CRITICAL: Private data files found in git history!
 : Consider using git-filter-repo to remove sensitive data
 : Found 3 data file(s) outside configured directories
 : Move orphaned files to appropriate data directories

✗ AUDIT FAILED: Critical security issues found
```

**Results structure:**
```r
str(audit, max.level = 2)
# List of 4
#  $ summary        : data.frame with check names, status, counts
#  $ findings       : List of 4
#   ..$ gitignore_issues      : data.frame
#   ..$ git_history_issues    : data.frame
#   ..$ orphaned_files        : data.frame
#   ..$ private_data_exposure : data.frame
#  $ recommendations: Character vector of actionable fixes
#  $ audit_metadata : List with timestamp, framework version, config
```

**Integration with CI/CD:**
```r
# In your CI pipeline or pre-commit hook
audit <- security_audit(verbose = FALSE)
if (any(audit$summary$status == "fail")) {
  stop("Security audit failed! Review findings.")
}
```
