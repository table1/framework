### 2.5. Enhanced Data Viewing

Framework provides `view_detail()` for rich, browser-based data exploration:

```r
# Interactive table with search, filter, sort, export
view_detail(mtcars)

# Works with any R object
view_detail(iris, title = "Iris Dataset")

# Lists get tabbed YAML + R structure views
config <- read_config()
view_detail(config)  # Perfect for exploring nested configs!

# Plots get interactive display
library(ggplot2)
p <- ggplot(mtcars, aes(mpg, hp)) + geom_point()
view_detail(p)
```

**Features:**
- **DataTables interface** for data frames (search, filter, sort, pagination)
- **Export to CSV/Excel** with one click
- **Tabbed views** for lists (YAML + R structure)
- **Works everywhere** - VS Code, RStudio, Positron, terminal
- **Respects IDE viewers** - doesn't override `View()`

**When to use:**
- `View()` (IDE native) → Quick peek at data
- `view_detail()` → Deep exploration, export, complex objects
