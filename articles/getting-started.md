# Getting started with reproducr

## What is reproducr?

You finish an analysis. The code runs. The numbers look right. But are
they stable?

Package updates change function behaviour silently. Stochastic code
without a fixed seed produces different results on every run. Results
certified last month may drift this month — with no error and no
warning.

`reproducr` makes these risks visible and trackable via a three-tier
workflow:

1.  **Scan & score** — parse your scripts and assess risk
2.  **Baseline & drift** — certify outputs and detect changes over time
3.  **Report & export** — generate human-readable audit reports

It works with your existing setup. If you use `renv`, `reproducr` reads
your lockfile automatically. No configuration required.

------------------------------------------------------------------------

## Why this matters — real failure modes

These are not hypothetical. Each scenario describes a class of problem
that occurs routinely in research and regulated workflows, produces no
error, and is invisible without explicit tooling.

### Scenario 1 — The collaborator upgrade problem

You write an analysis in January using dplyr 1.0.4 and share it with a
colleague who has dplyr 1.1.2.

``` r

results <- mtcars |>
  dplyr::group_by(cyl) |>
  dplyr::summarise(mean_mpg = mean(mpg))

# You then chain a further operation:
results |> dplyr::mutate(rank = dplyr::row_number())
```

In dplyr 1.0.x, `summarise()` retained grouping by default. In dplyr
1.1.x it drops the last grouping level. Your colleague’s `mutate()` now
operates on ungrouped data — the `rank` column is computed differently.
No error. No warning. Different numbers.

`reproducr` flags this immediately:

    [HIGH] dplyr::summarise
           In dplyr 1.1.0, summarise() changed its default grouping behaviour...

### Scenario 2 — The server deployment problem

You develop a model locally on R 3.5.3 and deploy to a production server
running R 3.6.2.

``` r

set.seed(42)
train_idx <- base::sample(1:nrow(data), 0.8 * nrow(data))
```

