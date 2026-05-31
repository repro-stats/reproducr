# reproducr: Behavioural Reproducibility Auditing for R Projects

You finish an analysis. The code runs. The numbers look right. But are
they stable?

`reproducr` makes behavioural reproducibility risks visible and
trackable. It scans your scripts for known silent breaking changes,
flags stochastic calls missing
[`set.seed()`](https://rdrr.io/r/base/Random.html), certifies analytical
outputs as baselines, and detects numerical drift across runs — before
it reaches a journal, a regulator, or a collaborator.

## Workflow

**Tier 1 — Scan & score**

    report <- audit_script("analysis.R")
    risks  <- risk_score(report)
    print(risks)

**Tier 2 — Baseline & drift**

    model <- lm(mpg ~ wt, data = mtcars)
    certify(list(coefs = coef(model)), tag = "submission-v1")

    # After any environment change:
    check_drift(list(coefs = coef(model)), against = "submission-v1")

**Tier 3 — Report & export**

    repro_report(report, risks, format = "html", style = "pharma")
    repro_badge(report, risks, output = "README")

## Key functions

|  |  |
|----|----|
| Function | Purpose |
| [`audit_script()`](https://ndohpenngit.github.io/reproducr/reference/audit_script.md) | Parse a script and extract all `pkg::fn` calls |
| [`risk_score()`](https://ndohpenngit.github.io/reproducr/reference/risk_score.md) | Check calls against the breaking-changes database |
| [`certify()`](https://ndohpenngit.github.io/reproducr/reference/certify.md) | Hash and store analytical outputs as a baseline |
| [`check_drift()`](https://ndohpenngit.github.io/reproducr/reference/check_drift.md) | Compare current outputs against a stored baseline |
| [`repro_report()`](https://ndohpenngit.github.io/reproducr/reference/repro_report.md) | Render a human-readable audit report |
| [`repro_badge()`](https://ndohpenngit.github.io/reproducr/reference/repro_badge.md) | Generate a reproducibility status badge |
| [`list_certs()`](https://ndohpenngit.github.io/reproducr/reference/list_certs.md) | List all certifications in a `.reproducr` file |

## The breaking-changes database

The internal database covers known silent breaking changes in: `dplyr`,
`tidyr`, `ggplot2`, `readr`, `purrr`, `stringr`, `broom`, `data.table`,
`lme4`, `lubridate`, and base R. Community contributions to expand the
database are very welcome — see the contributing vignette.

## See also

Useful links:

- <https://github.com/ndohpenngit/reproducr>

- Report bugs at <https://github.com/ndohpenngit/reproducr/issues>

## Author

**Maintainer**: Ndoh Penn <ndohpenn9@gmail.com>
([ORCID](https://orcid.org/0009-0003-9054-465X))
