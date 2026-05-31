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

## Tier 1: Scan and score

### Auditing a script

The entry point is
[`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md).
It reads your R source files, extracts every qualified `pkg::fn` call,
and resolves which version of each package is in use.

``` r

# Create a small example script
script <- tempfile(fileext = ".R")
writeLines(c(
  "# Example analysis",
  "set.seed(42)",
  "x   <- dplyr::filter(mtcars, cyl == 4)",
  "y   <- dplyr::summarise(x, mean_mpg = mean(mpg), n = dplyr::n())",
  "fit <- lm(mpg ~ wt, data = x)",
  "z   <- stats::rnorm(nrow(y))",
  "out <- base::sort(unique(x$gear))"
), script)

report <- audit_script(script, renv = FALSE, verbose = FALSE)
print(report)
#> 
#> -- reproducr audit report [2026-05-31 12:56] --
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
#> 1 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    3 dplyr    filter        <NA>
#> 2 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    4 dplyr summarise        <NA>
#> 3 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    4 dplyr         n        <NA>
#> 4 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    6 stats     rnorm       4.6.0
#> 5 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    7  base      sort       4.6.0
```

### Scoring for risk

Pass the report to
[`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md)
to run three independent checks:

``` r

risks <- risk_score(report)
print(risks)
#> 
#> -- reproducr risk score --
#> 
#>   HIGH:      1
#>   MEDIUM:    0
#>   LOW:       1
#> 
#> [HIGH]    stats::rnorm  (line 6 in file1aef4b1d10e4.R)
#>          Check    : changelog
#>          Details  : In R 3.6.0, RNG defaults changed. Stochastic output from rnorm()
#>                     with the same seed will differ between R <= 3.5 and R >= 3.6.
#>          Reference: https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html
#> 
#> [LOW]     base::sort  (line 7 in file1aef4b1d10e4.R)
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
#>                                 file line         call pkg_version risk
#> 1 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    6 stats::rnorm       4.6.0 high
#> 2 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R    7   base::sort       4.6.0  low
#>          check
#> 1    changelog
#> 2 locale_check
#>                                                                                                                                 description
#> 1            In R 3.6.0, RNG defaults changed. Stochastic output from rnorm() with the same seed will differ between R <= 3.5 and R >= 3.6.
#> 2 sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#>                                                              reference
#> 1           https://stat.ethz.ch/R-manual/R-devel/doc/html/NEWS.3.html
#> 2 https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html
```

## Tier 2: Baseline and drift detection

### Certifying outputs

After running an analysis, certify the key outputs using
[`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md).

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
#> reproducr: certified 3 output(s) [2026-05-31] under tag 'baseline-v1'
```

``` r

list_certs(file = cert_file)
#>           tag                timestamp r_version                      os
#> 1 baseline-v1 2026-05-31T12:56:44+0000     4.6.0 Linux 6.17.0-1015-azure
#>   n_outputs                             script
#> 1         3 /tmp/RtmpIS6qCm/file1aef4b1d10e4.R
```

### Checking for drift

After any environment change, re-run
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md):

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
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 2 potential concern(s) (1 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
#> # Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 2 potential concern(s) (1 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
```

``` r

badge <- repro_badge(report, risks, output = "markdown")
#> ![reproducibility](https://img.shields.io/badge/reproducibility-at%20risk-red)
cat(badge)
#> ![reproducibility](https://img.shields.io/badge/reproducibility-at%20risk-red)
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
