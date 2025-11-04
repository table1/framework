#!/usr/bin/env Rscript
# Start Framework GUI backend server with dev reload

# Load the package
devtools::load_all("..")

# Start GUI without opening browser (dev uses Vite on 5173)
framework::gui(browse = FALSE)
