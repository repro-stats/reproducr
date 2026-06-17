#' Generate a human-readable reproducibility report
#'
#' @description
#' Renders a reproducibility audit report from an [reproducr::audit_script()] result
#' and optionally a [reproducr::risk_score()] result and [reproducr::check_drift()] result. Three
#' style presets are available:
#'
#' - **`"minimal"`** -- compact summary suitable for console review or internal
#'   project documentation.
#' - **`"academic"`** -- generates a ready-to-paste methods paragraph for journal
#'   submissions, listing all packages with versions and summarising risk findings.
#' - **`"pharma"`** -- structured QC document with a risk register and sign-off
#'   fields, suitable for pharmaceutical or regulated analytical workflows.
#'
#' @param audit An `audit_report` object from [reproducr::audit_script()]. Required.
#' @param risks A `risk_report` data frame from [reproducr::risk_score()]. Optional but
#'   strongly recommended -- without it, the report cannot assess reproducibility.
#' @param drift A `drift_report` data frame from [reproducr::check_drift()]. Optional.
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
#' @seealso [reproducr::audit_script()], [reproducr::risk_score()],
#'   [reproducr::check_drift()], [reproducr::repro_badge()]
#'
#' @examples
#' script <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "set.seed(237)",
#'   "x <- dplyr::filter(mtcars, cyl == 4)",
#'   "y <- stats::rnorm(10)"
#' ), script)
#'
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' risks <- risk_score(report)
#'
#' # Console summary
#' repro_report(report, risks, format = "text", style = "minimal")
#'
#' # Academic methods paragraph (printed, not written to file)
#' cat(repro_report(report, risks, format = "text", style = "academic"))
#'
#' @export
repro_report <- function(audit,
                         risks = NULL,
                         drift = NULL,
                         format = "text",
                         style = "minimal",
                         output_file = NULL) {
  if (!inherits(audit, "audit_report")) {
    stop("`audit` must be an `audit_report` object from `audit_script()`.",
      call. = FALSE
    )
  }
  format <- match.arg(format, c("text", "md", "html"))
  style <- match.arg(style, c("minimal", "academic", "pharma"))

  verdict <- .compute_verdict(risks, drift)

  md_content <- switch(style,
    minimal  = .render_minimal(audit, risks, drift, verdict),
    academic = .render_academic(audit, risks, verdict),
    pharma   = .render_pharma(audit, risks, drift, verdict)
  )

  if (format == "html") {
    content <- .md_to_html(md_content,
      title = sprintf("reproducr Report -- %s", style)
    )
  } else {
    content <- md_content
  }

  if (format == "text") {
    text <- gsub("^#{1,3} ", "", content, perl = TRUE)
    text <- gsub("\\*\\*([^*]+)\\*\\*", "\\1", text, perl = TRUE)
    text <- gsub("`([^`]+)`", "\\1", text, perl = TRUE)
    text <- gsub("^- ", "  * ", text, perl = TRUE)
    cat(text)
  } else {
    if (is.null(output_file)) {
      output_file <- if (format == "html") {
        "reproducr_report.html"
      } else {
        "reproducr_report.md"
      }
    }
    writeLines(content, output_file)
    message("reproducr: report written to '", output_file, "'")
  }

  invisible(content)
}


# ---- rendering helpers ------------------------------------------------------

