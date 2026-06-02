# Generate a human-readable reproducibility report

Renders a reproducibility audit report from an
[`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md)
result and optionally a
[`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md)
result and
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
result. Three style presets are available:

- **`"minimal"`** â€” compact summary suitable for console review or
  internal project documentation.

- **`"academic"`** â€” generates a ready-to-paste methods paragraph for
  journal submissions, listing all packages with versions and
  summarising risk findings.

- **`"pharma"`** â€” structured QC document with a risk register and
  sign-off fields, suitable for pharmaceutical or regulated analytical
  workflows.

## Usage

``` r
repro_report(
  audit,
  risks = NULL,
  drift = NULL,
  format = "text",
  style = "minimal",
  output_file = NULL
)
```

## Arguments

- audit:

  An `audit_report` object from
  [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md).
  Required.

- risks:

  A `risk_report` data frame from
  [`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md).
  Optional but strongly recommended â€” without it, the report cannot
  assess reproducibility.

- drift:

  A `drift_report` data frame from
  [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md).
  Optional.

- format:

  `character(1)`. Output format: `"text"` (console), `"md"` (Markdown
  file), or `"html"` (HTML file). Default `"text"`.

- style:

  `character(1)`. Report style: `"minimal"`, `"academic"`, or
  `"pharma"`. Default `"minimal"`.

- output_file:

  `character(1)` or `NULL`. Output file path (used for `format = "md"`
  and `format = "html"`). If `NULL`, a sensible default name is used
  (`"reproducr_report.md"` / `"reproducr_report.html"`).

## Value

Invisibly returns the report content as a character string. For
file-based formats, the file is also written to disk.

## See also

[`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md),
[`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md),
[`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md),
[`repro_badge()`](https://ndohpenngit.github.io/reproducr/reference/repro_badge.md)

## Examples

``` r
script <- tempfile(fileext = ".R")
writeLines(c(
  "set.seed(237)",
  "x <- dplyr::filter(mtcars, cyl == 4)",
  "y <- stats::rnorm(10)"
), script)

report <- audit_script(script, renv = FALSE, verbose = FALSE)
risks  <- risk_score(report)

# Console summary
repro_report(report, risks, format = "text", style = "minimal")
#> reproducr audit report
#> 
#> - Generated: 2026-06-02 10:26
#> - R version: 4.6.0
#> - Platform: Linux 6.17.0-1015-azure
#> - Files scanned: 1
#> - Packages found: 2
#> - Qualified calls: 2
#> - Versions from: installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.

# Academic methods paragraph (printed, not written to file)
cat(repro_report(report, risks, format = "text", style = "academic"))
#> Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0). Reproducibility auditing (reproducr) identified no risks. The full audit report and certification records are available in the supplementary materials.
#> # Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1015-azure. The following packages were used: dplyr, stats (v4.6.0). Reproducibility auditing (reproducr) identified no risks. The full audit report and certification records are available in the supplementary materials.
```
