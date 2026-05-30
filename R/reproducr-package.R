#' reproducr: Computational Reproducibility Auditing for R Projects
#'
#' @description
#' `reproducr` audits R scripts for reproducibility risk beyond what
#' [renv](https://rstudio.github.io/renv/) provides. While `renv` locks
#' package versions, it cannot tell you:
#'
#' - Whether a function's *behaviour* changed silently between versions
#' - Whether stochastic calls lack a `set.seed()`
#' - Whether results have numerically drifted since your last analysis
#' - Whether your code is locale-sensitive
#'
#' `reproducr` fills those gaps.
#'
#' @section Workflow:
#'
#' **Tier 1 — Scan & score**
#'
#' ```r
#' report <- audit_script("analysis.R")
#' risks  <- risk_score(report)
#' print(risks)
#' ```
#'
#' **Tier 2 — Baseline & drift**
#'
#' ```r
#' model <- lm(mpg ~ wt, data = mtcars)
#' certify(list(coefs = coef(model)), tag = "submission-v1")
#'
#' # Later, after a package upgrade:
#' check_drift(list(coefs = coef(model)), against = "submission-v1")
#' ```
#'
#' **Tier 3 — Report & export**
#'
#' ```r
#' repro_report(report, risks, format = "html", style = "pharma")
#' repro_badge(report, risks, output = "README")
#' ```
#'
#' @section Key functions:
#'
#' | Function | Purpose |
#' |---|---|
#' | [audit_script()] | Parse a script and extract all `pkg::fn` calls |
#' | [risk_score()] | Check calls against the breaking-changes database |
#' | [certify()] | Hash and store analytical outputs as a baseline |
#' | [check_drift()] | Compare current outputs against a stored baseline |
#' | [repro_report()] | Render a human-readable audit report |
#' | [repro_badge()] | Generate a reproducibility status badge |
#' | [list_certs()] | List all certifications in a `.reproducr` file |
#'
#' @section Relationship to renv:
#'
#' `reproducr` and `renv` are complementary tools, not alternatives.
#' Use `renv` to freeze package versions. Use `reproducr` to verify that
#' freezing is actually sufficient — i.e. that no silent behavioural changes,
#' missing seeds, or locale dependencies threaten your results.
#'
#' @section The breaking-changes database:
#'
#' The internal database currently covers known breaking changes in:
#' `dplyr`, `tidyr`, `ggplot2`, `readr`, `purrr`, `stringr`, `broom`,
#' `data.table`, `lme4`, `lubridate`, and base R (RNG changes in R 3.6.0).
#' Community contributions to expand the database are very welcome — see
#' the contributing guide on GitHub.
#'
#' @keywords internal
"_PACKAGE"
