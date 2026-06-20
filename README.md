# reproducr <a href="https://repro-stats.github.io/reproducr/"><img src="man/figures/logo.svg" align="right" height="120" alt="reproducr website" /></a>

<!-- badges: start -->
[![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
[![CRAN status](https://www.r-pkg.org/badges/version/reproducr)](https://CRAN.R-project.org/package=reproducr)
[![R-CMD-check](https://github.com/repro-stats/reproducr/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/repro-stats/reproducr/actions/workflows/R-CMD-check.yml)
[![Codecov test coverage](https://codecov.io/gh/repro-stats/reproducr/graph/badge.svg)](https://app.codecov.io/gh/repro-stats/reproducr)
<!-- badges: end -->

> The reproducibility badge reflects the status of the [gallery repos](#gallery). See those repos for a live demonstration of `repro_badge()` in a real analysis workflow.

> **Know your R analysis will produce the same results tomorrow as it does today.**

---

## The problem

You finish an analysis. The code runs. The numbers look right. But are they stable?

Package updates change function behaviour silently. Stochastic code without a fixed seed produces different results on every run. A model fitted on one platform may return subtly different coefficients on another. Results that were correct in January may drift by March — with no error, no warning, and no obvious cause.

`reproducr` makes these risks visible and trackable, before they reach a journal, a regulator, or a collaborator.

---

## What it does

**Scans your scripts** for known breaking changes across popular CRAN packages, flags stochastic calls missing `set.seed()`, and identifies locale-sensitive operations that behave differently across systems.

**Certifies your outputs** by hashing key results — model coefficients, summary statistics, p-values — so any numerical drift is detected automatically on subsequent runs.

**Generates audit reports** in three styles: a plain summary, a ready-to-paste academic methods paragraph, and a structured QC document with sign-off fields for regulated workflows.

**Works with your existing setup.** If you use `renv`, `reproducr` reads your lockfile automatically. If you don't, it uses your installed library. No configuration required.

---

## Installation

```r
# Development version from GitHub
install.packages("remotes")
remotes::install_github("repro-stats/reproducr")
```

---

## Gallery

Real-world pipelines demonstrating the full `reproducr` workflow across
different domains, environments, and regulatory contexts. Each repository
is a complete, independently runnable analysis with CI that audits on every
push, certifies outputs, detects drift, and updates the badge automatically.

| Example | Domain | Audience | renv | Report style | Badge | Walkthrough |
|---|---|---|---|---|---|---|
| [reproducr-ecology](https://github.com/repro-stats/reproducr-ecology) | Ecology / penguins | General R users | No | minimal | [![reproducibility](https://github.com/repro-stats/reproducr-ecology/actions/workflows/reproducr-audit.yml/badge.svg)](https://github.com/repro-stats/reproducr-ecology/actions/workflows/reproducr-audit.yml) | [DEMO.md](https://github.com/repro-stats/reproducr-ecology/blob/main/DEMO.md) |
| [reproducr-clinical](https://github.com/repro-stats/reproducr-clinical) | Clinical trials / oncology | Biostatisticians, pharma | Yes | pharma | [![reproducibility](https://github.com/repro-stats/reproducr-clinical/actions/workflows/reproducr-audit.yml/badge.svg)](https://github.com/repro-stats/reproducr-clinical/actions/workflows/reproducr-audit.yml) | [DEMO.md](https://github.com/repro-stats/reproducr-clinical/blob/main/DEMO.md) |
| [reproducr-rwe](https://github.com/repro-stats/reproducr-rwe) | Real world evidence | Epidemiologists, HEOR | Yes | academic | [![reproducibility](https://github.com/repro-stats/reproducr-rwe/actions/workflows/reproducr-audit.yml/badge.svg)](https://github.com/repro-stats/reproducr-rwe/actions/workflows/reproducr-audit.yml) | [DEMO.md](https://github.com/repro-stats/reproducr-rwe/blob/main/DEMO.md) |
| [reproducr-cmc](https://github.com/repro-stats/reproducr-cmc) | CMC statistics | CMC statisticians, regulatory affairs | Yes | pharma | [![reproducibility](https://github.com/repro-stats/reproducr-cmc/actions/workflows/reproducr-audit.yml/badge.svg)](https://github.com/repro-stats/reproducr-cmc/actions/workflows/reproducr-audit.yml) | [DEMO.md](https://github.com/repro-stats/reproducr-cmc/blob/main/DEMO.md) |

Together they demonstrate that `reproducr` is environment-agnostic — it works
with or without `renv`, across domains, and at any level of regulatory rigour.
Each `DEMO.md` walks through the complete pipeline with real output at every step.

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
#>   R version:        4.4.2
#>   Platform:         aarch64-apple-darwin20
#>   Versions from:    installed library
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

# Step 4: After any environment change or package upgrade, check for drift
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
| `check_db_staleness()` | — | Check database entries against current CRAN versions |

### The three-tier workflow

```
Tier 1 — Scan & score          Tier 2 — Baseline & drift       Tier 3 — Report & export
─────────────────────          ─────────────────────────       ─────────────────────────
audit_script()                 certify()                       repro_report()
     │                              │                               │
     ▼                              ▼                               ▼
risk_score()                   check_drift()                   repro_badge()
```

Use Tier 1 alone for a quick scan, or build the full pipeline for regulated or peer-reviewed work.

---

## The breaking-changes database

The heart of `risk_score()` is a curated database of known cases where a package update **silently changed function behaviour** — not errors, not deprecation warnings, just different results. Coverage spans popular packages across the tidyverse, modelling (`lme4`, `survival`, `MatchIt`, `caret`), and base R.

The database is kept current via a weekly automated check -- see `check_db_staleness()`.
Community contributions are welcome via **[reproducr-db](https://github.com/repro-stats/reproducr-db)**, which lists every tracked entry.

---

## Risk checks

### `"changelog"` — Breaking changes database

Checks every detected `pkg::fn` call against the built-in database. A call is flagged only if the installed version falls within a known risky version window `(from_ver, to_ver]`.

Risk levels:
- **HIGH** — output values can change silently with no error
- **MEDIUM** — argument renamed or deprecated; may error or produce different output
- **LOW** — minor behavioural note; output unlikely to differ in practice

### `"seed_check"` — Missing set.seed()

Flags any call to a stochastic function (`rnorm`, `sample`, `rbinom`, etc.) where no `set.seed()` is found within 50 lines above the call.

```r
# This will be flagged:
x <- stats::rnorm(100)

# This will not:
set.seed(42)
x <- stats::rnorm(100)
```

### `"locale_check"` — Locale-sensitive operations

Flags functions whose output depends on the system locale (`sort()`, `format()`, `strftime()`, etc.) — relevant when code runs on servers in different countries or with different OS locale settings.

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

# Three months later, after any environment change:
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

### `"academic"`
A ready-to-paste methods paragraph for journal submissions:

> *All analyses were conducted in R (version 4.4.2) on macOS 26.5.
> The following packages were used: dplyr (v1.1.4), ggplot2 (v3.5.1) ...
> Reproducibility auditing (reproducr) identified no risks. The full audit
> report and certification records are available in the supplementary materials.*

### `"pharma"`
A structured QC document with execution environment table, full package inventory, risk register, drift assessment, and sign-off fields for analyst and reviewer.

```r
repro_report(report, risks, drift,
             format = "html", style = "pharma",
             output_file = "qc_report.html")
```

---

## CI/CD integration

`reproducr` is designed to run automatically on every push. A typical workflow:

- Audits your scripts for risk
- Checks for drift against the last certified run
- Updates the reproducibility badge in your README

See the [reports and badges vignette](https://repro-stats.github.io/reproducr/articles/reports-and-badges.html) for the complete GitHub Actions workflow.

---

## Contributing

### Breaking-changes database

The database powering `risk_score()` is maintained in a dedicated community
repository — **[reproducr-db](https://github.com/repro-stats/reproducr-db)**.

Contributing a new entry requires:

1. A `pkg::fn` key
2. A version window (`from_version`, `to_version`)
3. A risk level (`"high"`, `"medium"`, or `"low"`)
4. A plain-English description of the breaking change
5. A URL reference (package `NEWS.md`, CRAN page, GitHub release)

Each entry is a small JSON file — see the
[reproducr-db README](https://github.com/repro-stats/reproducr-db#entry-format)
for the format and the
[contributing guide](https://repro-stats.github.io/reproducr/articles/contributing-to-the-database.html)
for the version window design principles.

### Code of conduct

Please note that this project is released with a
[Contributor Code of Conduct](https://github.com/repro-stats/reproducr/blob/main/CODE_OF_CONDUCT.md).
By participating you agree to abide by its terms.

### Package development

To contribute to `reproducr` itself — new features, bug fixes, or
additional risk checks — open an issue or pull request on the
[main repository](https://github.com/repro-stats/reproducr).
