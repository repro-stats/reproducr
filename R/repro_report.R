#' Generate a human-readable reproducibility report
#'
#' @description
#' Renders a reproducibility audit report from an [audit_script()] result
#' and optionally a [risk_score()] result and [check_drift()] result. Three
#' style presets are available:
#'
#' - **`"minimal"`** — compact summary suitable for console review or internal
#'   project documentation.
#' - **`"academic"`** — generates a ready-to-paste methods paragraph for journal
#'   submissions, listing all packages with versions and summarising risk findings.
#' - **`"pharma"`** — structured QC document with a risk register and sign-off
#'   fields, suitable for pharmaceutical or regulated analytical workflows.
#'
#' @param audit An `audit_report` object from [audit_script()]. Required.
#' @param risks A `risk_report` data frame from [risk_score()]. Optional but
#'   strongly recommended — without it, the report cannot assess reproducibility.
#' @param drift A `drift_report` data frame from [check_drift()]. Optional.
#' @param format `character(1)`. Output format: `"text"` (console),
#'   `"md"` (Markdown file), or `"html"` (HTML file). Default `"text"`.
#' @param style `character(1)`. Report style: `"minimal"`, `"academic"`, or
#'   `"pharma"`. Default `"minimal"`.
#' @param output_file `character(1)` or `NULL`. Output file path (used for
#'   `format = "md"` and `format = "html"`). If `NULL`, a sensible default
#'   name is used (`"reproducr_report.md"` / `"reproducr_report.html"`).
#'
#' @return Invisibly returns the report content as a character string. For
#'   file-based formats, the file is also written to disk.
#'
#' @seealso [audit_script()], [risk_score()], [check_drift()], [repro_badge()]
#'
#' @examples
#' script <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "set.seed(42)",
#'   "x <- dplyr::filter(mtcars, cyl == 4)",
#'   "y <- stats::rnorm(10)"
#' ), script)
#'
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' risks  <- risk_score(report)
#'
#' # Console summary
#' repro_report(report, risks, format = "text", style = "minimal")
#'
#' # Academic methods paragraph (printed, not written to file)
#' cat(repro_report(report, risks, format = "text", style = "academic"))
#'
#' @export
repro_report <- function(audit,
                         risks       = NULL,
                         drift       = NULL,
                         format      = "text",
                         style       = "minimal",
                         output_file = NULL) {

  if (!inherits(audit, "audit_report")) {
    stop("`audit` must be an `audit_report` object from `audit_script()`.",
         call. = FALSE)
  }
  format <- match.arg(format, c("text", "md", "html"))
  style  <- match.arg(style,  c("minimal", "academic", "pharma"))

  verdict <- .compute_verdict(risks, drift)

  md_content <- switch(style,
    minimal  = .render_minimal(audit, risks, drift, verdict),
    academic = .render_academic(audit, risks, verdict),
    pharma   = .render_pharma(audit, risks, drift, verdict)
  )

  if (format == "html") {
    content <- .md_to_html(md_content,
                           title = sprintf("reproducr Report \u2014 %s", style))
  } else {
    content <- md_content
  }

  if (format == "text") {
    # Strip most markdown syntax for readable console output
    text <- gsub("^#{1,3} ", "", content, perl = TRUE)
    text <- gsub("\\*\\*([^*]+)\\*\\*", "\\1", text, perl = TRUE)
    text <- gsub("`([^`]+)`", "\\1", text, perl = TRUE)
    text <- gsub("^- ", "  * ", text, perl = TRUE)
    cat(text)
  } else {
    if (is.null(output_file)) {
      output_file <- if (format == "html") "reproducr_report.html"
                     else                  "reproducr_report.md"
    }
    writeLines(content, output_file)
    message("reproducr: report written to '", output_file, "'")
  }

  invisible(content)
}


