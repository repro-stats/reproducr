# Changelog

## reproducr 0.1.1

## reproducr 0.1.0.9002

- Fixed `audit_script(renv = TRUE)` incorrectly falling back to the
  installed library when a valid `renv.lock` was present. The regex
  parser was matching the R version field in the lockfile header,
  causing a length mismatch. Now uses `jsonlite` when available for
  robust JSON parsing, with a corrected regex fallback.

------------------------------------------------------------------------

## reproducr 0.1.0.9001

- Fixed
  [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md)
  to skip prose lines in `.Rmd` and `.qmd` files — only lines inside
  fenced ```` ```{r} ```` code blocks are now parsed. Previously, inline
  backtick references like `` `stats::sample()` `` in prose were
  incorrectly detected as qualified calls, producing false positives
  when auditing vignettes.

- Added explanatory text to the “See it in action” gallery section in
  `README.md`.

- Simplified the `reproducr` package audit workflow to use a placeholder
  script — the package source has no analysis code to audit, and
  vignettes intentionally demonstrate risky patterns as examples.

------------------------------------------------------------------------

## reproducr 0.1.0.9000

- [`check_db_staleness()`](https://ndohpenngit.github.io/reproducr/reference/check_db_staleness.md)
  — compares `to_version` ceilings in the breaking-changes database
  against current CRAN releases. Returns a tidy `staleness_report` data
  frame with `"ok"`, `"stale"`, or `"unknown"` status per entry. A
  weekly GitHub Actions workflow runs this automatically and opens a
  GitHub issue when stale entries are detected
  (`.github/workflows/db-staleness.yml`).

- Narrowed version windows for base R RNG entries
  ([`stats::rnorm`](https://rdrr.io/r/stats/Normal.html),
  [`stats::rbinom`](https://rdrr.io/r/stats/Binomial.html),
  [`stats::runif`](https://rdrr.io/r/stats/Uniform.html),
  `stats::sample`) from `to_version = "4.9.9"` to `"3.6.9"`. Users on
  modern R (\>= 4.x) were being falsely flagged for a 2019 change they
  are all on the same side of.

- Narrowed version window for
  [`stats::hclust`](https://rdrr.io/r/stats/hclust.html) from `"4.9.9"`
  to `"4.0.9"` for the same reason.

- Added version window design principles to `R/breaking_changes_db.R`
  and expanded
  [`vignette("contributing-to-the-database")`](https://ndohpenngit.github.io/reproducr/articles/contributing-to-the-database.md)
  with three rules for setting `to_version` and a quick-reference table.

------------------------------------------------------------------------

## reproducr 0.1.0

- [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md)
  — parse `.R`, `.Rmd`, and `.qmd` files to extract all qualified
  `pkg::fn` calls with version resolution from `renv.lock` or the
  installed library.

- [`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md)
  — three independent risk checks: `"changelog"` (curated database of
  known breaking changes), `"seed_check"` (flags stochastic functions
  without a nearby [`set.seed()`](https://rdrr.io/r/base/Random.html)),
  and `"locale_check"` (flags locale-sensitive operations).

- [`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md)
  — hash and store analytical outputs as a signed baseline.

- [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md)
  — compare current outputs against a stored baseline; reports `"ok"`,
  `"drifted"`, `"missing"`, and `"new"` statuses.

- [`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md)
  — inspect all certifications stored in a project’s `.reproducr.rds`
  file.

- [`repro_report()`](https://ndohpenngit.github.io/reproducr/reference/repro_report.md)
  — render audit reports in three styles (`"minimal"`, `"academic"`,
  `"pharma"`) and three formats (`"text"`, `"md"`, `"html"`).

- [`repro_badge()`](https://ndohpenngit.github.io/reproducr/reference/repro_badge.md)
  — generate a shields.io reproducibility status badge and optionally
  insert it into `README.md`.

- Initial breaking-changes database covering `dplyr`, `tidyr`,
  `ggplot2`, `readr`, `purrr`, `stringr`, `lubridate`, `broom`,
  `data.table`, `lme4`, and base R (R 3.6.0 RNG changes, R 4.0.0
  [`hclust()`](https://rdrr.io/r/stats/hclust.html) tie-breaking).
