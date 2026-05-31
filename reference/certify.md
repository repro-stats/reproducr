# Certify analytical outputs as a reproducibility baseline

Hashes a named list of R objects (model coefficients, summary
statistics, key scalars, data frames) and saves them alongside full
environment metadata to a local certification file (`.reproducr.rds` by
default). Later runs can call
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
to verify that results have not changed.

Think of `certify()` as a "signed receipt" for a completed analysis run.

## Usage

``` r
certify(outputs, tag, script = NULL, file = ".reproducr")
```

## Arguments

- outputs:

  A fully named list of R objects to certify. Each element is hashed
  using SHA-256 (or a base-R fallback if `digest` is not available).
  Common choices: `coef(model)`, `summary(model)$r.squared`, a results
  `data.frame`, or any key scalar.

- tag:

  `character(1)`. A human-readable label for this certification, e.g.
  `"submission-v1"` or `"pre-review"`. Tags must be unique within a
  certification file; passing a duplicate tag overwrites the existing
  record with a warning.

- script:

  `character(1)` or `NULL`. Path to the script that produced these
  outputs. Used for documentation in the certification record only; not
  validated. Default `NULL`.

- file:

  `character(1)`. Base path for the certification store. The actual file
  written is `paste0(file, ".rds")`. Default `".reproducr"`, which
  writes `.reproducr.rds` in the current working directory. Commit this
  file to version control.

## Value

Invisibly returns the certification record (a list). Prints a one-line
summary to the console.

## Certification store

All certifications for a project are accumulated in a single
`.reproducr.rds` file. You can have multiple tags representing different
stages (e.g. before and after peer review). Use
[`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md)
to inspect stored tags.

## Version control

Commit `.reproducr.rds` to your project's version control repository.
This makes the certification auditable and shareable with collaborators.

## See also

[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
to compare current outputs against a baseline;
[`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md)
to inspect stored certifications.

## Examples

``` r
model <- lm(mpg ~ wt, data = mtcars)

cert_file <- tempfile()

certify(
  outputs = list(
    coefs     = coef(model),
    r_squared = summary(model)$r.squared,
    n_obs     = nrow(mtcars)
  ),
  tag    = "baseline-v1",
  script = "analysis.R",
  file   = cert_file
)
#> reproducr: certified 3 output(s) [2026-05-31] under tag 'baseline-v1'

# See what is stored
list_certs(file = cert_file)
#>           tag                timestamp r_version                      os
#> 1 baseline-v1 2026-05-31T12:56:32+0000     4.6.0 Linux 6.17.0-1015-azure
#>   n_outputs     script
#> 1         3 analysis.R
```
