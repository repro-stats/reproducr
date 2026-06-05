# reproducr 0.1.1.9002

* `repro_report()` HTML output now uses `commonmark` for proper Markdown
  rendering — tables, headers, and code blocks render correctly in all
  browsers. Falls back gracefully with a message if `commonmark` is not
  installed. Added `commonmark` to `Suggests`.

* `repro_badge()` moved to its own file (`R/repro_badge.R`) -- previously
  it was defined in `R/repro_report.R`.

* Risk register in the `"pharma"` report style is now a compact summary
  table rather than individual cards -- more readable in regulated workflows.

* Fixed non-ASCII characters (em dashes) across all R source files --
  `certify.R`, `utils.R`, `check_db_staleness.R`, `reproducr-package.R`,
  `audit_script.R`, `risk_score.R`, `repro_report.R`. Resolves
  `R CMD check` WARNING on Windows and win-builder.

# reproducr 0.1.1.9001

* Added `reproducr-cmc` to the gallery — CMC statistical package covering
  dissolution f2, ICH Q1E stability shelf-life, and ICH Q2(R1) assay method
  validation. Pharma-style QC report, `renv` locked, 20 certified outputs.

* `check_db_staleness()` now skips entries marked `closed = TRUE` in the
  database. These are intentionally closed version windows (e.g. historical
  base R changes) that should not be flagged as stale. Five base R entries
  (`stats::sample`, `stats::rnorm`, `stats::runif`, `stats::rbinom`,
  `stats::hclust`) are now marked closed in `reproducr-db`.

* Updated 19 stale `to_version` ceilings in `reproducr-db` to cover current
  CRAN releases (`dplyr`, `ggplot2`, `tidyr`, `purrr`, `readr`, `stringr`,
  `data.table`, `lme4`, `broom`, `caret`).

* Added `caret::train` as a new database entry (version window `6.0.99` to
  `7.0.9`).

* Added `closed` and `closed_reason` fields to the `reproducr-db` JSON schema.

* Migrated all repositories to the
  [`repro-stats`](https://github.com/repro-stats) GitHub organisation.

# reproducr 0.1.1

* Fixed `audit_script(renv = TRUE)` incorrectly falling back to the installed
  library when a valid `renv.lock` was present. The regex parser was matching
  the R version field in the lockfile header, causing a length mismatch.
  Now uses `jsonlite` when available for robust JSON parsing, with a corrected
  regex fallback.

* Fixed `audit_script()` to skip prose lines in `.Rmd` and `.qmd` files —
  only lines inside fenced ` ```{r} ` code blocks are now parsed. Previously,
  inline backtick references like `` `stats::sample()` `` in prose were
  incorrectly detected as qualified calls, producing false positives when
  auditing vignettes.

* Added `check_db_staleness()` — compares `to_version` ceilings in the
  breaking-changes database against current CRAN releases. Returns a tidy
  `staleness_report` data frame with `"ok"`, `"stale"`, or `"unknown"`
  status per entry. A weekly GitHub Actions workflow opens an issue in
  `reproducr-db` automatically when stale entries are detected.

* Narrowed version windows for base R RNG entries (`stats::rnorm`,
  `stats::rbinom`, `stats::runif`, `stats::sample`) from `to_version = "4.9.9"`
  to `"3.6.9"`. Users on modern R (>= 4.x) were being falsely flagged for
  a 2019 change they are all on the same side of.

* Narrowed version window for `stats::hclust` from `"4.9.9"` to `"4.0.9"`
  for the same reason.

* Added version window design principles to `R/breaking_changes_db.R` and
  expanded `vignette("contributing-to-the-database")` with three rules for
  setting `to_version` and a quick-reference table.

* Launched [`reproducr-db`](https://github.com/repro-stats/reproducr-db) —
  a companion repository for community-contributed breaking-change entries.
  All 29 existing entries are available as JSON files with a validation CI
  workflow on every PR.

* Added `jsonlite` to `Suggests` to support robust `renv.lock` parsing.

* Added spelling wordlist (`inst/WORDLIST`) — no spelling errors.

# reproducr 0.1.0

* `audit_script()` — parse `.R`, `.Rmd`, and `.qmd` files to extract all
  qualified `pkg::fn` calls with version resolution from `renv.lock` or the
  installed library.

* `risk_score()` — three independent risk checks: `"changelog"` (curated
  database of known breaking changes), `"seed_check"` (flags stochastic
  functions without a nearby `set.seed()`), and `"locale_check"` (flags
  locale-sensitive operations).

* `certify()` — hash and store analytical outputs as a signed baseline.

* `check_drift()` — compare current outputs against a stored baseline;
  reports `"ok"`, `"drifted"`, `"missing"`, and `"new"` statuses.

* `list_certs()` — inspect all certifications stored in a project's
  `.reproducr.rds` file.

* `repro_report()` — render audit reports in three styles (`"minimal"`,
  `"academic"`, `"pharma"`) and three formats (`"text"`, `"md"`, `"html"`).

* `repro_badge()` — generate a shields.io reproducibility status badge and
  optionally insert it into `README.md`.

* Initial breaking-changes database covering `dplyr`, `tidyr`, `ggplot2`,
  `readr`, `purrr`, `stringr`, `lubridate`, `broom`, `data.table`, `lme4`,
  and base R (R 3.6.0 RNG changes, R 4.0.0 `hclust()` tie-breaking).