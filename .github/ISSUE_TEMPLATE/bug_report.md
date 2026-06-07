---
name: Bug report
about: Something is broken or producing unexpected output
title: '[BUG] '
labels: bug
assignees: ''
---

## What happened?
A clear description of the bug.

## Minimal reproducible example

```r
library(reproducr)

script <- tempfile(fileext = ".R")
writeLines("x <- dplyr::filter(mtcars, cyl == 4)", script)

report <- audit_script(script, renv = FALSE)
# What goes wrong?
```

## Expected behaviour
What did you expect?

## Actual behaviour
What actually happened? Include the full error message.

## Environment
- reproducr version: `packageVersion("reproducr")`
- R version:
- OS:
- Using renv: Yes / No
