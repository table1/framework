#' Framework View function that opens a DataTable in the browser using DT package
#'
#' @param x The data to view
#' @param title Optional title for the view
#' @param max_rows Maximum number of rows to display for data frames (default: 1000)
#' @return Opens a browser window with the data in a DataTable
#' @export
framework_view <- function(x, title = NULL, max_rows = 5000) {
  # Check if x is provided
  if (missing(x)) {
    stop("No data provided to view. Please provide a data frame or other viewable object as the first argument.")
  }

  # Ensure required packages are installed
  if (!requireNamespace("DT", quietly = TRUE)) {
    install.packages("DT", repos = "https://cloud.r-project.org")
  }
  if (!requireNamespace("lubridate", quietly = TRUE)) {
    install.packages("lubridate", repos = "https://cloud.r-project.org")
  }
  if (!requireNamespace("prismjs", quietly = TRUE)) {
    install.packages("prismjs", repos = c("https://ropensci.r-universe.dev", "https://cloud.r-project.org"))
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    install.packages("yaml", repos = "https://cloud.r-project.org")
  }

  # Get object information
  obj_name <- deparse(substitute(x))
  obj_type <- class(x)[1]

  # Handle different object types
  if (is.data.frame(x) || is.matrix(x)) {
    # For data frames and matrices, use DataTable
    # Format dates if they exist
    if (is.data.frame(x)) {
      x <- x |>
        mutate(across(where(lubridate::is.POSIXct), ~ format(., "%Y-%m-%d %H:%M")))
    }

    # Check if data frame is large and limit rows if necessary
    total_rows <- nrow(x)
    if (total_rows > max_rows) {
      warning(sprintf(
        "Data frame has %d rows. Only showing first %d rows. Use max_rows parameter to adjust this limit.",
        total_rows, max_rows
      ))
      x <- head(x, max_rows)
    }

    # Create the DataTable
    dt <- DT::datatable(
      x,
      caption = title %||% paste("Data:", obj_name, if (total_rows > max_rows) sprintf(" (showing %d of %d rows)", max_rows, total_rows) else ""),
      options = list(
        pageLength = 25,
        lengthMenu = list(c(10, 25, 50, 100, -1), c("10", "25", "50", "100", "All")),
        order = list(list(0, "asc")),
        dom = "Blfrtip",
        buttons = c("copy", "csv", "excel"),
        scrollX = TRUE
      ),
      extensions = c("Buttons", "Scroller"),
      filter = "top",
      selection = "none",
      class = "cell-border stripe hover",
      style = "bootstrap4"
    ) |>
      DT::formatStyle(
        columns = names(x),
        target = "row",
        backgroundColor = "white",
        "&:hover" = list(backgroundColor = "#f5f5f5")
      ) |>
      DT::formatStyle(
        columns = names(x),
        target = "cell",
        border = "1px solid #ddd"
      )

    # Add custom CSS for DataTable
    html_content <- htmltools::tagList(
      htmltools::tags$head(
        htmltools::tags$style("
          .dataTables_wrapper {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            padding: 10px;
          }
          .dataTables_wrapper .dataTables_length,
          .dataTables_wrapper .dataTables_filter,
          .dataTables_wrapper .dataTables_info,
          .dataTables_wrapper .dataTables_processing,
          .dataTables_wrapper .dataTables_paginate {
            margin: 8px 0;
          }
          .dataTables_wrapper .dataTables_length select {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 4px 8px;
            font-size: 0.9rem;
          }
          .dataTables_wrapper .dataTables_filter input {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 2px;
            font-size: 13px;
            margin-left: 8px;
          }
          .dataTables_wrapper .dataTables_info {
            font-size: 0.9rem;
            color: #666;
          }
          .dt-buttons {
            margin-bottom: 8px;
          }
          .dt-buttons .dt-button {
            background-color: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 6px 12px;
            margin-right: 8px;
            font-size: 0.9rem;
            color: #333;
            text-decoration: none;
            transition: all 0.2s ease;
          }
          .dt-buttons .dt-button:hover {
            background-color: #e9ecef;
            border-color: #ccc;
          }
          .dataTables_wrapper .dataTables_paginate {
            margin-top: 8px;
          }
          .dataTables_wrapper .dataTables_paginate ul {
            margin: 0;
            padding: 0;
            list-style: none;
            display: flex;
            gap: 4px;
          }
          .dataTables_wrapper .dataTables_paginate li {
            display: inline-block;
            margin: 0;
            padding: 0;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 6px 12px;
            background-color: #fff;
            transition: all 0.2s ease;
            display: inline-block;
            cursor: pointer;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button a {
            color: #0d5f78 !important;
            text-decoration: none !important;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button:hover {
            background-color: #e9ecef;
            border-color: #ccc;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button.current {
            background-color: #007bff !important;
            border-color: #007bff !important;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button.current a {
            color: white !important;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button.disabled {
            border-color: #eee;
            background-color: #f8f9fa;
            cursor: not-allowed;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button.disabled a {
            color: #ccc !important;
          }
          .dataTables_wrapper .dataTables_paginate .paginate_button.previous,
          .dataTables_wrapper .dataTables_paginate .paginate_button.next {
            font-weight: 500;
          }
          table.dataTable {
            font-size: 10px;
            border-collapse: collapse;
            table-layout: fixed;
            caption-side: top;
          }
          table.dataTable td,
          table.dataTable th {
            padding: 3px;
            border: 1px solid #ddd;
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }
          table.dataTable td[data-type='numeric'] {
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
          }
          table.dataTable thead th {
            background-color: #f8f9fa;
            font-weight: 700;
            font-size: 14px;
            color: #333;
            position: relative;
            padding: 4px 3px;
          }
          table.dataTable thead th:hover {
            overflow: visible;
            white-space: normal;
            height: auto;
          }
          table.dataTable tbody tr:hover {
            background-color: #f5f5f5;
          }
          table.dataTable tbody td:hover {
            overflow: visible;
            white-space: normal;
            height: auto;
            z-index: 1;
            position: relative;
            background-color: #fff;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .dataTables_wrapper .dataTables_scroll {
            margin: 8px 0;
          }
          .dataTables_wrapper .dataTables_scrollBody {
            border: 1px solid #ddd;
            border-radius: 4px;
          }
          .dataTables_wrapper .dataTables_scrollHead {
            border: 1px solid #ddd;
            border-radius: 4px 4px 0 0;
          }
          .dataTables_wrapper .dataTables_scrollFoot {
            border: 1px solid #ddd;
            border-radius: 0 0 4px 4px;
          }
          table.dataTable caption {
            font-size: 16px;
            font-weight: 700;
            color: #333;
            margin-bottom: 8px;
            padding: 12px 0;
            text-align: left;
            caption-side: top;
          }
        ")
      ),
      dt
    )
  } else if (inherits(x, c("ggplot", "plotly", "trellis", "recordedplot")) ||
    any(class(x) %in% c("histogram", "density", "boxplot", "barplot", "plot", "tsplot"))) {
    # For plots, save and display as image
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      install.packages("ggplot2", repos = "https://cloud.r-project.org")
    }

    # Create temporary file for the plot
    temp_file <- tempfile(fileext = ".png")

    # Save plot based on type
    if (inherits(x, "ggplot")) {
      ggplot2::ggsave(temp_file, x, width = 10, height = 8, dpi = 100)
    } else if (inherits(x, "plotly")) {
      # For plotly, save as HTML
      temp_file <- tempfile(fileext = ".html")
      htmlwidgets::saveWidget(x, temp_file)
    } else {
      # For other plot types (including native R plots)
      png(temp_file, width = 1000, height = 800, res = 100)
      if (inherits(x, "histogram")) {
        # For histograms, we need to replot
        plot(x,
          main = attr(x, "main") %||% "Histogram",
          xlab = attr(x, "xlab") %||% "",
          ylab = attr(x, "ylab") %||% "Frequency",
          col = attr(x, "col") %||% "steelblue"
        )
      } else if (inherits(x, "density")) {
        # For density plots
        plot(x,
          main = attr(x, "main") %||% "Density Plot",
          xlab = attr(x, "xlab") %||% "",
          ylab = attr(x, "ylab") %||% "Density"
        )
      } else {
        # For all other plot types
        print(x)
      }
      dev.off()
    }

    # Create HTML content for the plot
    html_content <- htmltools::tagList(
      htmltools::tags$head(
        htmltools::tags$link(
          rel = "stylesheet",
          href = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css"
        ),
        htmltools::tags$script(
          src = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"
        ),
        htmltools::tags$script(
          src = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-r.min.js"
        ),
        htmltools::tags$style("
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            padding: 20px;
            background-color: #f8f9fa;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .header {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #dee2e6;
          }
          .header h1 {
            margin: 0;
            font-size: 1.5rem;
            color: #212529;
          }
          .header .type {
            color: #6c757d;
            font-size: 0.9rem;
            margin-top: 5px;
          }
          .tabs {
            margin-top: 20px;
          }
          .tab-buttons {
            margin-bottom: 10px;
            border-bottom: 1px solid #dee2e6;
          }
          .tab-button {
            padding: 8px 16px;
            border: none;
            background: none;
            cursor: pointer;
            font-size: 0.9rem;
            color: #6c757d;
            border-bottom: 2px solid transparent;
            margin-right: 5px;
          }
          .tab-button:hover {
            color: #007bff;
          }
          .tab-button.active {
            color: #007bff;
            border-bottom-color: #007bff;
          }
          .tab-content {
            display: none;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
          }
          .tab-content.active {
            display: block;
          }
          .plot-container {
            text-align: center;
            margin-top: 20px;
          }
          .plot-container img {
            max-width: 100%;
            height: auto;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          pre {
            margin: 0;
            padding: 0;
            background: none;
          }
          code {
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 0.9rem;
            line-height: 1.5;
          }
        "),
        htmltools::HTML("
          <script>
            function switchTab(evt, tabId) {
              // Hide all tab content
              var tabContents = document.getElementsByClassName('tab-content');
              for (var i = 0; i < tabContents.length; i++) {
                tabContents[i].classList.remove('active');
              }

              // Remove active class from all buttons
              var tabButtons = document.getElementsByClassName('tab-button');
              for (var i = 0; i < tabButtons.length; i++) {
                tabButtons[i].classList.remove('active');
              }

              // Show the selected tab and mark its button as active
              document.getElementById(tabId).classList.add('active');
              evt.currentTarget.classList.add('active');

              // Trigger Prism to highlight the code
              if (typeof Prism !== 'undefined') {
                Prism.highlightAll();
              }
            }
          </script>
        ")
      ),
      htmltools::tags$div(
        class = "container",
        htmltools::tags$div(
          class = "header",
          htmltools::tags$h1(title %||% paste("Plot:", obj_name)),
          htmltools::tags$div(
            class = "type",
            paste("Type:", obj_type)
          )
        ),
        htmltools::tags$div(
          class = "tabs",
          htmltools::tags$div(
            class = "tab-buttons",
            htmltools::tags$button(
              class = "tab-button active",
              onclick = "switchTab(event, 'plot-tab')",
              "Plot"
            ),
            htmltools::tags$button(
              class = "tab-button",
              onclick = "switchTab(event, 'struct-tab')",
              "Structure"
            )
          ),
          htmltools::tags$div(
            id = "plot-tab",
            class = "tab-content active",
            htmltools::tags$div(
              class = "plot-container",
              if (inherits(x, "plotly")) {
                htmltools::tags$iframe(
                  src = temp_file,
                  width = "100%",
                  height = "600px",
                  style = "border: none;"
                )
              } else {
                htmltools::tags$img(src = temp_file)
              }
            )
          ),
          htmltools::tags$div(
            id = "struct-tab",
            class = "tab-content",
            htmltools::tags$pre(
              class = "language-r",
              htmltools::HTML(
                paste(capture.output(str(x)), collapse = "\n")
              )
            )
          )
        )
      )
    )
  } else {
    # For other objects, use Prism.js for syntax highlighting
    if (is.list(x) || is.environment(x)) {
      # For lists and environments, convert to YAML format
      yaml_str <- yaml::as.yaml(x)
      r_str <- paste(capture.output(str(x)), collapse = "\n")

      yaml_highlighted <- prismjs::prism_highlight_text(yaml_str, language = "yaml")
      r_highlighted <- prismjs::prism_highlight_text(r_str, language = "r")

      content <- paste0(
        '<div class="tabs">
          <div class="tab-buttons">
            <button class="tab-button active" onclick="switchTab(event, \'yaml-tab\')">YAML</button>
            <button class="tab-button" onclick="switchTab(event, \'r-tab\')">R</button>
          </div>
          <div id="yaml-tab" class="tab-content active">
            <pre class="language-yaml">', yaml_highlighted, '</pre>
          </div>
          <div id="r-tab" class="tab-content">
            <pre class="language-r">', r_highlighted, "</pre>
          </div>
        </div>"
      )
    } else if (is.function(x)) {
      # For functions, show both R and Structure representations
      r_str <- paste(capture.output(x), collapse = "\n")
      struct_str <- paste(capture.output(str(x)), collapse = "\n")

      r_highlighted <- prismjs::prism_highlight_text(r_str, language = "r")
      struct_highlighted <- prismjs::prism_highlight_text(struct_str, language = "r")

      content <- paste0(
        '<div class="tabs">
          <div class="tab-buttons">
            <button class="tab-button active" onclick="switchTab(event, \'r-tab\')">R</button>
            <button class="tab-button" onclick="switchTab(event, \'struct-tab\')">Structure</button>
          </div>
          <div id="r-tab" class="tab-content active">
            <pre class="language-r">', r_highlighted, '</pre>
          </div>
          <div id="struct-tab" class="tab-content">
            <pre class="language-r">', struct_highlighted, "</pre>
          </div>
        </div>"
      )
    } else {
      # For other objects, show both R and Structure representations
      r_str <- paste(capture.output(x), collapse = "\n")
      struct_str <- paste(capture.output(str(x)), collapse = "\n")

      r_highlighted <- prismjs::prism_highlight_text(r_str, language = "r")
      struct_highlighted <- prismjs::prism_highlight_text(struct_str, language = "r")

      content <- paste0(
        '<div class="tabs">
          <div class="tab-buttons">
            <button class="tab-button active" onclick="switchTab(event, \'r-tab\')">R</button>
            <button class="tab-button" onclick="switchTab(event, \'struct-tab\')">Structure</button>
          </div>
          <div id="r-tab" class="tab-content active">
            <pre class="language-r">', r_highlighted, '</pre>
          </div>
          <div id="struct-tab" class="tab-content">
            <pre class="language-r">', struct_highlighted, "</pre>
          </div>
        </div>"
      )
    }

    # Create HTML content for non-data frame objects
    html_content <- htmltools::tagList(
      htmltools::tags$head(
        htmltools::tags$link(
          rel = "stylesheet",
          href = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css"
        ),
        htmltools::tags$script(
          src = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"
        ),
        htmltools::tags$script(
          src = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-r.min.js"
        ),
        htmltools::tags$script(
          src = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"
        ),
        htmltools::HTML("
          <script>
            function switchTab(evt, tabId) {
              // Hide all tab content
              var tabContents = document.getElementsByClassName('tab-content');
              for (var i = 0; i < tabContents.length; i++) {
                tabContents[i].classList.remove('active');
              }

              // Remove active class from all buttons
              var tabButtons = document.getElementsByClassName('tab-button');
              for (var i = 0; i < tabButtons.length; i++) {
                tabButtons[i].classList.remove('active');
              }

              // Show the selected tab and mark its button as active
              document.getElementById(tabId).classList.add('active');
              evt.currentTarget.classList.add('active');

              // Trigger Prism to highlight the code
              if (typeof Prism !== 'undefined') {
                Prism.highlightAll();
              }
            }
          </script>
        "),
        htmltools::tags$style("
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            padding: 20px;
            background-color: #f8f9fa;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .header {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #dee2e6;
          }
          .header h1 {
            margin: 0;
            font-size: 1.5rem;
            color: #212529;
          }
          .header .type {
            color: #6c757d;
            font-size: 0.9rem;
            margin-top: 5px;
          }
          .tabs {
            margin-top: 20px;
          }
          .tab-buttons {
            margin-bottom: 10px;
            border-bottom: 1px solid #dee2e6;
          }
          .tab-button {
            padding: 8px 16px;
            border: none;
            background: none;
            cursor: pointer;
            font-size: 0.9rem;
            color: #6c757d;
            border-bottom: 2px solid transparent;
            margin-right: 5px;
          }
          .tab-button:hover {
            color: #007bff;
          }
          .tab-button.active {
            color: #007bff;
            border-bottom-color: #007bff;
          }
          .tab-content {
            display: none;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
          }
          .tab-content.active {
            display: block;
          }
          pre {
            margin: 0;
            padding: 0;
            background: none;
          }
          code {
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 0.9rem;
            line-height: 1.5;
          }
        ")
      ),
      htmltools::tags$div(
        class = "container",
        htmltools::tags$div(
          class = "header",
          htmltools::tags$h1(title %||% paste("Object:", obj_name)),
          htmltools::tags$div(
            class = "type",
            paste("Type:", obj_type)
          )
        ),
        htmltools::HTML(content)
      )
    )
  }

  # Create temporary file and save
  temp_file <- tempfile(fileext = ".html")
  htmltools::save_html(html_content, temp_file)

  # Open in browser
  utils::browseURL(temp_file)
}

#' Override the default View function with the Framework View version
#'
#' This function will replace the default View function with our Framework View version.
#' It should be called when loading the framework.
#'
#' @return Invisibly returns TRUE if successful
#' @export
use_framework_view <- function() {
  # Store the original View function
  if (!exists(".original_view", envir = .GlobalEnv)) {
    assign(".original_view", utils::View, envir = .GlobalEnv)
  }

  # Replace View with our version
  assign("View", framework_view, envir = .GlobalEnv)

  invisible(TRUE)
}

#' Restore the original View function
#'
#' This function will restore the original View function if it was overridden.
#'
#' @return Invisibly returns TRUE if successful
#' @export
restore_framework_view <- function() {
  if (exists(".original_view", envir = .GlobalEnv)) {
    assign("View", .original_view, envir = .GlobalEnv)
    rm(".original_view", envir = .GlobalEnv)
  }

  invisible(TRUE)
}
