# Generate a reproducibility status badge

Produces a [shields.io](https://shields.io) Markdown badge reflecting
the current reproducibility status of a project. The badge is
colour-coded:

- **Green** (`reproducible`) â€” no risks detected.

- **Yellow** (`caution`) â€” medium-severity risks only.

- **Red** (`at risk`) â€” one or more high-severity risks or drifted
  outputs.

- **Grey** (`unknown`) â€” no risk information supplied.

Can be inserted automatically into a `README.md` (e.g. from a GitHub
Actions workflow).

## Usage

``` r
repro_badge(
  audit,
  risks = NULL,
  drift = NULL,
  output = "markdown",
  readme_path = "README.md"
)
```

## Arguments

- audit:

  An `audit_report` from
  [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md).

- risks:

  A `risk_report` from
  [`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md).
  Optional.

- drift:

  A `drift_report` from
  [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md).
  Optional.

- output:

  `character(1)`. `"markdown"` (return the badge string) or `"README"`
  (insert/update the badge in `README.md`). Default `"markdown"`.

- readme_path:

  `character(1)`. Path to the README file when `output = "README"`.
  Default `"README.md"`.

## Value

Invisibly returns the badge Markdown string.

## Examples

``` r
script <- tempfile(fileext = ".R")
writeLines("x <- dplyr::filter(mtcars, cyl == 4)", script)
report <- audit_script(script, renv = FALSE, verbose = FALSE)
risks  <- risk_score(report)

badge <- repro_badge(report, risks)
#> ![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen) 
cat(badge)
#> ![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)
```
