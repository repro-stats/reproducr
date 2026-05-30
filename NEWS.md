# reproducr (development version)

# reproducr 0.1.0

## New features

* `audit_script()` — parse `.R`, `.Rmd`, and `.qmd` files to extract all
  qualified `pkg::fn` calls with version resolution from `renv.lock` or the
  installed library.

* `risk_score()` — three independent risk checks:
  - `"changelog"`: curated database of 26 known breaking changes across 11
    popular packages and base R.
  - `"seed_check"`: flags stochastic functions without a nearby `set.seed()`.
  - `"locale_check"`: flags locale-sensitive operations.

* `certify()` — hash and store analytical outputs as a signed baseline.

* `check_drift()` — compare current outputs against a stored baseline;
  reports `"ok"`, `"drifted"`, `"missing"`, and `"new"` statuses.

* `list_certs()` — inspect all certifications stored in a project's
  `.reproducr.rds` file.

* `repro_report()` — render audit reports in three styles (`"minimal"`,
  `"academic"`, `"pharma"`) and three formats (`"text"`, `"md"`, `"html"`).

* `repro_badge()` — generate a shields.io reproducibility status badge and
  optionally insert it into `README.md`.

## Breaking changes database

Initial coverage: `dplyr`, `tidyr`, `ggplot2`, `readr`, `purrr`, `stringr`,
`lubridate`, `broom`, `data.table`, `lme4`, and base R (R 3.6.0 RNG changes,
R 4.0.0 `hclust()` tie-breaking).