#' @noRd
.compute_verdict <- function(risks, drift) {
  n_high <- if (!is.null(risks)) sum(risks$risk == "high", na.rm = TRUE) else 0L
  n_medium <- if (!is.null(risks)) sum(risks$risk == "medium", na.rm = TRUE) else 0L
  n_drifted <- if (!is.null(drift)) sum(drift$status == "drifted", na.rm = TRUE) else 0L

  if (is.null(risks) && is.null(drift)) {
    return(list(
      level   = "unknown",
      summary = "Reproducibility status unknown -- run `risk_score()` to assess.",
      emoji   = "?"
    ))
  }
  if (n_high > 0L || n_drifted > 0L) {
    list(
      level = "at_risk",
      summary = sprintf(
        "AT RISK: %d high-severity risk(s)%s detected.",
        n_high,
        if (n_drifted > 0L) sprintf(", %d drifted output(s)", n_drifted) else ""
      ),
      emoji = "x"
    )
  } else if (n_medium > 0L) {
    list(
      level = "caution",
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

#' @noRd
.render_minimal <- function(audit, risks, drift, verdict) {
  n_pkgs <- length(unique(audit$calls$pkg[nchar(audit$calls$pkg) > 0L]))
  n_calls <- nrow(audit$calls)

  lines <- c(
    "# reproducr audit report",
    "",
    sprintf("- **Generated:** %s", format(audit$timestamp, "%Y-%m-%d %H:%M")),
    sprintf("- **R version:** %s", audit$env$r_version),
    sprintf("- **Platform:** %s", audit$env$os),
    sprintf("- **Files scanned:** %d", length(audit$paths)),
    sprintf("- **Packages found:** %d", n_pkgs),
    sprintf("- **Qualified calls:** %d", n_calls),
    sprintf(
      "- **Versions from:** %s",
      if (isTRUE(audit$renv_used)) "renv.lock" else "installed library"
    ),
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
      lines <- c(
        lines,
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
      lines <- c(
        lines,
        sprintf(
          "- **%s** `%s`%s",
          toupper(d$status), d$output,
          if (nchar(trimws(d$note)) > 0L) paste0(" -- ", d$note) else ""
        )
      )
    }
    lines <- c(lines, "")
  }

  paste(lines, collapse = "\n")
}

#' @noRd
.render_academic <- function(audit, risks, verdict) {
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
    n_h <- sum(risks$risk == "high", na.rm = TRUE)
    n_m <- sum(risks$risk == "medium", na.rm = TRUE)
    sprintf(
      paste0(
        "Reproducibility auditing (reproducr) identified %d potential ",
        "concern(s) (%d high, %d medium severity) relating to known ",
        "behavioural changes in package APIs across versions."
      ),
      n_risks, n_h, n_m
    )
  }

  paragraph <- sprintf(
    paste0(
      "All analyses were conducted in R (version %s) on %s. ",
      "The following packages were used: %s. ",
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

#' @noRd
.render_pharma <- function(audit, risks, drift, verdict) {
  # Verdict colour for HTML badge
  verdict_badge <- switch(verdict$level,
    reproducible = "background:#d4edda;color:#155724;padding:3px 10px;border-radius:4px;",
    caution      = "background:#fff3cd;color:#856404;padding:3px 10px;border-radius:4px;",
    at_risk      = "background:#f8d7da;color:#721c24;padding:3px 10px;border-radius:4px;",
    unknown      = "background:#e2e3e5;color:#383d41;padding:3px 10px;border-radius:4px;"
  )

  lines <- c(
    "# Computational Reproducibility QC Document",
    "",
    "| Field | Value |",
    "|---|---|",
    "| Document version | 1.0 |",
    sprintf("| Date | %s |", format(audit$timestamp, "%Y-%m-%d")),
    "| Generated by | reproducr R package |",
    sprintf("| Verdict | **%s** |", verdict$summary),
    "",
    "## 1. Execution environment",
    "",
    "| Property | Value |",
    "|---|---|",
    sprintf("| R version | %s |", audit$env$r_version),
    sprintf("| Platform | %s |", audit$env$r_platform),
    sprintf("| OS | %s |", audit$env$os),
    sprintf("| Locale | %s |", audit$env$locale),
    sprintf("| Timezone | %s |", audit$env$timezone),
    sprintf(
      "| Package versions from | %s |",
      if (isTRUE(audit$renv_used)) "renv.lock" else "installed library"
    ),
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
      lines <- c(lines, sprintf(
        "| %s | %s |", pkgs$pkg[i],
        ifelse(is.na(pkgs$pkg_version[i]), "unknown",
          pkgs$pkg_version[i]
        )
      ))
    }
  } else {
    lines <- c(lines, "_No qualified package calls detected._")
  }
  lines <- c(lines, "")

  lines <- c(lines, "## 4. Risk register", "")
  if (is.null(risks) || nrow(risks) == 0L) {
    lines <- c(lines, "_No risks identified._", "")
  } else {
    lines <- c(
      lines,
      "| # | Call | Severity | File | Check | Description |",
      "|---|---|---|---|---|---|"
    )
    for (i in seq_len(nrow(risks))) {
      r <- risks[i, , drop = FALSE]
      desc_short <- if (nchar(r$description) > 120L) {
        paste0(substr(r$description, 1L, 117L), "...")
      } else {
        r$description
      }
      lines <- c(lines, sprintf(
        "| %d | `%s` | **%s** | %s:%d | %s | %s |",
        i, r$call, toupper(r$risk),
        basename(r$file), r$line,
        r$check,
        gsub("|", "\\|", desc_short, fixed = TRUE)
      ))
    }
    lines <- c(lines, "")
  }

  if (!is.null(drift)) {
    lines <- c(lines, "## 5. Drift assessment", "")
    lines <- c(lines, "| Output | Status | Note |", "|---|---|---|")
    for (i in seq_len(nrow(drift))) {
      d <- drift[i, , drop = FALSE]
      lines <- c(lines, sprintf(
        "| %s | %s | %s |",
        d$output, d$status,
        ifelse(nchar(trimws(d$note)) > 0L, d$note, "")
      ))
    }
    lines <- c(lines, "")
    n_next <- 6L
  } else {
    n_next <- 5L
  }

  lines <- c(
    lines,
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

#' @noRd
.md_to_html <- function(md, title = "reproducr Report") {
  # Use commonmark if available for proper Markdown -> HTML conversion
  if (requireNamespace("commonmark", quietly = TRUE)) {
    body <- paste(commonmark::markdown_html(md, extensions = TRUE),
      collapse = "\n"
    )
  } else {
    message(
      "reproducr: install 'commonmark' for properly rendered HTML tables: ",
      "install.packages('commonmark')"
    )
    # Minimal fallback
    html <- md
    html <- gsub("(?m)^# (.+)$", "<h1>\\1</h1>", html, perl = TRUE)
    html <- gsub("(?m)^## (.+)$", "<h2>\\1</h2>", html, perl = TRUE)
    html <- gsub("(?m)^### (.+)$", "<h3>\\1</h3>", html, perl = TRUE)
    html <- gsub("(?m)^> (.+)$", "<blockquote>\\1</blockquote>", html, perl = TRUE)
    html <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", html, perl = TRUE)
    html <- gsub("`([^`]+)`", "<code>\\1</code>", html, perl = TRUE)
    html <- gsub("(?m)^- (.+)$", "<li>\\1</li>", html, perl = TRUE)
    body <- paste(html, collapse = "\n")
  }

  css <- paste0(
    "body{font-family:system-ui,-apple-system,sans-serif;",
    "max-width:900px;margin:2rem auto;padding:0 2rem;",
    "line-height:1.65;color:#111;} ",
    "h1{font-size:1.7rem;border-bottom:3px solid #0F6E56;",
    "padding-bottom:.5rem;color:#0F6E56;margin-top:2rem;} ",
    "h2{font-size:1.2rem;margin-top:2.5rem;padding-bottom:.3rem;",
    "border-bottom:1px solid #ddd;color:#222;} ",
    "h3{font-size:1rem;color:#444;margin-top:1.5rem;} ",
    "code{background:#f4f4f4;padding:2px 6px;border-radius:3px;",
    "font-size:.88em;font-family:monospace;} ",
    "pre{background:#f4f4f4;padding:1rem;border-radius:6px;",
    "overflow-x:auto;font-size:.88em;} ",
    "blockquote{border-left:4px solid #0F6E56;margin:1rem 0;",
    "padding:.6rem 1.2rem;background:#f0faf5;border-radius:0 6px 6px 0;} ",
    "table{border-collapse:collapse;width:100%;margin:1rem 0;",
    "font-size:.95em;} ",
    "th{background:#0F6E56;color:#fff;padding:.5rem .8rem;",
    "text-align:left;font-weight:600;} ",
    "td{padding:.45rem .8rem;border-bottom:1px solid #e5e5e5;",
    "vertical-align:top;} ",
    "tr:nth-child(even) td{background:#f9f9f9;} ",
    "tr:hover td{background:#f0faf5;} ",
    "li{margin:.3rem 0;} ",
    "strong{color:#111;} ",
    ".verdict-ok{background:#d4edda;color:#155724;padding:3px 10px;",
    "border-radius:4px;font-weight:600;} ",
    ".verdict-warn{background:#fff3cd;color:#856404;padding:3px 10px;",
    "border-radius:4px;font-weight:600;} ",
    ".verdict-risk{background:#f8d7da;color:#721c24;padding:3px 10px;",
    "border-radius:4px;font-weight:600;} ",
    "hr{border:none;border-top:1px solid #eee;margin:2rem 0;}"
  )

  paste0(
    "<!DOCTYPE html>\n<html lang='en'>\n<head>\n",
    "<meta charset='utf-8'>\n",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>\n",
    "<title>", title, "</title>\n",
    "<style>\n", css, "\n</style>\n",
    "</head>\n<body>\n",
    body,
    "\n</body>\n</html>"
  )
}
