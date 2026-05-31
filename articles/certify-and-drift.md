# Certifying outputs and detecting drift

This vignette covers Tier 2 of the `reproducr` workflow in depth:
[`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md),
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md),
and
[`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md).
These three functions together form the *baseline and drift detection*
system.

## The problem they solve

`renv` freezes the package versions you declare. But packages change
hands, maintainers push silent fixes, platform-level libraries (BLAS,
LAPACK) get updated by system administrators, and R itself changes RNG
defaults between minor versions. Any of these can alter your numerical
results without producing an error.

[`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md)
and
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
detect this. The idea is simple:

1.  After a successful analysis run, hash the key outputs and store the
    hashes.
2.  Later — after any change to the environment — re-run the analysis
    and compare the new hashes against the stored ones.
3.  Any mismatch is reported explicitly, by output name.

------------------------------------------------------------------------

## `certify()` — creating a baseline

### What gets hashed

Pass a fully named list of any R objects you want to protect. Common
choices:

``` r

model <- lm(mpg ~ wt + cyl, data = mtcars)

certify(
  outputs = list(
    # Model parameters
    coefs       = coef(model),
    r_squared   = summary(model)$r.squared,
    sigma       = sigma(model),

    # Key data properties
    n_obs       = nrow(mtcars),
    n_complete  = sum(complete.cases(mtcars)),

    # A summary table
    group_means = aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
  ),
  tag    = "baseline-v1",
  script = "analysis.R",
  file   = cert_file
)
#> reproducr: certified 6 output(s) [2026-05-31] under tag 'baseline-v1'
```

Any R object that can be serialised works: numeric vectors, data frames,
matrices, lists, character vectors, and scalars. The hash is computed
with SHA-256 via the `digest` package if available, or a base-R fallback
otherwise.

### Choosing what to certify

Certify outputs that are:

- **Conclusions** — the numbers that appear in your paper or report
- **Stable** — not random session artefacts like timestamps or row
  ordering
- **Interpretable** — so a drift report tells you something meaningful

Avoid certifying objects that are expected to differ across runs by
design, such as [`proc.time()`](https://rdrr.io/r/base/proc.time.html)
outputs or [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) values.

### Tags and the certification store

Every certification requires a `tag` — a human-readable label that
identifies the analysis milestone:

``` r

# Certify at multiple milestones
certify(
  outputs = list(coefs = coef(model)),
  tag     = "pre-peer-review",
  file    = cert_file
)
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'pre-peer-review'

certify(
  outputs = list(coefs = coef(model)),
  tag     = "post-revision",
  file    = cert_file
)
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'post-revision'
```

All certifications for a project accumulate in a single `.reproducr.rds`
file. Tags must be unique within a file — passing a duplicate tag
overwrites the existing record with a warning:

``` r

certify(
  outputs = list(coefs = coef(model)),
  tag     = "baseline-v1",  # already exists
  file    = cert_file
)
#> Warning: Tag 'baseline-v1' already exists in
#> '/tmp/RtmptayJfW/file1aab67e843f1'. Overwriting.
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'baseline-v1'
```

### What gets stored alongside the hashes

Each certification record stores:

| Field            | Description                      |
|------------------|----------------------------------|
| `tag`            | The label you supplied           |
| `timestamp`      | ISO 8601 timestamp               |
| `script`         | Path to the script (if supplied) |
| `r_version`      | R version at certification time  |
| `r_platform`     | Platform string                  |
| `os`             | Operating system                 |
| `hashes`         | Named list of SHA-256 hashes     |
| `output_names`   | Names of certified outputs       |
| `output_classes` | R class of each output           |
| `output_dims`    | Dimensions/length of each output |

This means that even if
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
reports a mismatch, the record tells you what *type* of object changed
and approximately what size it was — which helps diagnose whether it was
a data issue or a model issue.

------------------------------------------------------------------------

## `list_certs()` — inspecting the store

Before running
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md),
you can inspect what certifications are stored:

``` r

list_certs(file = cert_file)
#>               tag                timestamp r_version                      os
#> 1     baseline-v1 2026-05-31T11:51:52+0000     4.6.0 Linux 6.17.0-1015-azure
#> 2 pre-peer-review 2026-05-31T11:51:52+0000     4.6.0 Linux 6.17.0-1015-azure
#> 3   post-revision 2026-05-31T11:51:52+0000     4.6.0 Linux 6.17.0-1015-azure
#>   n_outputs script
#> 1         1   <NA>
#> 2         1   <NA>
#> 3         1   <NA>
```

The result is a plain data frame — one row per certification, in
insertion order. This is useful for:

- Confirming the right tag exists before passing it to
  [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
- Auditing the history of an analysis over time
- Checking that CI has been certifying on each run

------------------------------------------------------------------------

## `check_drift()` — comparing against a baseline

### Basic usage

``` r

# Re-run the same analysis
model2 <- lm(mpg ~ wt + cyl, data = mtcars)

result <- check_drift(
  outputs = list(
    coefs      = coef(model2),
    r_squared  = summary(model2)$r.squared,
    sigma      = sigma(model2),
    n_obs      = nrow(mtcars),
    n_complete = sum(complete.cases(mtcars)),
    group_means = aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
  ),
  against = "baseline-v1",
  file    = cert_file
)
#> 
#> -- reproducr drift check vs 'baseline-v1' --
#> 
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 1
#>   Drifted  : 0
#>   Missing  : 0
#>   New      : 5
```

### The four statuses

Every output in the comparison gets one of four statuses:

``` r

# Demonstrate all four by constructing an artificial scenario
certify(
  outputs = list(
    stays_same  = 42L,
    will_change = coef(lm(mpg ~ wt, data = mtcars)),
    will_vanish = "this output disappears next run"
  ),
  tag  = "four-statuses",
  file = cert_file
)
#> reproducr: certified 3 output(s) [2026-05-31] under tag 'four-statuses'

demo_result <- check_drift(
  outputs = list(
    stays_same  = 42L,
    will_change = coef(lm(mpg ~ hp, data = mtcars)),  # different model
    brand_new   = "this output is new"
    # will_vanish is not supplied
  ),
  against = "four-statuses",
  file    = cert_file
)
#> 
#> -- reproducr drift check vs 'four-statuses' --
#> 
#>   Verdict  : DRIFT DETECTED
#>   OK       : 1
#>   Drifted  : 1
#>   Missing  : 1
#>   New      : 1
#> 
#>   Drifted outputs:
#>     - will_change

print(demo_result)
#> 
#> -- reproducr drift report --
#> 
#> [OK]      stays_same
#> [DRIFT]   will_change
#>             Hash mismatch (numeric tolerance check requires stored values).
#> [NEW]     brand_new
#>             Not present in the baseline certification.
#> [MISSING] will_vanish
#>             Present in baseline but not supplied to check_drift().
```

| Status | Meaning |
|----|----|
| `ok` | Hash matches the baseline exactly |
| `drifted` | Hash differs — output has changed |
| `missing` | Present in baseline, not supplied to [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md) |
| `new` | Supplied to [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md), not in baseline |

`"missing"` and `"new"` are not errors by themselves — you may have
intentionally added or removed outputs between milestones. But they are
worth reviewing, especially `"missing"`, which could indicate an output
was dropped by accident.

### Using `"latest"` to always compare against the most recent certification

``` r

certify(outputs = list(x = 1L), tag = "run-1", file = cert_file)
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'run-1'
certify(outputs = list(x = 1L), tag = "run-2", file = cert_file)
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'run-2'
certify(outputs = list(x = 1L), tag = "run-3", file = cert_file)
#> reproducr: certified 1 output(s) [2026-05-31] under tag 'run-3'

# Compares against "run-3" automatically
check_drift(outputs = list(x = 1L), against = "latest", file = cert_file)
#> reproducr: comparing against latest tag: 'run-3'
#> 
#> -- reproducr drift check vs 'run-3' --
#> 
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 1
#>   Drifted  : 0
#>   Missing  : 0
#>   New      : 0
```

This is the pattern to use in CI: always certify after a successful run,
then on the next run compare against `"latest"`. Any drift between
consecutive runs is caught immediately.

### Working with the drift report

The return value is a `data.frame` with columns `output`, `status`,
`max_delta`, and `note`. Use it programmatically to make CI fail on
drift:

``` r

result <- check_drift(outputs = current_outputs, against = "latest")

n_drifted <- sum(result$status == "drifted")
if (n_drifted > 0L) {
  drifted_names <- result$output[result$status == "drifted"]
  stop(sprintf(
    "%d output(s) have drifted since last certification: %s",
    n_drifted,
    paste(drifted_names, collapse = ", ")
  ))
}
```

------------------------------------------------------------------------

## Recommended workflow across a project lifecycle

### Initial analysis

``` r

# Run analysis
model <- lm(...)
results <- compute_results(...)

# Certify at submission
certify(
  outputs = list(
    primary_coef = coef(model)[2],
    primary_pval = summary(model)$coefficients[2, 4],
    n            = nrow(data),
    effect_size  = compute_d(model)
  ),
  tag    = "submitted-2026-01-15",
  script = "main_analysis.R"
)
```

### After reviewer comments

``` r

# Re-run with minor changes
# ...

check_drift(
  outputs = list(
    primary_coef = coef(model)[2],
    primary_pval = summary(model)$coefficients[2, 4],
    n            = nrow(data),
    effect_size  = compute_d(model)
  ),
  against = "submitted-2026-01-15"
)
# If all "ok" — results are numerically identical to submission
# If "drifted" — investigate before resubmitting
```

### In a CI pipeline (GitHub Actions)

``` yaml
- name: Certify and check drift
  run: |
    Rscript -e "
      source('main_analysis.R')
      library(reproducr)

      # On first run, certify
      if (!file.exists('.reproducr.rds')) {
        certify(outputs = OUTPUTS, tag = 'ci-initial')
      }

      # On every subsequent run, check
      result <- check_drift(outputs = OUTPUTS, against = 'latest')
      certify(outputs = OUTPUTS, tag = paste0('ci-', Sys.Date()))

      if (any(result\$status == 'drifted')) stop('Drift detected!')
    "
```

------------------------------------------------------------------------

## Version control considerations

Commit `.reproducr.rds` to your Git repository. This gives you:

- A permanent, auditable history of what every run produced
- The ability to
  [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
  against any past milestone, not just the most recent one
- A single file reviewers can inspect to verify reproducibility claims

Add `.reproducr.rds` to your `.gitattributes` as a binary file to
prevent noisy diffs:

    .reproducr.rds binary

And add a note to your `.Rbuildignore` so it does not end up in a
package tarball if your analysis is inside a package directory:

    ^\.reproducr\.rds$