R 3.6.0 changed the default RNG algorithm for
[`sample()`](https://rdrr.io/r/base/sample.html). The same seed now
produces a different train/test split. Your model is trained on
different data than you validated locally. Accuracy metrics differ
silently across environments.

`reproducr` flags this:

    [HIGH] stats::sample
           In R 3.6.0, the default RNG algorithm changed...

### Scenario 3 — The renv false sense of security

You use `renv` to lock your environment and restore it six months later
on a new machine. Everything installs correctly but results differ.

`renv` locked `readr 2.0.1`. Your original analysis was written with
`readr 1.4.0`. The lockfile captured the version you were *already on*
when you ran `renv::init()` — past the breaking change. You never
compared against pre-2.0 output.

``` r

data <- readr::read_csv("clinical_data.csv")
# Column "patient_id" now parses as character instead of double.
# Downstream merge silently drops rows.
```

`renv` cannot detect this because it only sees versions, not behaviour.
`reproducr` sees the function call and flags it:

    [HIGH] readr::read_csv
           In readr 2.0.0, read_csv() switched to the vroom backend.
           Column type guessing changed...

------------------------------------------------------------------------

## Tier 1: Scan and score

### Auditing a script

The entry point is
[`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md).
It reads your R source files, extracts every qualified `pkg::fn` call,
and resolves which version of each package is in use.

``` r

# Create a small example script
script <- tempfile(fileext = ".R")
writeLines(c(
  "# Example analysis",
  "set.seed(237)",
  "x   <- dplyr::filter(mtcars, cyl == 4)",
  "y   <- dplyr::summarise(x, mean_mpg = mean(mpg), n = dplyr::n())",
  "fit <- lm(mpg ~ wt, data = x)",
  "z   <- stats::rnorm(nrow(y))",
  "out <- base::sort(unique(x$gear))"
), script)

report <- audit_script(script, renv = FALSE, verbose = FALSE)
print(report)
#> 
#> -- reproducr audit report [2026-06-06 09:48] --
#> 
#>   Files scanned:     1
#>   Packages found:    3
#>   Calls detected:    5
#>   R version:         4.6.0
#>   Platform:          Linux 6.17.0-1015-azure
#>   Versions from:     installed library
#> 
#>   Next step: risks <- risk_score(report)
```

``` r

report$calls
#>                                 file line   pkg        fn pkg_version
#> 1 /tmp/RtmpLeguYe/file1c07128ea8cc.R    3 dplyr    filter        <NA>
#> 2 /tmp/RtmpLeguYe/file1c07128ea8cc.R    4 dplyr summarise        <NA>
#> 3 /tmp/RtmpLeguYe/file1c07128ea8cc.R    4 dplyr         n        <NA>
#> 4 /tmp/RtmpLeguYe/file1c07128ea8cc.R    6 stats     rnorm       4.6.0
#> 5 /tmp/RtmpLeguYe/file1c07128ea8cc.R    7  base      sort       4.6.0
```

### Scoring for risk

Pass the report to
[`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
to run three independent checks:

``` r

risks <- risk_score(report)
print(risks)
#> 
#> -- reproducr risk score --
#> 
#>   HIGH:      0
#>   MEDIUM:    0
#>   LOW:       1
#> 
#> [LOW]     base::sort  (line 7 in file1c07128ea8cc.R)
#>          Check    : locale_check
#>          Details  : sort() output is locale-sensitive. Current locale: C.UTF-8.
#>                     Results may differ on machines with different LC_COLLATE or
#>                     LC_TIME settings.
#>          Reference: https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html
```

- **`"changelog"`** — checks calls against a curated database of known
  silent breaking changes
- **`"seed_check"`** — flags stochastic functions without a nearby
  [`set.seed()`](https://rdrr.io/r/base/Random.html)
- **`"locale_check"`** — flags functions whose output varies by system
  locale

``` r

# High-severity only
high_risks <- risk_score(report, min_risk = "high")

# Just the seed check
seed_issues <- risk_score(report, methods = "seed_check")
```

``` r

# As a plain data frame for downstream use
as.data.frame(risks)
#>                                 file line       call pkg_version risk
#> 1 /tmp/RtmpLeguYe/file1c07128ea8cc.R    7 base::sort       4.6.0  low
#>          check
#> 1 locale_check
#>                                                                                                                                 description
#> 1 sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#>                                                              reference
#> 1 https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html
```

## Tier 2: Baseline and drift detection

### Certifying outputs

After running an analysis, certify the key outputs using
[`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md).

``` r

cert_file <- tempfile()

model <- lm(mpg ~ wt, data = mtcars)

certify(
  outputs = list(
    coefs     = coef(model),
    r_squared = summary(model)$r.squared,
    n_obs     = nrow(mtcars)
  ),
  tag    = "baseline-v1",
  script = script,
  file   = cert_file
)
#> reproducr: certified 3 output(s) [2026-06-06] under tag 'baseline-v1'
```

``` r

list_certs(file = cert_file)
#>           tag                timestamp r_version                      os
#> 1 baseline-v1 2026-06-06T09:48:15+0000     4.6.0 Linux 6.17.0-1015-azure
#>   n_outputs                             script
#> 1         3 /tmp/RtmpLeguYe/file1c07128ea8cc.R
```

### Checking for drift

After any environment change, re-run
[`check_drift()`](https://repro-stats.github.io/reproducr/reference/check_drift.md):

``` r

result <- check_drift(
  outputs = list(
    coefs     = coef(model),
    r_squared = summary(model)$r.squared,
    n_obs     = nrow(mtcars)
  ),
  against = "baseline-v1",
  file    = cert_file
)
#> 
#> -- reproducr drift check vs 'baseline-v1' --
#> 
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 3
#>   Drifted  : 0
#>   Missing  : 0
#>   New      : 0
```

``` r

# Different model — shows drift
model2 <- lm(mpg ~ hp, data = mtcars)

check_drift(
  outputs = list(coefs = coef(model2)),
  against = "baseline-v1",
  file    = cert_file
)
#> 
#> -- reproducr drift check vs 'baseline-v1' --
#> 
#>   Verdict  : DRIFT DETECTED
#>   OK       : 0
#>   Drifted  : 1
#>   Missing  : 2
#>   New      : 0
#> 
#>   Drifted outputs:
#>     - coefs
```

## Tier 3: Report and export

``` r

repro_report(report, risks, format = "text", style = "minimal")
```

``` r

cat(repro_report(report, risks, format = "text", style = "academic"))
#> Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 1 potential concern(s) (0 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
#> # Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 1 potential concern(s) (0 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
```

``` r

badge <- repro_badge(report, risks, output = "markdown")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
cat(badge)
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
```

## The full pipeline

``` r

library(reproducr)

# Tier 1
report <- audit_script("analysis.R")
risks  <- risk_score(report)

# Tier 2
certify(
  outputs = list(coefs = coef(my_model)),
  tag     = "submission-v1"
)

check_drift(
  outputs = list(coefs = coef(my_model)),
  against = "submission-v1"
)

# Tier 3
repro_report(report, risks, format = "html", style = "pharma")
repro_badge(report, risks, output = "README")
```
