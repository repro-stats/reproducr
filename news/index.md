# Changelog

## reproducr 0.2.1

#### Bug fixes

- [`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
  now stores raw output values alongside hashes in the certification
  record (new `values` field in `.reproducr.rds`). Previously only
  SHA-256 hashes were stored, making element-wise numeric comparison
  impossible downstream.

- [`check_drift()`](https://repro-stats.github.io/reproducr/reference/check_drift.md)
  tolerance comparison is now fully implemented. Previously `tolerance`
  was a no-op — the function detected numeric outputs but immediately
  fell back to a hash-mismatch message for all of them. It now computes
  `max(abs(current - stored))` element-wise and resolves to `"ok"` when
  `delta <= tolerance`, `"drifted"` with the observed delta when not,
  and handles length mismatches, non-finite deltas, and old
  certification format (pre-0.2.1 `.reproducr.rds`) gracefully. Fixes
  false-positive drift reports on cross-platform runs (e.g. macOS local
  vs Linux CI).

- `.md_to_html()` fallback (used when `commonmark` is not installed) now
  correctly converts Markdown headings, list items, and blockquotes in
  multiline strings. The line-anchored
  [`gsub()`](https://rdrr.io/r/base/grep.html) patterns were missing the
  `(?m)` multiline flag. Also fixes a typo in the `<h2>` replacement
  string (`\\2` → `\\1`).

- [`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
  stale ceiling and stale floor detail messages now respect
  `verbose = FALSE`. Previously these were printed unconditionally
  regardless of the `verbose` argument.

- CI audit workflows now commit `reproducibility_report.md` alongside
  `README.md` and `.reproducr.rds`, and use timestamp-based tags
  (`ci-{date}-{hhmmss}`) to prevent same-day collisions.

#### New features

- [`print.staleness_report()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
  gains a `details` argument (default `TRUE`). Set `details = FALSE` to
  print only the summary counts without the per-entry breakdown, useful
  when reviewing results interactively after already having read the
  entries.

#### Internal

- Test coverage increased from 89% to 97%.
- `withr` added to `Suggests` to formally declare the test dependency.

#### Migration note

Delete `.reproducr.rds` and re-run
[`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
once to populate the new `values` field. Until then
[`check_drift()`](https://repro-stats.github.io/reproducr/reference/check_drift.md)
degrades gracefully with an informative message.

## reproducr 0.2.0

- [`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
  gains a `major_version_grace` parameter (default `1L`) – when the
  installed version is one or more major versions ahead of an entry’s
  `from_version`, the entry is suppressed entirely. This prevents
  historically wide version windows (e.g. a major package rewrite from
  several years ago) from generating false-positive flags for users who
  are already well past the breaking-change transition.

- [`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
  gains a `from_version_major_threshold` parameter (default `1L`) –
  flags database entries where the current CRAN release is one or more
  major versions ahead of `from_version`, indicating the window floor
  may be too wide and the entry may need its `from_version` raised or
  the entry closed. New status values: `"stale_ceiling"` (the previous
  `"stale"` status, renamed for clarity) and `"stale_floor"`.

## reproducr 0.1.5

- Fixed remaining relative URI in `README.md` – `CODE_OF_CONDUCT.md`
  link now uses the full absolute GitHub URL. Resolves CRAN pre-check
  NOTE: “Found the following (possibly) invalid file URI”.

- Updated `MatchIt::matchit` database entry: narrowed `from_version`
  from `3.0.2` to `4.6.99` to reflect that the 3.x -\> 4.x rewrite is
  long complete and active users are on 4.x.

## reproducr 0.1.4

- Fixed invalid relative URIs in `README.md` – `CODE_OF_CONDUCT.md` and
  `CONTRIBUTING.md` links now use absolute GitHub URLs. Resolves CRAN
  pre-check NOTE: “Found the following (possibly) invalid file URI”.

## reproducr 0.1.3

- Added `CONTRIBUTING.md` with guidelines for contributing to the
  package and to the breaking-changes database (`reproducr-db`).

- Added `CODE_OF_CONDUCT.md` (Contributor Covenant).

- Added `LICENSE` and `LICENSE.md` files for the MIT licence.

- Fixed bug in `.resolve_current_versions()` where packages appearing in
  multiple library paths caused a “more elements supplied than there are
  to replace” error. Now takes only the first match.

- Improved test coverage from 82% to 86%. Added
  `tests/testthat/test-utils.R` covering `.parse_renv_lock()`,
  `.hash_object()`, `.renv_lock_exists()`, `.get_os()`, `.pad()`, and
  `.version_in_window()`.

- `CONTRIBUTING.md`, `LICENSE.md`, `CODE_OF_CONDUCT.md`, and
  `codecov.yml` added to `.Rbuildignore` – present in the GitHub
  repository but excluded from the CRAN tarball.

- Added Codecov integration – coverage badge now shown in README.

- Added GitHub issue templates (bug report, feature request, database
  entry suggestion) and PR template.

## reproducr 0.1.2

### Breaking-changes database

- [`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
  now skips entries marked `closed = TRUE` – these are intentionally
  closed version windows (e.g. historical base R changes) that should
  not be flagged as stale. Five base R entries (`stats::sample`,
  [`stats::rnorm`](https://rdrr.io/r/stats/Normal.html),
  [`stats::runif`](https://rdrr.io/r/stats/Uniform.html),
  [`stats::rbinom`](https://rdrr.io/r/stats/Binomial.html),
  [`stats::hclust`](https://rdrr.io/r/stats/hclust.html)) are now marked
  closed in `reproducr-db`.

- Updated 19 stale `to_version` ceilings in `reproducr-db` to cover
  current CRAN releases (`dplyr`, `ggplot2`, `tidyr`, `purrr`, `readr`,
  `stringr`, `data.table`, `lme4`, `broom`, `caret`).

- Added `caret::train` as a new database entry (version window `6.0.99`
  to `7.0.9`).

- Added `closed` and `closed_reason` fields to the `reproducr-db` JSON
  schema.

### Reports and badges

- [`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
  HTML output now uses `commonmark` for proper Markdown rendering –
  tables, headers, and code blocks render correctly in all browsers.
  Falls back gracefully with a message if `commonmark` is not installed.
  Added `commonmark` to `Suggests`.

- Risk register in the `"pharma"` report style is now a compact summary
  table rather than individual cards – more readable in regulated
  workflows.

- [`repro_badge()`](https://repro-stats.github.io/reproducr/reference/repro_badge.md)
  moved to its own file (`R/repro_badge.R`).

### Bug fixes

- Fixed non-ASCII characters (em dashes) across all R source files –
  `certify.R`, `utils.R`, `check_db_staleness.R`, `reproducr-package.R`,
  `audit_script.R`, `risk_score.R`, `repro_report.R`. Resolves
  `R CMD check` WARNING on Windows.

### Infrastructure

- Migrated all repositories to the
  [`repro-stats`](https://github.com/repro-stats) GitHub organisation.

- Added `reproducr-cmc` to the gallery – a CMC statistical package
  covering dissolution f2 (ICH Q1B), stability shelf-life (ICH Q1E), and
  assay method validation (ICH Q2(R1)). Pharma-style QC report, `renv`
  locked, 20 certified outputs.

## reproducr 0.1.1

- Fixed `audit_script(renv = TRUE)` incorrectly falling back to the
  installed library when a valid `renv.lock` was present. The regex
  parser was matching the R version field in the lockfile header,
  causing a length mismatch. Now uses `jsonlite` when available for
  robust JSON parsing, with a corrected regex fallback.

- Fixed
  [`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
  to skip prose lines in `.Rmd` and `.qmd` files – only lines inside
  fenced ```` ```{r} ```` code blocks are now parsed. Previously, inline
  backtick references like `` `stats::sample()` `` in prose were
  incorrectly detected as qualified calls, producing false positives
  when auditing vignettes.

- Added
  [`check_db_staleness()`](https://repro-stats.github.io/reproducr/reference/check_db_staleness.md)
  – compares `to_version` ceilings in the breaking-changes database
  against current CRAN releases. Returns a tidy `staleness_report` data
  frame with `"ok"`, `"stale"`, or `"unknown"` status per entry. A
  weekly GitHub Actions workflow opens an issue in `reproducr-db`
  automatically when stale entries are detected.

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
  [`vignette("contributing-to-the-database")`](https://repro-stats.github.io/reproducr/articles/contributing-to-the-database.md)
  with three rules for setting `to_version` and a quick-reference table.

- Launched [`reproducr-db`](https://github.com/repro-stats/reproducr-db)
  – a companion repository for community-contributed breaking-change
  entries. All 29 existing entries are available as JSON files with a
  validation CI workflow on every PR.

- Added `jsonlite` to `Suggests` to support robust `renv.lock` parsing.

- Added spelling wordlist (`inst/WORDLIST`) – no spelling errors.

## reproducr 0.1.0

- [`audit_script()`](https://repro-stats.github.io/reproducr/reference/audit_script.md)
  – parse `.R`, `.Rmd`, and `.qmd` files to extract all qualified
  `pkg::fn` calls with version resolution from `renv.lock` or the
  installed library.

- [`risk_score()`](https://repro-stats.github.io/reproducr/reference/risk_score.md)
  – three independent risk checks: `"changelog"` (curated database of
  known breaking changes), `"seed_check"` (flags stochastic functions
  without a nearby [`set.seed()`](https://rdrr.io/r/base/Random.html)),
  and `"locale_check"` (flags locale-sensitive operations).

- [`certify()`](https://repro-stats.github.io/reproducr/reference/certify.md)
  – hash and store analytical outputs as a signed baseline.

- [`check_drift()`](https://repro-stats.github.io/reproducr/reference/check_drift.md)
  – compare current outputs against a stored baseline; reports `"ok"`,
  `"drifted"`, `"missing"`, and `"new"` statuses.

- [`list_certs()`](https://repro-stats.github.io/reproducr/reference/list_certs.md)
  – inspect all certifications stored in a project’s `.reproducr.rds`
  file.

- [`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
  – render audit reports in three styles (`"minimal"`, `"academic"`,
  `"pharma"`) and three formats (`"text"`, `"md"`, `"html"`).

- [`repro_badge()`](https://repro-stats.github.io/reproducr/reference/repro_badge.md)
  – generate a shields.io reproducibility status badge and optionally
  insert it into `README.md`.

- Initial breaking-changes database covering `dplyr`, `tidyr`,
  `ggplot2`, `readr`, `purrr`, `stringr`, `lubridate`, `broom`,
  `data.table`, `lme4`, and base R (R 3.6.0 RNG changes, R 4.0.0
  [`hclust()`](https://rdrr.io/r/stats/hclust.html) tie-breaking).
