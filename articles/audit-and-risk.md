# Auditing scripts and scoring risk

This vignette covers Tier 1 of the `reproducr` workflow in depth:
[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
and
[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md).
If you are new to the package, read the [getting
started](https://repro-stats.github.io/reproducr/articles/getting-started.md)
vignette first.

## How `audit_script()` detects calls

[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
reads your R source files line by line and extracts every *qualified*
function call — one that uses the `::` or `:::` namespace operator.

``` r

dplyr::filter(df, x > 0)      # detected  — pkg = "dplyr", fn = "filter"
filter(df, x > 0)              # not detected — package ambiguous
dplyr:::internal_fn()          # detected  — pkg = "dplyr", fn = "internal_fn"
```

Unqualified calls are intentionally ignored. The package cannot
determine which package a bare
[`filter()`](https://rdrr.io/r/stats/filter.html) call belongs to from
source text alone, and guessing would produce false positives. Using
explicit namespacing (`pkg::fn`) is itself a reproducibility best
practice, and
[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
rewards it.

### What gets skipped

The parser skips two things:

**Pure comment lines** — any line whose first non-whitespace character
is `#`:

``` r
# dplyr::filter(df, x > 0)    ← skipped entirely
  # also skipped
x <- dplyr::filter(df, x > 0)  ← detected
```

**Trailing inline comments** — the part of a line after `#`:

``` r

x <- 1  # dplyr::not_this()   ← "not_this" is NOT detected
```

### Single-file vs directory scan

``` r

# Single file
report <- audit_script("analysis.R")

# All scripts in a directory (recursive)
report <- audit_script("R/")

# Whole project
report <- audit_script(".")
```

When scanning a directory, `reproducr` automatically excludes `renv/`,
`packrat/`, `node_modules/`, and hidden directories (those starting with
`.`) so library source files do not pollute your results.

### Version resolution

[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
resolves the version of every detected package from one of two sources,
in order of preference:

1.  **`renv.lock`** — if an `renv.lock` file exists in the working
    directory and `renv = TRUE` (the default), versions are read from
    the lockfile. This gives stable, reproducible version information in
    CI environments where the installed library may differ from the
    project’s declared versions.

2.  **Installed library** — if no `renv.lock` is present (or
    `renv = FALSE`),
    [`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
    calls
    [`installed.packages()`](https://rdrr.io/r/utils/installed.packages.html)
    to resolve versions from whatever is currently installed.

``` r

script <- tempfile(fileext = ".R")
writeLines(c(
  "x <- dplyr::filter(mtcars, cyl == 4)",
  "y <- ggplot2::ggplot(x, ggplot2::aes(mpg, wt))"
), script)

# renv = FALSE — use installed library (no renv.lock in tempdir)
report <- audit_script(script, renv = FALSE, verbose = FALSE)

# Version column — NA means the package is not installed
report$calls[, c("pkg", "fn", "pkg_version")]
#>       pkg     fn pkg_version
#> 1   dplyr filter        <NA>
#> 2 ggplot2 ggplot        <NA>
#> 3 ggplot2    aes        <NA>
```

### The `audit_report` object

The return value is a list of class `"audit_report"`. Its components
are:

| Component   | Type         | Description                               |
|-------------|--------------|-------------------------------------------|
| `calls`     | `data.frame` | One row per detected call                 |
| `env`       | `list`       | R version, platform, OS, locale, timezone |
| `renv_used` | `logical`    | Were versions from `renv.lock`?           |
| `timestamp` | `POSIXct`    | When the audit ran                        |
| `paths`     | `character`  | Files that were scanned                   |

``` r

report <- audit_script(script, renv = FALSE, verbose = FALSE)

# Environment fingerprint
report$env
#> $r_version
#> [1] "4.6.0"
#> 
#> $r_platform
#> [1] "x86_64-pc-linux-gnu"
#> 
#> $os
#> [1] "Linux 6.17.0-1018-azure"
#> 
#> $locale
#> [1] "LC_CTYPE=C.UTF-8;LC_NUMERIC=C;LC_TIME=C.UTF-8;LC_COLLATE=C.UTF-8;LC_MONETARY=C.UTF-8;LC_MESSAGES=C.UTF-8;LC_PAPER=C.UTF-8;LC_NAME=C;LC_ADDRESS=C;LC_TELEPHONE=C;LC_MEASUREMENT=C.UTF-8;LC_IDENTIFICATION=C"
#> 
#> $timezone
#> [1] "UTC"

# Files scanned
report$paths
#> [1] "/tmp/RtmpWavq6O/file1a97435252f.R"

# Programmatic summary
s <- summary(report)
s$n_calls
#> [1] 3
s$calls_per_pkg
#>   dplyr ggplot2 
#>       1       2
```

------------------------------------------------------------------------

## How `risk_score()` works

[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
runs up to three independent checks on the calls detected by
[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md).
Each check is self-contained — they can be run in any combination.

### Check 1: `"changelog"` — the breaking-changes database

This is the most powerful check.
[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
looks up every detected `pkg::fn` call in an internal database of known
cases where a package update silently changed a function’s behaviour
without producing an error or warning.

For each match, it checks whether the installed (or locked) version
falls inside a *risk window* — a half-open interval
`(from_ver, to_ver]`:

    installed version > from_ver  AND  installed version <= to_ver
             ↑                                    ↑
       last "safe" version          first version where the
       (not inclusive)               breaking change applies

A version outside the window is not flagged, even if the function is in
the database. This avoids false positives for users on older or newer
versions where the specific change does not apply.

``` r

# Write a script that calls a function with a known breaking change
risky_script <- tempfile(fileext = ".R")
writeLines(c(
  "# dplyr 1.1.0 changed summarise() grouping behaviour",
  "x <- dplyr::group_by(mtcars, cyl)",
  "y <- dplyr::summarise(x, mean_mpg = mean(mpg))",
  "z <- stringr::str_c('a', NA)" # str_c NA-handling changed in 1.5.0
), risky_script)

report <- audit_script(risky_script, renv = FALSE, verbose = FALSE)
risks <- risk_score(report, methods = "changelog")
print(risks)
#> 
#> -- reproducr risk score --
#> 
#>   No risks detected. All checks passed.
```

The database currently covers breaking changes in: `dplyr`, `tidyr`,
`ggplot2`, `readr`, `purrr`, `stringr`, `lubridate`, `broom`,
`data.table`, `lme4`, and base R (the R 3.6.0 RNG change and the R 4.0.0
[`hclust()`](https://rdrr.io/r/stats/hclust.html) tie-breaking change).
See the [contributing to the
database](https://repro-stats.github.io/reproducr/articles/contributing-to-the-database.md)
vignette to add new entries.

### Check 2: `"seed_check"` — missing `set.seed()`

This check finds every call to a stochastic function and verifies that a
[`set.seed()`](https://rdrr.io/r/base/Random.html) call appears within
the 50 lines above it in the same file.

Stochastic functions covered:

    stats::sample    stats::runif     stats::rnorm     stats::rbinom
    stats::rpois     stats::rexp      stats::rgamma    stats::rbeta
    stats::rcauchy   stats::rchisq    stats::rf        stats::rt
    stats::rgeom     stats::rhyper    stats::rnbinom   stats::rweibull
    base::sample     base::sample.int

``` r

seed_script <- tempfile(fileext = ".R")
writeLines(c(
  "# First call — no seed above it",
  "x <- stats::rnorm(100)",
  "",
  "# Second call — seed present within 50 lines",
  "set.seed(237)",
  "y <- stats::rbinom(100, 1, 0.5)",
  "",
  "# Third call — seed is there but 60 lines away (beyond the window)",
  rep("z <- 1", 55),
  "w <- stats::runif(10)"
), seed_script)

report <- audit_script(seed_script, renv = FALSE, verbose = FALSE)
risks <- risk_score(report, methods = "seed_check")
as.data.frame(risks)[, c("line", "call", "risk", "description")]
#>   line         call   risk
#> 1    2 stats::rnorm medium
#> 2   64 stats::runif medium
#>                                                                                                                                         description
#> 1  rnorm() is stochastic but no set.seed() was found in the 50 lines above this call (line 2). Output will differ across runs without a fixed seed.
#> 2 runif() is stochastic but no set.seed() was found in the 50 lines above this call (line 64). Output will differ across runs without a fixed seed.
```

The 50-line window is intentional: a
[`set.seed()`](https://rdrr.io/r/base/Random.html) call at the top of a
500-line script does not protect a stochastic call at the bottom,
because code is refactored, reordered, and split across files over time.

### Check 3: `"locale_check"` — locale-sensitive operations

This check flags functions whose output depends on the system locale:

    base::sort      base::order     base::format
    base::toupper   base::tolower   base::strftime
    base::as.Date   base::sprintf

``` r

locale_script <- tempfile(fileext = ".R")
writeLines(c(
  "x <- base::sort(c('banana', 'apple', 'cherry'))",
  "y <- base::format(3.14159, digits = 3)",
  "z <- base::strftime(Sys.time(), '%B')" # month name is locale-dependent
), locale_script)

report <- audit_script(locale_script, renv = FALSE, verbose = FALSE)
risks <- risk_score(report, methods = "locale_check")
as.data.frame(risks)[, c("call", "risk", "description")]
#>             call risk
#> 1     base::sort  low
#> 2   base::format  low
#> 3 base::strftime  low
#>                                                                                                                                     description
#> 1     sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> 2   format() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> 3 strftime() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
```

These are rated `"low"` risk because most analyses running on the same
OS with the same locale will produce identical results. The risk
materialises when code is moved to a server in a different country, or
when a Docker container has a different `LC_ALL` setting.

**Scenario — The international collaboration problem**

Your analysis runs correctly on your Brussels workstation. A
collaborator in the US runs the exact same code and gets different
patient group orderings.

``` r

sorted_ids <- base::sort(patient_ids)
# "é" sorts after "z" under LC_COLLATE=en_US.UTF-8
# but between "e" and "f" under LC_COLLATE=fr_BE.UTF-8
```

The downstream merge uses `sorted_ids` as a key. The groupings differ.
Table 2 in the paper is different in the two labs — with no error thrown
anywhere. `reproducr` flags
[`base::sort()`](https://rdrr.io/r/base/sort.html) as locale-sensitive
so you know to pin the locale explicitly:

``` r

# Pin locale for reproducible sorting
Sys.setlocale("LC_COLLATE", "C")
sorted_ids <- base::sort(patient_ids)
```

------------------------------------------------------------------------

## Combining checks and filtering

All three checks run by default. You can select any subset:

``` r

full_script <- tempfile(fileext = ".R")
writeLines(c(
  "x <- dplyr::summarise(mtcars, n = dplyr::n())",
  "y <- stats::rnorm(10)",
  "z <- base::sort(letters)"
), full_script)

report <- audit_script(full_script, renv = FALSE, verbose = FALSE)

# All checks
all_risks <- risk_score(report)

# Changelog only
changelog_risks <- risk_score(report, methods = "changelog")

# Seed and locale only
other_risks <- risk_score(report, methods = c("seed_check", "locale_check"))

nrow(all_risks)
#> [1] 2
nrow(changelog_risks)
#> [1] 0
nrow(other_risks)
#> [1] 2
```

Filter by minimum severity with `min_risk`:

``` r

# Only items worth acting on immediately
high_only <- risk_score(report, min_risk = "high")

# Medium and above
medium_up <- risk_score(report, min_risk = "medium")

# Everything (default)
all_items <- risk_score(report, min_risk = "low")

c(high = nrow(high_only), medium_up = nrow(medium_up), all = nrow(all_items))
#>      high medium_up       all 
#>         0         1         2
```

------------------------------------------------------------------------

## Working with the results

[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
returns a `risk_report` object that inherits from `data.frame`, so all
standard data frame operations work directly:

``` r

risks <- risk_score(report)

# Standard subsetting
risks[risks$check == "seed_check", ]
#> 
#> -- reproducr risk score --
#> 
#>   HIGH:      0
#>   MEDIUM:    1
#>   LOW:       0
#> 
#> [MEDIUM]  stats::rnorm  (line 2 in file1a972848c4a0.R)
#>          Check    : seed_check
#>          Details  : rnorm() is stochastic but no set.seed() was found in the 50 lines
#>                     above this call (line 2). Output will differ across runs without
#>                     a fixed seed.
#>          Reference: https://stat.ethz.ch/R-manual/R-devel/library/base/html/Random.html

# Count by risk level
table(risks$risk)
#> 
#>    low medium 
#>      1      1

# Convert to plain data.frame (drops the extra class)
df <- as.data.frame(risks)
class(df)
#> [1] "data.frame"
```

You can pipe results into any tidy workflow:

``` r

library(dplyr)

risk_score(report) |>
  filter(risk == "high") |>
  select(call, line, description) |>
  arrange(line)
```

------------------------------------------------------------------------

## Practical interpretation

**High risk** — take action before submitting. These are cases where the
function’s output values are known to silently change between versions.
At minimum, pin the package version in your `renv.lock` and document the
version in your methods section.

**Medium risk** — review carefully. An argument may have been renamed,
deprecated, or a stochastic function lacks a seed. Your results may
differ across runs or environments.

**Low risk** — be aware. Locale-sensitive functions are unlikely to
differ on your development machine, but worth noting if the analysis
will run on a different OS or server.

**No risks detected** — all detected calls are either not in the
breaking- changes database, or outside any known risky version window,
and no stochastic or locale issues were found. This is a positive
signal, not a guarantee — the database does not cover every possible
package.
