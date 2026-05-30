# reproducr <img src="man/figures/logo.svg" align="right" height="120" alt="" />

<!-- reproducr-badge -->![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)<!-- /reproducr-badge -->
![CRAN status](https://img.shields.io/badge/CRAN-not%20yet-lightgrey)
![R version](https://img.shields.io/badge/R-%3E%3D%204.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Tests](https://img.shields.io/badge/tests-63%20passing-brightgreen)

> **Computational reproducibility auditing for R — the layer `renv` doesn't cover.**

---

## The problem

You have an analysis. You have `renv`. Your packages are locked. Are you done?

Not quite. `renv` answers one question: *"Can I reinstall these packages?"*
It cannot tell you:

- Whether a function's **behaviour changed silently** between versions (e.g. `dplyr::summarise()` changed its grouping defaults in v1.1.0)
- Whether your **stochastic code** is missing a `set.seed()` and will produce different results every run
- Whether your results have **numerically drifted** since your last analysis
- Whether your code is **locale-sensitive** and will behave differently on a server in a different country

`reproducr` answers those questions. Use it *alongside* `renv`, not instead of it.

---

## Installation

```r
# Development version from GitHub
# install.packages("remotes")
remotes::install_github("ndohpenngit/reproducr")
```

---

## Quick start

```r
library(reproducr)

# Step 1: Audit your script
report <- audit_script("analysis.R")
print(report)
#>
#> -- reproducr audit report [2026-05-30 14:32] --
#>
#>   Files scanned:    1
#>   Packages found:   4
#>   Calls detected:   23
#>   R version:        4.3.3
#>   Platform:         Linux 6.18.5
#>   Versions from:    renv.lock
#>
#>   Next step: risks <- risk_score(report)

# Step 2: Score for risk
risks <- risk_score(report)
print(risks)
#>
#> -- reproducr risk score --
#>
#>   HIGH:      1
#>   MEDIUM:    2
#>   LOW:       1
#>
#> [HIGH]   dplyr::summarise (line 14 in analysis.R)
#>          Check    : changelog
#>          Details  : In dplyr 1.1.0, summarise() changed its default
#>                     grouping behaviour ...
#>          Reference: https://dplyr.tidyverse.org/news/index.html#dplyr-110

# Step 3: Certify your outputs as a baseline
model <- lm(mpg ~ wt, data = mtcars)

certify(
  outputs = list(
    coefs     = coef(model),
    r_squared = summary(model)$r.squared,
    n_obs     = nrow(mtcars)
  ),
  tag    = "submission-v1",
  script = "analysis.R"
)
#> reproducr: certified 3 output(s) [2026-05-30] under tag 'submission-v1'

# Step 4: After a package upgrade, check for drift
check_drift(
  outputs = list(
    coefs     = coef(model),
    r_squared = summary(model)$r.squared,
    n_obs     = nrow(mtcars)
  ),
  against = "submission-v1"
)
#>
#> -- reproducr drift check vs 'submission-v1' --
#>
#>   Verdict  : ALL OUTPUTS MATCH
#>   OK       : 3
#>   Drifted  : 0

# Step 5: Generate a report
repro_report(report, risks, format = "html", style = "pharma",
             output_file = "qc_report.html")

# Step 6: Badge your README
repro_badge(report, risks, output = "README")
```

---

## Core functions

| Function | Tier | Purpose |
|---|---|---|
| `audit_script()` | 1 | Parse a script and extract all `pkg::fn` calls with version info |
| `risk_score()` | 1 | Check calls against the breaking-changes database |
| `certify()` | 2 | Hash and store analytical outputs as a signed baseline |
| `check_drift()` | 2 | Compare current outputs against a stored baseline |
| `list_certs()` | 2 | Inspect all certifications in a project |
| `repro_report()` | 3 | Render audit report (text / Markdown / HTML) |
| `repro_badge()` | 3 | Generate a shields.io reproducibility badge |

### The three-tier workflow

```
Tier 1 — Scan & score          Tier 2 — Baseline & drift       Tier 3 — Report & export
─────────────────────          ─────────────────────────       ─────────────────────────
audit_script()                 certify()                       repro_report()
     │                              │                               │
     ▼                              ▼                               ▼
risk_score()               check_drift()                    repro_badge()
```

You can use just Tier 1 for a quick scan, or build up to the full pipeline for
regulated or peer-reviewed work.

---

## The breaking-changes database

The heart of `risk_score()` is a curated database of known cases where a
package update **silently changed function behaviour** — not errors, not
deprecation warnings, just different results.

Current coverage:

| Package | Entries | Examples |
|---|---|---|
| `dplyr` | 4 | `summarise()` grouping change (v1.1.0), `across()` naming (v1.1.0) |
| `tidyr` | 3 | `nest()` interface rewrite (v1.0.0), `pivot_wider()` duplicate handling (v1.2.0) |
| `ggplot2` | 3 | Default colour scale change (v3.4.0), `aes()` scoping (v3.5.0) |
| `readr` | 2 | vroom backend switch, column type guessing (v2.0.0) |
| `purrr` | 2 | Error handling change (v1.0.0), `map_df()` deprecation |
| `stringr` | 1 | `str_c()` NA propagation (v1.5.0) |
| `lubridate` | 2 | DST arithmetic (v1.9.0) |
| `broom` | 1 | Column renaming (v0.8.0) |
| `data.table` | 2 | `fread()` type detection, `melt()` factor→character |
| `lme4` | 1 | Optimizer tolerance change |
| `base R` | 5 | RNG change (R 3.6.0), `hclust()` tie-breaking (R 4.0.0) |

**Contributing:** The database is designed for community contribution. Each
entry is a plain R list — see `R/breaking_changes_db.R` and open a pull
request to add new entries.

---

## Risk checks

### `"changelog"` — Breaking changes database

Checks every detected `pkg::fn` call against the built-in database. A call is
flagged only if the installed (or `renv`-locked) version falls within a known
risky version window `(from_ver, to_ver]`.

Risk levels:
- **HIGH** — output values can change silently with no error
- **MEDIUM** — argument renamed/deprecated; may error or produce different output
- **LOW** — minor behavioural note; output unlikely to differ in practice

### `"seed_check"` — Missing set.seed()

Flags any call to a stochastic function (`rnorm`, `sample`, `rbinom`, etc.)
where no `set.seed()` is found within the 50 lines above the call. Rated
**MEDIUM** risk — results will differ across runs.

```r
# This will be flagged:
x <- stats::rnorm(100)

# This will not:
set.seed(42)
x <- stats::rnorm(100)
```

### `"locale_check"` — Locale-sensitive operations

Flags functions whose output depends on the system locale (`sort()`, `format()`,
`strftime()`, etc.). Rated **LOW** risk — relevant when code will run on
servers in different countries or with different OS locale settings.

---

## Certification and drift detection

```r
# After your analysis completes, certify the key outputs:
certify(
  outputs = list(
    model_coefs  = coef(my_model),
    final_n      = nrow(results),
    primary_pval = tidy(my_model)$p.value[2]
  ),
  tag    = "pre-review",
  script = "main_analysis.R"
)

# Three months later, after a dplyr upgrade:
check_drift(
  outputs = list(
    model_coefs  = coef(my_model),
    final_n      = nrow(results),
    primary_pval = tidy(my_model)$p.value[2]
  ),
  against = "pre-review"
)
```

Certifications accumulate in a `.reproducr.rds` file in your project root.
**Commit this file to version control** — it is your audit trail.

---

## Report styles

### `"minimal"` (default)
A compact Markdown/HTML summary covering environment, verdict, and risk table.
Good for internal project documentation.

### `"academic"`
Generates a ready-to-paste methods paragraph for journal submissions:

> *All analyses were conducted in R (version 4.3.3) on Linux 6.18.5.
> The following packages were used: dplyr (v1.1.4), ggplot2 (v3.5.1) ...
> Reproducibility auditing (reproducr) identified no risks. The full audit
> report and certification records are available in the supplementary materials.*

### `"pharma"`
A structured QC document with:
- Execution environment table
- Full package inventory with versions
- Risk register (one entry per flagged call)
- Drift assessment table
- Sign-off fields for analyst and reviewer

```r
repro_report(report, risks, drift,
             format = "html", style = "pharma",
             output_file = "qc_report.html")
```

---

## CI/CD integration

Add `reproducr` to your GitHub Actions workflow to automatically audit on
every push and update the badge in your README:

```yaml
# .github/workflows/reproducr.yml
name: Reproducibility audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - name: Install reproducr
        run: Rscript -e "remotes::install_github('ndohpenngit/reproducr')"

      - name: Run audit
        run: |
          Rscript -e "
            library(reproducr)
            report <- audit_script('.', verbose = FALSE)
            risks  <- risk_score(report)
            repro_badge(report, risks, output = 'README')
            repro_report(report, risks, format = 'md',
                         output_file = 'reproducibility_report.md')
            if (any(risks\$risk == 'high')) stop('High-severity risks detected.')
          "

      - name: Commit updated badge
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add README.md reproducibility_report.md
          git diff --staged --quiet || git commit -m "chore: update reproducibility badge"
          git push
```

---

## Relationship to renv

| | `renv` | `reproducr` |
|---|---|---|
| Freezes package versions | ✓ | — |
| Restores environments | ✓ | — |
| Detects silent behavioural changes | — | ✓ |
| Flags missing set.seed() | — | ✓ |
| Detects numerical drift | — | ✓ |
| Generates QC reports | — | ✓ |
| Works without renv | — | ✓ |
| Works best with renv | ✓ | ✓ |

`renv` locks your packages. `reproducr` tells you whether locking is enough.

---

## Contributing

Contributions to the breaking-changes database are especially welcome. Each
entry requires:

1. A `pkg::fn` key
2. A version window (`from_version`, `to_version`)
3. A risk level (`"high"`, `"medium"`, or `"low"`)
4. A plain-English description of the breaking change
5. A URL reference (package `NEWS.md`, CRAN page, GitHub release)

See `R/breaking_changes_db.R` for the existing format and open a pull request.

---

## Citation

If you use `reproducr` in published research, please cite:

```
Last, F. (2026). reproducr: Computational Reproducibility Auditing for R
Projects. R package version 0.1.0. https://github.com/ndohpenngit/reproducr
```

---

## License

MIT © 2026 reproducr authors
