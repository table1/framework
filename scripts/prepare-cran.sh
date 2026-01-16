#!/bin/bash
# Prepare Framework package for CRAN submission
# Run from package root directory

set -e

echo "========================================"
echo "Framework CRAN Submission Preparation"
echo "========================================"
echo ""

# Get package root (script location parent)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PKG_ROOT"

echo "Package directory: $PKG_ROOT"
echo ""

# Step 1: Clean previous builds
echo "[1/5] Cleaning previous builds..."
rm -f framework_*.tar.gz
rm -rf framework.Rcheck
rm -f cran-check.log
echo "      Done."
echo ""

# Step 2: Regenerate documentation
echo "[2/5] Regenerating documentation..."
Rscript -e "devtools::document()" 2>&1 | grep -v "^>" || true
echo "      Done."
echo ""

# Step 3: Build the package
echo "[3/5] Building package tarball..."
R CMD build . 2>&1 | tail -3
TARBALL=$(ls -t framework_*.tar.gz 2>/dev/null | head -1)
if [ -z "$TARBALL" ]; then
    echo "ERROR: Build failed - no tarball created"
    exit 1
fi
echo "      Created: $TARBALL"
SIZE=$(du -h "$TARBALL" | cut -f1)
echo "      Size: $SIZE"
echo ""

# Step 4: Run CRAN checks
echo "[4/5] Running R CMD check --as-cran..."
echo "      (This may take a few minutes)"
echo ""

# Allow check to proceed without all Suggests installed
export _R_CHECK_FORCE_SUGGESTS_=false

R CMD check --as-cran "$TARBALL" 2>&1 | tee cran-check.log

# Step 5: Summary
echo ""
echo "========================================"
echo "Summary"
echo "========================================"

# Count issues (more robust grep)
ERRORS=$(grep -cE "^Status:.*ERROR" cran-check.log 2>/dev/null || echo "0")
if [ "$ERRORS" = "0" ]; then
    ERRORS=$(grep -cE "^\* checking.*ERROR$" cran-check.log 2>/dev/null || echo "0")
fi

WARNINGS=$(grep -cE "^WARNING:" cran-check.log 2>/dev/null || echo "0")
NOTES=$(grep -cE "^NOTE:" cran-check.log 2>/dev/null || echo "0")

# Parse final status line
FINAL_STATUS=$(grep "^Status:" cran-check.log 2>/dev/null | tail -1)
echo "Final: $FINAL_STATUS"
echo ""

# Check for errors/warnings in status line
if echo "$FINAL_STATUS" | grep -qE "ERROR|WARNING"; then
    echo "STATUS: NOT READY FOR SUBMISSION"
    echo ""
    echo "Review framework.Rcheck/00check.log for details."
    rm -f cran-check.log
    exit 1
else
    echo "STATUS: READY FOR SUBMISSION"
    echo ""
    echo "Tarball: $PKG_ROOT/$TARBALL"
    echo ""
    echo "Next steps:"
    echo "  1. Review any NOTEs in framework.Rcheck/00check.log"
    echo "  2. Submit at: https://cran.r-project.org/submit.html"
    echo "  3. Or use: Rscript -e \"devtools::submit_cran()\""
    echo ""
fi

# Cleanup
rm -f cran-check.log
