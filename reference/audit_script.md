# Audit an R script for reproducibility risks

Parses one or more R source files and extracts every qualified
`package::function` call, resolving the installed version of each
package. The resulting `audit_report` object is the entry point for the
rest of the `reproducr` workflow.

## Usage

``` r
audit_script(path = ".", renv = TRUE, verbose = TRUE)

# S3 method for class 'audit_report'
print(x, ...)

# S3 method for class 'audit_report'
summary(object, ...)
```

## Arguments

- path:

  `character(1)`. Path to a `.R`, `.Rmd`, or `.qmd` file **or** a
  directory. When a directory is supplied, all R-ish source files are
  scanned recursively, excluding `renv/` and `packrat/` subdirectories.
  Defaults to `"."` (the current working directory).

- renv:

  `logical(1)`. If `TRUE` and a `renv.lock` file exists in the current
  working directory, package versions are read from the lockfile rather
  than the currently installed library. Useful for stable version
  reporting in CI environments. Default `TRUE`.

- verbose:

  `logical(1)`. Whether to print progress messages. Default `TRUE`.

- x:

  An `audit_report` object (for `print`).

- ...:

  Additional arguments (currently unused).

- object:

  An `audit_report` object (for `summary`).

## Value

An S3 object of class `"audit_report"`, a list containing:

- `calls`:

  A `data.frame` with one row per detected `pkg::fn` call, columns
  `file`, `line`, `pkg`, `fn`, `pkg_version`.

- `env`:

  A list with R version, platform, OS, locale, and timezone.

- `renv_used`:

  `logical` – were versions sourced from a lockfile?

- `timestamp`:

  `POSIXct` timestamp of when the audit was run.

- `paths`:

  Character vector of files that were scanned.

## Detection approach

`audit_script()` uses regular-expression matching on source text to
extract qualified calls of the form `pkg::fn` or `pkg:::fn`. It
intentionally skips comment lines (lines beginning with `#`, after
trimming whitespace). For more robust analysis, tools that operate on
the parse tree (e.g. `lintr`) should be used alongside `reproducr`.

## What counts as a qualifying call?

Only *qualified* calls – those using `::` or `:::` – are detected.
Unqualified calls (e.g. `filter(df, x > 0)` without `dplyr::`) are not
detected because he package cannot be determined unambiguously from
source text alone. This is by design: qualifying calls is also a
reproducibility best practice.

## See also

[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
to check detected calls against the breaking-changes database;
[`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
to render the full audit;
[`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
to lock a set of outputs as a baseline.

## Examples

``` r
# Write a temporary script to audit
script <- tempfile(fileext = ".R")
writeLines(c(
  "set.seed(237)",
  "x <- dplyr::filter(mtcars, cyl == 4)",
  "y <- dplyr::summarise(x, mean_mpg = mean(mpg))",
  "z <- stats::rnorm(nrow(y))"
), script)

report <- audit_script(script, renv = FALSE, verbose = FALSE)
print(report)
#> 
#> -- reproducr audit report [2026-06-15 19:03] --
#> 
#>   Files scanned:     1
#>   Packages found:    2
#>   Calls detected:    3
#>   R version:         4.6.0
#>   Platform:          Linux 6.17.0-1018-azure
#>   Versions from:     installed library
#> 
#>   Next step: risks <- risk_score(report)
#> 

# See the detected calls as a data frame
report$calls
#>                                 file line   pkg        fn pkg_version
#> 1 /tmp/Rtmp2ILJq0/file1a1076a64919.R    2 dplyr    filter        <NA>
#> 2 /tmp/Rtmp2ILJq0/file1a1076a64919.R    3 dplyr summarise        <NA>
#> 3 /tmp/Rtmp2ILJq0/file1a1076a64919.R    4 stats     rnorm       4.6.0
```
