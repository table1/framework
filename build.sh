#!/bin/bash

# Framework Package Build Script

set -e  # Exit on error

echo "🔨 Building Framework R Package..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -f *.tar.gz
rm -rf *.Rcheck

# Generate documentation
echo "📚 Generating documentation..."
R -e "devtools::document()"

# Build package
echo "📦 Building package..."
R CMD build .

# Install package
echo "💾 Installing package..."
R CMD INSTALL *.tar.gz

# Run tests if they exist
if [ -d "tests" ]; then
    echo "🧪 Running tests..."
    R -e "testthat::test_dir('tests')"
fi

echo "✅ Package built and installed successfully!"
echo "🚀 Ready to use with library(framework)"