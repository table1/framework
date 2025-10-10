#!/usr/bin/env Rscript
# Build Script for Presentation
#
# This script renders the presentation to various formats.
# Customize as needed for your project.

library(framework)
scaffold()

# Render presentation to HTML (Reveal.js)
quarto::quarto_render("presentation.qmd")

message("Presentation built successfully!")
message("Open presentation.html in your browser to view.")
