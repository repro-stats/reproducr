# Certifying outputs and detecting drift

This vignette covers Tier 2 of the `reproducr` workflow in depth:
[`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md),
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md),
and
[`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md).
These three functions together form the *baseline and drift detection*
system.

## The problem they solve

Packages change hands. Maintainers push silent fixes. Platform-level
libraries (BLAS, LAPACK) get updated by system administrators. R itself
changes RNG defaults between minor versions. Any of these can alter your
numerical results without producing an error.

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
    coefs       = coef(model),
    r_squared   = summary(model)$r.squared,
    sigma       = sigma(model),
    n_obs       = nrow(mtcars),
    n_complete  = sum(complete.cases(mtcars)),
    group_means = aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
  ),
  tag    = "baseline-v1",
  script = "analysis.R",
  file   = cert_file
)
#> reproducr: certified 6 output(s) [2026-06-02] under tag 'baseline-v1'
```

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

Every certification requires a `tag` — a human-readable label:

``` r

certify(
  outputs = list(coefs = coef(model)),
  tag     = "pre-peer-review",
  file    = cert_file
)
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'pre-peer-review'

certify(
  outputs = list(coefs = coef(model)),
  tag     = "post-revision",
  file    = cert_file
)
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'post-revision'
```

Passing a duplicate tag overwrites the existing record with a warning:

``` r

certify(
  outputs = list(coefs = coef(model)),
  tag     = "baseline-v1",
  file    = cert_file
)
#> Warning: Tag 'baseline-v1' already exists in
#> '/tmp/RtmpA4VxW8/file1b8e27b3a137'. Overwriting.
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'baseline-v1'
```

------------------------------------------------------------------------

## `list_certs()` — inspecting the store

``` r

list_certs(file = cert_file)
#>               tag                timestamp r_version                      os
#> 1     baseline-v1 2026-06-02T18:52:11+0000     4.6.0 Linux 6.17.0-1015-azure
#> 2 pre-peer-review 2026-06-02T18:52:11+0000     4.6.0 Linux 6.17.0-1015-azure
#> 3   post-revision 2026-06-02T18:52:11+0000     4.6.0 Linux 6.17.0-1015-azure
#>   n_outputs script
#> 1         1   <NA>
#> 2         1   <NA>
#> 3         1   <NA>
```

------------------------------------------------------------------------

## `check_drift()` — comparing against a baseline

### Basic usage

``` r

model2 <- lm(mpg ~ wt + cyl, data = mtcars)

result <- check_drift(
  outputs = list(
    coefs       = coef(model2),
    r_squared   = summary(model2)$r.squared,
    sigma       = sigma(model2),
    n_obs       = nrow(mtcars),
    n_complete  = sum(complete.cases(mtcars)),
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

``` r

certify(
  outputs = list(
    stays_same  = 42L,
    will_change = coef(lm(mpg ~ wt, data = mtcars)),
    will_vanish = "this output disappears next run"
  ),
  tag  = "four-statuses",
  file = cert_file
)
#> reproducr: certified 3 output(s) [2026-06-02] under tag 'four-statuses'

demo_result <- check_drift(
  outputs = list(
    stays_same  = 42L,
    will_change = coef(lm(mpg ~ hp, data = mtcars)),
    brand_new   = "this output is new"
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

### Using `"latest"`

``` r

certify(outputs = list(x = 1L), tag = "run-1", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'run-1'
certify(outputs = list(x = 1L), tag = "run-2", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'run-2'
certify(outputs = list(x = 1L), tag = "run-3", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-02] under tag 'run-3'

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

### Using drift results programmatically

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

## Recommended workflow

### At submission

``` r

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

check_drift(
  outputs = list(
    primary_coef = coef(model)[2],
    primary_pval = summary(model)$coefficients[2, 4],
    n            = nrow(data),
    effect_size  = compute_d(model)
  ),
  against = "submitted-2026-01-15"
)
```

------------------------------------------------------------------------

## Version control

Commit `.reproducr.rds` to your Git repository. This gives you a
permanent, auditable history of what every run produced, and lets you
compare against any past milestone.

Add to `.gitattributes` to prevent noisy diffs:

    .reproducr.rds binary