#' Generate a reproducibility status badge
#'
#' @description
#' Produces a [shields.io](https://shields.io) Markdown badge reflecting the
#' current reproducibility status of a project. The badge is colour-coded:
#'
#' - **Green** (`reproducible`) — no risks detected.
#' - **Yellow** (`caution`) — medium-severity risks only.
#' - **Red** (`at risk`) — one or more high-severity risks or drifted outputs.
#' - **Grey** (`unknown`) — no risk information supplied.
#'
#' Can be inserted automatically into a `README.md` (e.g. from a GitHub
#' Actions workflow).
#'
#' @param audit An `audit_report` from [audit_script()].
#' @param risks A `risk_report` from [risk_score()]. Optional.
#' @param drift A `drift_report` from [check_drift()]. Optional.
#' @param output `character(1)`. `"markdown"` (return the badge string) or
#'   `"README"` (insert/update the badge in `README.md`). Default `"markdown"`.
#' @param readme_path `character(1)`. Path to the README file when
#'   `output = "README"`. Default `"README.md"`.
#'
#' @return Invisibly returns the badge Markdown string.
#'
#' @examples
#' script <- tempfile(fileext = ".R")
#' writeLines("x <- dplyr::filter(mtcars, cyl == 4)", script)
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' risks  <- risk_score(report)
#'
#' badge <- repro_badge(report, risks)
#' cat(badge)
#'
#' @export
repro_badge <- function(audit,
                        risks       = NULL,
                        drift       = NULL,
                        output      = "markdown",
                        readme_path = "README.md") {

  if (!inherits(audit, "audit_report")) {
    stop("`audit` must be an `audit_report` object from `audit_script()`.",
         call. = FALSE)
  }
  output <- match.arg(output, c("markdown", "README"))

  verdict <- .compute_verdict(risks, drift)

  badge_meta <- list(
    reproducible = list(label = "reproducible", color = "brightgreen"),
    caution      = list(label = "caution",       color = "yellow"),
    at_risk      = list(label = "at%20risk",     color = "red"),
    unknown      = list(label = "unknown",        color = "lightgrey")
  )[[verdict$level]]

  badge_url <- sprintf(
    "https://img.shields.io/badge/reproducibility-%s-%s",
    badge_meta$label, badge_meta$color
  )
  badge_md <- sprintf("![reproducibility](%s)", badge_url)

  if (output == "README") {
    if (!file.exists(readme_path)) {
      stop("README not found at '", readme_path, "'. ",
           "Create the file first or set readme_path.", call. = FALSE)
    }
    lines   <- readLines(readme_path, warn = FALSE)
    tag_open  <- "<!-- reproducr-badge -->"
    tag_close <- "<!-- /reproducr-badge -->"
    badge_line <- paste0(tag_open, badge_md, tag_close)

    existing <- grep(tag_open, lines, fixed = TRUE)
    if (length(existing) > 0L) {
      lines[existing[[1L]]] <- badge_line
      if (length(existing) > 1L) lines <- lines[-existing[-1L]]
    } else {
      lines <- c(badge_line, "", lines)
    }
    writeLines(lines, readme_path)
    message("reproducr: badge updated in '", readme_path, "'")
  } else {
    cat(badge_md, "\n")
  }

  invisible(badge_md)
}


# ---- rendering helpers ------------------------------------------------------

.compute_verdict <- function(risks, drift) {
  n_high    <- if (!is.null(risks)) sum(risks$risk == "high",    na.rm = TRUE) else 0L
  n_medium  <- if (!is.null(risks)) sum(risks$risk == "medium",  na.rm = TRUE) else 0L
  n_drifted <- if (!is.null(drift)) sum(drift$status == "drifted", na.rm = TRUE) else 0L

  if (is.null(risks) && is.null(drift)) {
    return(list(
      level   = "unknown",
      summary = "Reproducibility status unknown \u2014 run `risk_score()` to assess.",
      emoji   = "?"
    ))
  }
  if (n_high > 0L || n_drifted > 0L) {
    list(
      level   = "at_risk",
      summary = sprintf(
        "AT RISK: %d high-severity risk(s)%s detected.",
        n_high,
        if (n_drifted > 0L) sprintf(", %d drifted output(s)", n_drifted) else ""
      ),
      emoji = "x"
    )
  } else if (n_medium > 0L) {
    list(
      level   = "caution",
      summary = sprintf(
        "CAUTION: %d medium-severity risk(s) detected. Review before submission.",
        n_medium
      ),
      emoji = "!"
    )
  } else {
    list(
      level   = "reproducible",
      summary = "REPRODUCIBLE: No significant risks detected.",
      emoji   = "v"
    )
  }
}

