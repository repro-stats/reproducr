# Score function calls for reproducibility risk

Takes an `audit_report` and checks every detected `pkg::fn` call against
three independent checks:

- **`"changelog"`** — matches against a curated database of known
  breaking changes in popular CRAN packages, flagging calls where the
  installed version falls in a known-risky version window.

- **`"seed_check"`** — flags stochastic functions (`rnorm`, `sample`,
  etc.) where no [`set.seed()`](https://rdrr.io/r/base/Random.html)
  appears within 50 lines above the call.

- **`"locale_check"`** — flags functions whose output is
  locale-sensitive ([`sort()`](https://rdrr.io/r/base/sort.html),
  [`format()`](https://rdrr.io/r/base/format.html),
  [`tolower()`](https://rdrr.io/r/base/chartr.html), etc.).

## Usage

``` r
risk_score(
  audit,
  methods = c("changelog", "seed_check", "locale_check"),
  min_risk = "low"
)

# S3 method for class 'risk_report'
print(x, ...)

# S3 method for class 'risk_report'
as.data.frame(x, ...)

# S3 method for class 'risk_report'
x[i, j, ...]
```

## Arguments

- audit:

  An `audit_report` object returned by
  [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md).

- methods:

  `character`. Which checks to run. Any combination of `"changelog"`,
  `"seed_check"`, `"locale_check"`. Default: all three.

- min_risk:

  `character(1)`. Minimum risk level to include in the output. One of
  `"low"` (show all), `"medium"`, or `"high"`. Default `"low"`.

- x:

  A `risk_report` object (for `print`, `as.data.frame`, and `[`).

- ...:

  Additional arguments (currently unused).

- i:

  Row index.

- j:

  Column index. When columns are subsetted and required columns are
  removed, the `"risk_report"` class is stripped so that
  `print.risk_report()` is not called on an incomplete object.

## Value

A `data.frame` of class `c("risk_report", "data.frame")` with one row
per flagged call. Columns:

- `file`:

  Source file path.

- `line`:

  Line number of the call.

- `call`:

  The `pkg::fn` string.

- `pkg_version`:

  Installed or lockfile-resolved version.

- `risk`:

  `"high"`, `"medium"`, or `"low"`.

- `check`:

  Which check flagged it: `"changelog"`, `"seed_check"`, or
  `"locale_check"`.

- `description`:

  Plain-English explanation of the risk.

- `reference`:

  URL to the relevant changelog or documentation.

Rows are ordered by risk severity (high first), then by file and line.
If no risks are found, an empty data frame with the same columns is
returned.

## Version windows

The `"changelog"` check uses a half-open version window
`(from_ver, to_ver]`: a call is flagged only if the installed version is
*greater than* `from_ver` *and* *at most* `to_ver`. This means the risk
is scoped to versions where the breaking change is known to apply.

## See also

[`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md)
to generate the input;
[`repro_report()`](https://ndohpenngit.github.io/reproducr/reference/repro_report.md)
to render the results; the `reproducr` GitHub repository to contribute
new database entries.

## Examples

``` r
script <- tempfile(fileext = ".R")
writeLines(c(
  "x <- dplyr::summarise(mtcars, n = dplyr::n())",
  "y <- stats::rnorm(100)",
  "z <- base::sort(letters)"
), script)

report <- audit_script(script, renv = FALSE, verbose = FALSE)
risks  <- risk_score(report)
print(risks)
#> 
#> -- reproducr risk score --
#> 
#>   HIGH:      0
#>   MEDIUM:    1
#>   LOW:       1
#> 
#> [MEDIUM]  stats::rnorm  (line 2 in file198819c520e6.R)
#>          Check    : seed_check
#>          Details  : rnorm() is stochastic but no set.seed() was found in the 50 lines
#>                     above this call (line 2). Output will differ across runs without
#>                     a fixed seed.
#>          Reference: https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html
#> 
#> [LOW]     base::sort  (line 3 in file198819c520e6.R)
#>          Check    : locale_check
#>          Details  : sort() output is locale-sensitive. Current locale: C. Results may
#>                     differ on machines with different LC_COLLATE or LC_TIME settings.
#>          Reference: https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html
#> 

# High-severity items only
risk_score(report, min_risk = "high")
#> 
#> -- reproducr risk score --
#> 
#>   No risks detected. All checks passed.
#> 

# Only the changelog check
risk_score(report, methods = "changelog")
#> 
#> -- reproducr risk score --
#> 
#>   No risks detected. All checks passed.
#> 
```
