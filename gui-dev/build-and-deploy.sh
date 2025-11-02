#!/bin/bash
# Build and deploy GUI to inst/gui/

set -e  # Exit on error

echo "================================================"
echo "Building Framework GUI..."
echo "================================================"

# Navigate to gui-dev directory
cd "$(dirname "$0")"

# Build the Vue app
echo "→ Building Vue app..."
npm run build

# Copy to inst/gui/
echo "→ Copying to inst/gui/..."
rm -rf ../inst/gui/*
cp -r dist/* ../inst/gui/

echo ""
echo "✅ Build complete!"
echo ""
echo "Files deployed to: inst/gui/"
echo ""
echo "To test in production mode:"
echo "  R -e \"devtools::load_all(); framework::gui()\""
echo ""
echo "Or restart if already running:"
echo "  R -e \"devtools::load_all(); framework::gui_restart()\""
echo ""