.render_minimal <- function(audit, risks, drift, verdict) {
  n_pkgs  <- length(unique(audit$calls$pkg[nchar(audit$calls$pkg) > 0L]))
  n_calls <- nrow(audit$calls)

  lines <- c(
    "# reproducr audit report",
    "",
    sprintf("- **Generated:** %s", format(audit$timestamp, "%Y-%m-%d %H:%M")),
    sprintf("- **R version:** %s", audit$env$r_version),
    sprintf("- **Platform:** %s",  audit$env$os),
    sprintf("- **Files scanned:** %d", length(audit$paths)),
    sprintf("- **Packages found:** %d", n_pkgs),
    sprintf("- **Qualified calls:** %d", n_calls),
    sprintf("- **Versions from:** %s",
            if (isTRUE(audit$renv_used)) "renv.lock" else "installed library"),
    "",
    "## Verdict",
    "",
    sprintf("> %s", verdict$summary),
    ""
  )

  if (!is.null(risks) && nrow(risks) > 0L) {
    lines <- c(lines, "## Risks", "")
    for (i in seq_len(nrow(risks))) {
      r <- risks[i, , drop = FALSE]
      lines <- c(lines,
        sprintf("### [%s] `%s`", toupper(r$risk), r$call),
        sprintf("- **File:** %s, line %d", basename(r$file), r$line),
        sprintf("- **Check:** %s", r$check),
        sprintf("- **Details:** %s", r$description),
        sprintf("- **Reference:** <%s>", r$reference),
        ""
      )
    }
  }

  if (!is.null(drift) && nrow(drift) > 0L) {
    lines <- c(lines, "## Drift check", "")
    for (i in seq_len(nrow(drift))) {
      d <- drift[i, , drop = FALSE]
      lines <- c(lines,
        sprintf("- **%s** `%s`%s",
                toupper(d$status), d$output,
                if (nchar(trimws(d$note)) > 0L) paste0(" \u2014 ", d$note) else "")
      )
    }
    lines <- c(lines, "")
  }

  paste(lines, collapse = "\n")
}

.render_academic <- function(audit, risks, verdict) {
  # Build "pkg (v1.2.3)" list
  if (nrow(audit$calls) > 0L) {
    pkgs <- unique(audit$calls$pkg[!is.na(audit$calls$pkg)])
    pkg_strs <- vapply(pkgs, function(p) {
      v <- audit$calls$pkg_version[audit$calls$pkg == p][1L]
      if (!is.na(v)) sprintf("%s (v%s)", p, v) else p
    }, character(1L))
    pkg_sentence <- paste(pkg_strs, collapse = ", ")
  } else {
    pkg_sentence <- "no qualified package calls detected"
  }

  n_risks <- if (!is.null(risks)) nrow(risks) else 0L
  risk_sentence <- if (n_risks == 0L) {
    "Reproducibility auditing (reproducr) identified no risks."
  } else {
    n_h <- sum(risks$risk == "high",   na.rm = TRUE)
    n_m <- sum(risks$risk == "medium", na.rm = TRUE)
    sprintf(
      paste0("Reproducibility auditing (reproducr) identified %d potential ",
             "concern(s) (%d high, %d medium severity) relating to known ",
             "behavioural changes in package APIs across versions."),
      n_risks, n_h, n_m
    )
  }

  paragraph <- sprintf(
    paste0(
      "All analyses were conducted in R (version %s) on %s. ",
      "The following packages were used: %s. ",
      "Package environments were managed using renv. ",
      "%s ",
      "The full audit report and certification records are available in ",
      "the supplementary materials."
    ),
    audit$env$r_version,
    audit$env$os,
    pkg_sentence,
    risk_sentence
  )

  paste(c("# Methods paragraph (reproducr)", "", paragraph, ""), collapse = "\n")
}

