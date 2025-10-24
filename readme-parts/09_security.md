## Data Integrity & Security

- **Hash tracking**: All data files tracked with SHA-256 hashes
- **Locked data**: Flag files as read-only, errors on modification
- **Password-based encryption**: Ansible Vault-style encryption for sensitive data/results
- **Gitignore by default**: Private directories auto-ignored
- **Security audits**: Comprehensive security scanning with `security_audit()`

### Password-Based Encryption

Framework provides Ansible Vault-style password-based encryption for sensitive data and results. Files are encrypted using scrypt key derivation and ChaCha20-Poly1305 authenticated encryption.

**Setup:**

```r
# Option 1: Set password in .env file (recommended)
# Add to your .env file:
ENCRYPTION_PASSWORD=your-secure-password

# Option 2: Set in R session
Sys.setenv(ENCRYPTION_PASSWORD = "your-secure-password")

# Option 3: Interactive prompt (if not set, you'll be prompted)
```

**Encrypting data:**

```r
# Save encrypted data
my_data <- data.frame(ssn = c("123-45-6789", "987-65-4321"))
data_save(
  my_data,
  path = "sensitive.private.data",
  encrypted = TRUE  # Will prompt for password if not in env
)

# Or provide password directly
data_save(
  my_data,
  path = "sensitive.private.data",
  encrypted = TRUE,
  password = "specific-password"
)
```

**Loading encrypted data:**

```r
# Auto-detects encryption via magic bytes, prompts for password
data <- data_load("sensitive.private.data")

# Or provide password directly
data <- data_load("sensitive.private.data", password = "specific-password")
```

**Encrypting results (blinding):**

```r
# Save blinded result
model <- lm(mpg ~ wt, data = mtcars)
result_save(
  name = "regression_model",
  value = model,
  type = "model",
  blind = TRUE  # Encrypts the result
)

# Load blinded result (auto-detects encryption)
model <- result_get("regression_model")
```

**How it works:**
- Files are prefixed with `FWENC1` magic bytes for auto-detection
- Each encrypted file uses a unique random salt (same password = different ciphertext)
- Decryption automatically detects encrypted files - no flags needed
- Wrong password = clear error message

**Security notes:**
- Requires `sodium` package: `install.packages("sodium")`
- Password strength matters - use strong, unique passwords
- Share passwords securely (not in git commits!)
- Encrypted files are safe to commit, but manage passwords separately

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
