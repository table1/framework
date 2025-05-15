# .styler.fr.R
styler::style_transformer(
  style = styler::tidyverse_style(
    indent_by = 2,
    start_comments_with_one_space = TRUE,
    math_token_spacing = styler::specify_math_token_spacing(
      zero = c("+", "-", "=", "<", ">", "~"),
      one = c("*", "/", "^", "%%", "%/%", "%in%")
    ),
    reindention = styler::tidyverse_reindention(),
    line_break = styler::tidyverse_line_break(),
    space_around_operators = TRUE,
    space_around_equals = TRUE,
    space_around_math_operators = TRUE,
    space_around_curly_braces = TRUE,
    space_around_colon = TRUE,
    space_around_comma = TRUE,
    space_around_dots = TRUE,
    space_around_parens = TRUE,
    space_around_semicolon = TRUE,
    space_around_tilde = TRUE,
    space_around_unary_operators = TRUE,
    space_around_vertical_bar = TRUE,
    space_before_curly_braces = TRUE,
    space_before_colon = TRUE,
    space_before_comma = TRUE,
    space_before_dots = TRUE,
    space_before_parens = TRUE,
    space_before_semicolon = TRUE,
    space_before_tilde = TRUE,
    space_before_unary_operators = TRUE,
    space_before_vertical_bar = TRUE,
    space_after_curly_braces = TRUE,
    space_after_colon = TRUE,
    space_after_comma = TRUE,
    space_after_dots = TRUE,
    space_after_parens = TRUE,
    space_after_semicolon = TRUE,
    space_after_tilde = TRUE,
    space_after_unary_operators = TRUE,
    space_after_vertical_bar = TRUE
  )
) 