.render_pharma <- function(audit, risks, drift, verdict) {
  lines <- c(
    "# Computational Reproducibility QC Document",
    "",
    sprintf("| Field | Value |"),
    sprintf("|---|---|"),
    sprintf("| Document version | 1.0 |"),
    sprintf("| Date | %s |", format(audit$timestamp, "%Y-%m-%d")),
    sprintf("| Generated by | reproducr R package |"),
    sprintf("| Verdict | **%s** |", verdict$summary),
    "",
    "## 1. Execution environment",
    "",
    sprintf("| Property | Value |"),
    sprintf("|---|---|"),
    sprintf("| R version | %s |", audit$env$r_version),
    sprintf("| Platform | %s |", audit$env$r_platform),
    sprintf("| OS | %s |", audit$env$os),
    sprintf("| Locale | %s |", audit$env$locale),
    sprintf("| Timezone | %s |", audit$env$timezone),
    sprintf("| Package versions from | %s |",
            if (isTRUE(audit$renv_used)) "renv.lock" else "installed library"),
    "",
    "## 2. Files audited",
    ""
  )
  for (f in audit$paths) lines <- c(lines, sprintf("- `%s`", f))
  lines <- c(lines, "")

  lines <- c(lines, "## 3. Package inventory", "")
  if (nrow(audit$calls) > 0L) {
    pkgs <- unique(audit$calls[, c("pkg", "pkg_version"), drop = FALSE])
    pkgs <- pkgs[!duplicated(pkgs$pkg), ]
    lines <- c(lines, "| Package | Version |", "|---|---|")
    for (i in seq_len(nrow(pkgs))) {
      lines <- c(lines, sprintf("| %s | %s |", pkgs$pkg[i],
                                 ifelse(is.na(pkgs$pkg_version[i]), "unknown",
                                        pkgs$pkg_version[i])))
    }
  } else {
    lines <- c(lines, "_No qualified package calls detected._")
  }
  lines <- c(lines, "")

  lines <- c(lines, "## 4. Risk register", "")
  if (is.null(risks) || nrow(risks) == 0L) {
    lines <- c(lines, "_No risks identified._", "")
  } else {
    for (i in seq_len(nrow(risks))) {
      r <- risks[i, , drop = FALSE]
      lines <- c(lines,
        sprintf("### Risk %d: `%s`", i, r$call),
        sprintf("| Field | Value |"),
        sprintf("|---|---|"),
        sprintf("| Severity | **%s** |", toupper(r$risk)),
        sprintf("| File | %s, line %d |", basename(r$file), r$line),
        sprintf("| Check method | %s |", r$check),
        sprintf("| Description | %s |", gsub("|", "\\|", r$description, fixed = TRUE)),
        sprintf("| Reference | <%s> |", r$reference),
        ""
      )
    }
  }

  if (!is.null(drift)) {
    lines <- c(lines, "## 5. Drift assessment", "")
    lines <- c(lines, "| Output | Status | Note |", "|---|---|---|")
    for (i in seq_len(nrow(drift))) {
      d <- drift[i, , drop = FALSE]
      lines <- c(lines, sprintf("| %s | %s | %s |",
                                 d$output, d$status,
                                 ifelse(nchar(trimws(d$note)) > 0L, d$note, "")))
    }
    lines <- c(lines, "")
    n_next <- 6L
  } else {
    n_next <- 5L
  }

  lines <- c(lines,
    sprintf("## %d. Sign-off", n_next),
    "",
    "| Role | Name | Signature | Date |",
    "|---|---|---|---|",
    "| Analyst | | | |",
    "| Reviewer | | | |",
    ""
  )

  paste(lines, collapse = "\n")
}

.md_to_html <- function(md, title = "reproducr Report") {
  # Light Markdown -> HTML conversion (no external dependencies)
  html <- md
  html <- gsub("^# (.+)$",    "<h1>\\1</h1>",  html, perl = TRUE)
  html <- gsub("^## (.+)$",   "<h2>\\1</h2>",  html, perl = TRUE)
  html <- gsub("^### (.+)$",  "<h3>\\1</h3>",  html, perl = TRUE)
  html <- gsub("^> (.+)$",    "<blockquote>\\1</blockquote>", html, perl = TRUE)
  html <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", html, perl = TRUE)
  html <- gsub("`([^`]+)`",   "<code>\\1</code>", html, perl = TRUE)
  html <- gsub("^- (.+)$",    "<li>\\1</li>",  html, perl = TRUE)
  # Simple table rows
  html <- gsub("^\\|(.+)\\|$", "<tr><td>\\1</td></tr>", html, perl = TRUE)

  css <- paste0(
    "body{font-family:system-ui,-apple-system,sans-serif;",
    "max-width:860px;margin:2rem auto;padding:0 1.5rem;",
    "line-height:1.6;color:#111;} ",
    "h1{font-size:1.6rem;border-bottom:2px solid #eee;padding-bottom:.4rem;} ",
    "h2{font-size:1.25rem;margin-top:2rem;border-bottom:1px solid #eee;} ",
    "h3{font-size:1.05rem;color:#333;} ",
    "code{background:#f5f5f5;padding:2px 6px;border-radius:3px;font-size:.9em;} ",
    "blockquote{border-left:4px solid #0070f3;margin:0;",
    "padding:.5rem 1rem;background:#f0f7ff;border-radius:0 4px 4px 0;} ",
    "table{border-collapse:collapse;width:100%;margin:1rem 0;} ",
    "td,th{border:1px solid #ddd;padding:.4rem .7rem;} ",
    "tr:nth-child(even){background:#fafafa;} ",
    "li{margin:.2rem 0;}"
  )

  paste0(
    "<!DOCTYPE html><html lang='en'><head>",
    "<meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>",
    "<title>", title, "</title>",
    "<style>", css, "</style>",
    "</head><body>\n",
    paste(html, collapse = "\n"),
    "\n</body></html>"
  )
}
