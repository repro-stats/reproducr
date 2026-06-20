# Generating reports and badges

This vignette covers Tier 3 of the `reproducr` workflow:
[`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
and
[`repro_badge()`](https://repro-stats.github.io/reproducr/reference/repro_badge.md).
These functions turn audit results into documents and status indicators
for external consumption.

------------------------------------------------------------------------

## `repro_report()` — generating reports

[`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
combines an `audit_report`, an optional `risk_report`, and an optional
`drift_report` into a single human-readable document. It has two
orthogonal dimensions:

- **`style`** — what the report contains (`"minimal"`, `"academic"`,
  `"pharma"`)
- **`format`** — how it is rendered (`"text"`, `"md"`, `"html"`)

### The verdict

Every report leads with a verdict, computed from the risks and drift:

| Verdict        | Condition                                     |
|----------------|-----------------------------------------------|
| `REPRODUCIBLE` | No risks detected, no drifted outputs         |
| `CAUTION`      | Medium-severity risks only, no drift          |
| `AT RISK`      | Any high-severity risk, or any drifted output |
| `UNKNOWN`      | No `risks` or `drift` supplied                |

``` r

# No risks — REPRODUCIBLE
clean_script <- tempfile(fileext = ".R")
writeLines("x <- 1 + 1", clean_script)
clean_report <- audit_script(clean_script, renv = FALSE, verbose = FALSE)
clean_risks <- risk_score(clean_report)

cat(repro_report(clean_report, clean_risks, format = "text", style = "minimal"))
#> reproducr audit report
#> 
#> - Generated: 2026-06-20 19:29
#> - R version: 4.6.0
#> - Platform: Linux 6.17.0-1018-azure
#> - Files scanned: 1
#> - Packages found: 0
#> - Qualified calls: 0
#> - Versions from: installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
#> # reproducr audit report
#> 
#> - **Generated:** 2026-06-20 19:29
#> - **R version:** 4.6.0
#> - **Platform:** Linux 6.17.0-1018-azure
#> - **Files scanned:** 1
#> - **Packages found:** 0
#> - **Qualified calls:** 0
#> - **Versions from:** installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
```

------------------------------------------------------------------------

## Style: `"minimal"`

A compact summary covering environment metadata, verdict, and risk
table. Use this for internal project documentation, PR descriptions, or
quick console review.

``` r

cat(repro_report(report, risks, format = "text", style = "minimal"))
#> reproducr audit report
#> 
#> - Generated: 2026-06-20 19:29
#> - R version: 4.6.0
#> - Platform: Linux 6.17.0-1018-azure
#> - Files scanned: 1
#> - Packages found: 3
#> - Qualified calls: 5
#> - Versions from: installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
#> 
#> ## Risks
#> 
#> ### [LOW] base::sort
#> - File: file1ba161a40fee.R, line 5
#> - Check: locale_check
#> - Details: sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> - Reference: <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>
#> # reproducr audit report
#> 
#> - **Generated:** 2026-06-20 19:29
#> - **R version:** 4.6.0
#> - **Platform:** Linux 6.17.0-1018-azure
#> - **Files scanned:** 1
#> - **Packages found:** 3
#> - **Qualified calls:** 5
#> - **Versions from:** installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
#> 
#> ## Risks
#> 
#> ### [LOW] `base::sort`
#> - **File:** file1ba161a40fee.R, line 5
#> - **Check:** locale_check
#> - **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> - **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>
```

The minimal style includes:

- Generation timestamp and R version
- File count, package count, call count
- Version source (lockfile or installed library)
- Overall verdict
- One entry per risk (if any)
- Drift summary (if drift is supplied)

``` r

cat(repro_report(report, risks,
  drift = drift,
  format = "text", style = "minimal"
))
#> reproducr audit report
#> 
#> - Generated: 2026-06-20 19:29
#> - R version: 4.6.0
#> - Platform: Linux 6.17.0-1018-azure
#> - Files scanned: 1
#> - Packages found: 3
#> - Qualified calls: 5
#> - Versions from: installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
#> 
#> ## Risks
#> 
#> ### [LOW] base::sort
#> - File: file1ba161a40fee.R, line 5
#> - Check: locale_check
#> - Details: sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> - Reference: <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>
#> 
#> ## Drift check
#> 
#> - OK coefs
#> # reproducr audit report
#> 
#> - **Generated:** 2026-06-20 19:29
#> - **R version:** 4.6.0
#> - **Platform:** Linux 6.17.0-1018-azure
#> - **Files scanned:** 1
#> - **Packages found:** 3
#> - **Qualified calls:** 5
#> - **Versions from:** installed library
#> 
#> ## Verdict
#> 
#> > REPRODUCIBLE: No significant risks detected.
#> 
#> ## Risks
#> 
#> ### [LOW] `base::sort`
#> - **File:** file1ba161a40fee.R, line 5
#> - **Check:** locale_check
#> - **Details:** sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE or LC_TIME settings.
#> - **Reference:** <https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html>
#> 
#> ## Drift check
#> 
#> - **OK** `coefs`
```

------------------------------------------------------------------------

## Style: `"academic"`

Generates a ready-to-paste methods paragraph for journal submission or a
thesis. The paragraph lists every detected package with its version,
states the R version and operating system, and summarises the risk
findings.

``` r

cat(repro_report(report, risks, format = "text", style = "academic"))
#> Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1018-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 1 potential concern(s) (0 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
#> # Methods paragraph (reproducr)
#> 
#> All analyses were conducted in R (version 4.6.0) on Linux 6.17.0-1018-azure. The following packages were used: dplyr, stats (v4.6.0), base (v4.6.0). Reproducibility auditing (reproducr) identified 1 potential concern(s) (0 high, 0 medium severity) relating to known behavioural changes in package APIs across versions. The full audit report and certification records are available in the supplementary materials.
```

This is intentionally a single prose paragraph so it can be pasted
directly into a “Software and data” or “Computational reproducibility”
subsection. If no risks were found, the paragraph says so explicitly. If
risks were found, it states the count and severity so reviewers know to
look at the supplementary materials.

**Example output in a paper:**

> All analyses were conducted in R (version 4.3.3) on Linux 6.1.0. The
> following packages were used: dplyr (v1.1.4), ggplot2 (v3.5.1), readr
> (v2.1.5). Reproducibility auditing (reproducr) identified no risks.
> The full audit report and certification records are available in the
> supplementary materials.

------------------------------------------------------------------------

## Style: `"pharma"`

A structured QC document with formal sections, a complete package
inventory, a risk register, and sign-off fields for analyst and
reviewer. This style is designed for pharmaceutical, biotech, and other
regulated analytical workflows where the output needs to be reviewed and
signed before submission.

``` r

cat(repro_report(report, risks,
  drift = drift,
  format = "text", style = "pharma"
))
#> Computational Reproducibility QC Document
#> 
#> | Field | Value |
#> |---|---|
#> | Document version | 1.0 |
#> | Date | 2026-06-20 |
#> | Generated by | reproducr R package |
#> | Verdict | REPRODUCIBLE: No significant risks detected. |
#> 
#> ## 1. Execution environment
#> 
#> | Property | Value |
#> |---|---|
#> | R version | 4.6.0 |
#> | Platform | x86_64-pc-linux-gnu |
#> | OS | Linux 6.17.0-1018-azure |
#> | Locale | LC_CTYPE=C.UTF-8;LC_NUMERIC=C;LC_TIME=C.UTF-8;LC_COLLATE=C.UTF-8;LC_MONETARY=C.UTF-8;LC_MESSAGES=C.UTF-8;LC_PAPER=C.UTF-8;LC_NAME=C;LC_ADDRESS=C;LC_TELEPHONE=C;LC_MEASUREMENT=C.UTF-8;LC_IDENTIFICATION=C |
#> | Timezone | UTC |
#> | Package versions from | installed library |
#> 
#> ## 2. Files audited
#> 
#> - /tmp/Rtmp0dtA5F/file1ba161a40fee.R
#> 
#> ## 3. Package inventory
#> 
#> | Package | Version |
#> |---|---|
#> | dplyr | unknown |
#> | stats | 4.6.0 |
#> | base | 4.6.0 |
#> 
#> ## 4. Risk register
#> 
#> | # | Call | Severity | File | Check | Description |
#> |---|---|---|---|---|---|
#> | 1 | base::sort | LOW | file1ba161a40fee.R:5 | locale_check | sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE ... |
#> 
#> ## 5. Drift assessment
#> 
#> | Output | Status | Note |
#> |---|---|---|
#> | coefs | ok |  |
#> 
#> ## 6. Sign-off
#> 
#> | Role | Name | Signature | Date |
#> |---|---|---|---|
#> | Analyst | | | |
#> | Reviewer | | | |
#> # Computational Reproducibility QC Document
#> 
#> | Field | Value |
#> |---|---|
#> | Document version | 1.0 |
#> | Date | 2026-06-20 |
#> | Generated by | reproducr R package |
#> | Verdict | **REPRODUCIBLE: No significant risks detected.** |
#> 
#> ## 1. Execution environment
#> 
#> | Property | Value |
#> |---|---|
#> | R version | 4.6.0 |
#> | Platform | x86_64-pc-linux-gnu |
#> | OS | Linux 6.17.0-1018-azure |
#> | Locale | LC_CTYPE=C.UTF-8;LC_NUMERIC=C;LC_TIME=C.UTF-8;LC_COLLATE=C.UTF-8;LC_MONETARY=C.UTF-8;LC_MESSAGES=C.UTF-8;LC_PAPER=C.UTF-8;LC_NAME=C;LC_ADDRESS=C;LC_TELEPHONE=C;LC_MEASUREMENT=C.UTF-8;LC_IDENTIFICATION=C |
#> | Timezone | UTC |
#> | Package versions from | installed library |
#> 
#> ## 2. Files audited
#> 
#> - `/tmp/Rtmp0dtA5F/file1ba161a40fee.R`
#> 
#> ## 3. Package inventory
#> 
#> | Package | Version |
#> |---|---|
#> | dplyr | unknown |
#> | stats | 4.6.0 |
#> | base | 4.6.0 |
#> 
#> ## 4. Risk register
#> 
#> | # | Call | Severity | File | Check | Description |
#> |---|---|---|---|---|---|
#> | 1 | `base::sort` | **LOW** | file1ba161a40fee.R:5 | locale_check | sort() output is locale-sensitive. Current locale: C.UTF-8. Results may differ on machines with different LC_COLLATE ... |
#> 
#> ## 5. Drift assessment
#> 
#> | Output | Status | Note |
#> |---|---|---|
#> | coefs | ok |  |
#> 
#> ## 6. Sign-off
#> 
#> | Role | Name | Signature | Date |
#> |---|---|---|---|
#> | Analyst | | | |
#> | Reviewer | | | |
```

The pharma style includes:

1.  **Header table** — document version, date, verdict
2.  **Execution environment** — R version, platform, OS, locale,
    timezone, version source
3.  **Files audited** — full paths of all scanned files
4.  **Package inventory** — every detected package with version
5.  **Risk register** — one entry per flagged call with severity, file,
    line, check method, description, and reference URL
6.  **Drift assessment** — table of all certified outputs with status
7.  **Sign-off** — analyst and reviewer fields

------------------------------------------------------------------------

## Format: `"md"` and `"html"`

For `"md"` and `"html"` formats,
[`repro_report()`](https://repro-stats.github.io/reproducr/reference/repro_report.md)
writes to a file. If `output_file` is not specified, it defaults to
`"reproducr_report.md"` or `"reproducr_report.html"` in the working
directory.

``` r

md_file <- tempfile(fileext = ".md")
repro_report(report, risks,
  format      = "md",
  style       = "minimal",
  output_file = md_file
)
#> reproducr: report written to '/tmp/Rtmp0dtA5F/file1ba168b357a7.md'

# Inspect the raw Markdown
cat(readLines(md_file, warn = FALSE), sep = "\n")
```

``` r

html_file <- tempfile(fileext = ".html")
repro_report(report, risks,
  drift = drift,
  format = "html",
  style = "pharma",
  output_file = html_file
)
#> reproducr: report written to '/tmp/Rtmp0dtA5F/file1ba1492f05b1.html'

# The file is self-contained — open it in a browser
# browseURL(html_file)
```

The HTML output is a fully self-contained file with embedded CSS — no
external dependencies, safe to email or attach to a submission.

### All nine combinations

``` r

styles <- c("minimal", "academic", "pharma")
formats <- c("text", "md", "html")

for (sty in styles) {
  for (fmt in formats) {
    if (fmt == "text") {
      repro_report(report, risks, format = fmt, style = sty)
    } else {
      out <- tempfile(fileext = paste0(".", fmt))
      repro_report(report, risks,
        format = fmt, style = sty,
        output_file = out
      )
      message("Written: ", out)
    }
  }
}
```

------------------------------------------------------------------------

## `repro_badge()` — status badges

[`repro_badge()`](https://repro-stats.github.io/reproducr/reference/repro_badge.md)
generates a [shields.io](https://shields.io) badge reflecting the
current reproducibility status of the project. The badge is designed to
sit in a README and update automatically via CI.

### Badge colours

| Badge | Condition |
|----|----|
| ![reproducible](https://img.shields.io/badge/reproducibility-reproducible-brightgreen) | No risks, no drift |
| ![caution](https://img.shields.io/badge/reproducibility-caution-yellow) | Medium risks only |
| ![at risk](https://img.shields.io/badge/reproducibility-at%20risk-red) | High risks or drift |
| ![unknown](https://img.shields.io/badge/reproducibility-unknown-lightgrey) | No risk info supplied |

``` r

# Reproducible — clean script, no risks
clean_badge <- repro_badge(clean_report, clean_risks, output = "markdown")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
cat(clean_badge, "\n")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)

# Unknown — no risks supplied
unknown_badge <- repro_badge(report, output = "markdown")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-unknown-lightgrey)](https://repro-stats.github.io/reproducr/)
cat(unknown_badge, "\n")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-unknown-lightgrey)](https://repro-stats.github.io/reproducr/)

# With risks — colour depends on highest severity
risk_badge <- repro_badge(report, risks, output = "markdown")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
cat(risk_badge, "\n")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
```

### Inserting into `README.md`

``` r

readme <- tempfile(fileext = ".md")
writeLines(c(
  "# myanalysis",
  "",
  "Analysis of the relationship between engine size and fuel efficiency.",
  "",
  "## Installation"
), readme)

# Insert badge at the top
repro_badge(report, risks, output = "README", readme_path = readme)
#> reproducr: badge updated in '/tmp/Rtmp0dtA5F/file1ba14b8f14c1.md'

# See the result
cat(readLines(readme, warn = FALSE), sep = "\n")
#> [![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://repro-stats.github.io/reproducr/)
#> 
#> # myanalysis
#> 
#> Analysis of the relationship between engine size and fuel efficiency.
#> 
#> ## Installation
```

The badge is wrapped in HTML comment markers:

``` html
<!-- reproducr-badge -->![reproducibility](...)<!-- /reproducr-badge -->
```

This makes subsequent calls idempotent — running
[`repro_badge()`](https://repro-stats.github.io/reproducr/reference/repro_badge.md)
again replaces the existing badge rather than inserting a second one. It
is safe to call on every CI push.

### Removing a badge

To remove the badge from a README, delete the line containing
`<!-- reproducr-badge -->`. The comment markers make it easy to find
with any text editor or `grep`.

------------------------------------------------------------------------

## Full CI pipeline

The recommended CI pattern updates the badge automatically on every
push:

``` yaml
name: Reproducibility audit

on:
  push:
    branches: [main, master]
  schedule:
    - cron: '0 6 * * 1'   # Weekly on Monday at 06:00 UTC

jobs:
  audit:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
          use-public-rspm: true

      - name: Install reproducr
        run: Rscript -e "install.packages('.', repos = NULL, type = 'source')"

      - name: Run reproducibility audit
        run: |
          Rscript -e "
            library(reproducr)
            report <- audit_script('vignettes/', renv = FALSE, verbose = FALSE)
            risks  <- risk_score(report)
            repro_badge(report, risks, output = 'README')
            n_high <- sum(risks\$risk == 'high', na.rm = TRUE)
            if (n_high > 0) {
              message(n_high, ' high-severity reproducibility risk(s) detected.')
            }
          "

      - name: Commit updated badge
        if: github.event_name == 'push'
        run: |
          git config user.name  'github-actions[bot]'
          git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
          git add README.md
          git diff --staged --quiet || \
            git commit -m 'chore: update reproducibility badge [skip ci]'
          git push
```

The workflow template is also available as a file inside the package:

``` r

system.file("templates", "github_actions_audit.yml", package = "reproducr")
```
