# Render-test environment for the framework R package.
#
# R + Quarto + the package's dependencies in a clean Linux container, so
# render/publish functions can be tested reproducibly (and away from any
# macOS-specific setup). Built multi-arch: rocker/r-ver ships arm64 and amd64,
# and P3M serves binary packages for both.
#
# Build:  docker compose -f docker/compose.yml build
# Test:   docker compose -f docker/compose.yml run --rm render-test

FROM rocker/r-ver:4.5.1

ARG QUARTO_VERSION=1.6.43

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libfreetype6-dev pandoc \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL -o /tmp/quarto.deb \
        "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${ARCH}.deb" \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb \
    && quarto check --quiet || true

# Package dependencies (Imports + the pieces render/cloud testing needs)
RUN install2.r --error --skipinstalled \
    checkmate DBI RSQLite yaml fs readr dotenv openssl lubridate jsonlite \
    plumber httr2 devtools testthat knitr rmarkdown

WORKDIR /work

# The framework repo is mounted at /opt/framework by compose
CMD ["Rscript", "/opt/framework/docker/render/test-render.R"]
