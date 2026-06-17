# Check analytical outputs for drift against a certified baseline

Re-hashes a set of named R objects and compares them against a
previously stored certification. Reports which outputs are unchanged
(`"ok"`), have changed (`"drifted"`), are present in the baseline but
not supplied (`"missing"`), or are new outputs not in the baseline
(`"new"`).

For numeric outputs whose hashes differ, `check_drift()` falls back to
an element-wise absolute difference comparison using `tolerance`. This
makes drift detection robust to benign floating-point variation across
platforms (e.g. Linux CI vs macOS local), while still catching genuine
numerical changes. The fallback requires that the certification was
created with
[`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
version \>= 0.2.0, which stores raw values alongside hashes.

## Usage

``` r
check_drift(
  outputs,
  against = "latest",
  file = ".reproducr",
  tolerance = 1e-10
)
```

## Arguments

- outputs:

  A fully named list of current R objects – the same names used in the
  [`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
  call being compared against.

- against:

  `character(1)`. The certification tag to compare against. Use
  `"latest"` (the default) to automatically select the most recently
  added certification.

- file:

  `character(1)`. Base path of the certification store. Default
  `".reproducr"` (reads `.reproducr.rds`).

- tolerance:

  `numeric(1)`. Numeric tolerance for element-wise comparison of numeric
  outputs whose hashes differ. Outputs whose maximum absolute difference
  is within `tolerance` are reported as `"ok"`. Set to `0` for exact
  hash matching only. Default `1e-10`.

## Value

Invisibly returns a `data.frame` of class
`c("drift_report", "data.frame")` with columns `output`, `status`
(`"ok"`, `"drifted"`, `"missing"`, `"new"`), `max_delta`, and `note`.
Also emits a summary via
[`message()`](https://rdrr.io/r/base/message.html).

## See also

[`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
to create a baseline;
[`list_certs()`](https://repro-stats.github.io/reproducr/reference/list_certs.md)
to see available tags.

## Examples

``` r
cert_file <- tempfile()
model <- lm(mpg ~ wt, data = mtcars)

certify(list(coefs = coef(model)), tag = "v1", file = cert_file)
#> reproducr: certified 1 output(s) [2026-06-17] under tag 'v1'

# Same outputs -- should report "ok"
result <- check_drift(list(coefs = coef(model)),
  against = "v1", file = cert_file
)
#> -- reproducr drift check vs 'v1' --
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 1
#>   Drifted  : 0
#>   Missing  : 0
#>   New      : 0
print(result)
#> 
#> -- reproducr drift report --
#> 
#> [OK]      coefs
#> 

# Different model -- should report "drifted"
model2 <- lm(mpg ~ hp, data = mtcars)
check_drift(list(coefs = coef(model2)),
  against = "v1", file = cert_file
)
#> -- reproducr drift check vs 'v1' --
#>   Verdict  : DRIFT DETECTED
#>   OK       : 0
#>   Drifted  : 1
#>   Missing  : 0
#>   New      : 0
#>   Drifted outputs:
#>     - coefs
```
