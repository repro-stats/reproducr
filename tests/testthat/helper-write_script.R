# Shared helper: write a named temporary R script.
# Available to all test files because testthat loads helper-*.R files first.
write_script <- function(...) {
  f <- tempfile(fileext = ".R")
  writeLines(c(...), f)
  f
}
