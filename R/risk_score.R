#' Score function calls for reproducibility risk
#'
#' @description
#' Takes an `audit_report` and checks every detected `pkg::fn` call against
#' three independent checks:
#'
#' - **`"changelog"`** — matches against a curated database of known breaking
#'   changes in popular CRAN packages, flagging calls where the installed
#'   version falls in a known-risky version window.
#' - **`"seed_check"`** — flags stochastic functions (`rnorm`, `sample`, etc.)
#'   where no `set.seed()` appears within 50 lines above the call.
#' - **`"locale_check"`** — flags functions whose output is locale-sensitive
#'   (`sort()`, `format()`, `tolower()`, etc.).
#'
#' @param audit An `audit_report` object returned by [audit_script()].
#' @param methods `character`. Which checks to run. Any combination of
#'   `"changelog"`, `"seed_check"`, `"locale_check"`. Default: all three.
#' @param min_risk `character(1)`. Minimum risk level to include in the output.
#'   One of `"low"` (show all), `"medium"`, or `"high"`. Default `"low"`.
#'
#' @return A `data.frame` of class `c("risk_report", "data.frame")` with one
#'   row per flagged call. Columns:
#'   \describe{
#'     \item{`file`}{Source file path.}
#'     \item{`line`}{Line number of the call.}
#'     \item{`call`}{The `pkg::fn` string.}
#'     \item{`pkg_version`}{Installed or renv-locked version.}
#'     \item{`risk`}{`"high"`, `"medium"`, or `"low"`.}
#'     \item{`check`}{Which check flagged it: `"changelog"`, `"seed_check"`,
#'       or `"locale_check"`.}
#'     \item{`description`}{Plain-English explanation of the risk.}
#'     \item{`reference`}{URL to the relevant changelog or documentation.}
#'   }
#'   Rows are ordered by risk severity (high first), then by file and line.
#'   If no risks are found, an empty data frame with the same columns is
#'   returned.
#'
#' @section Version windows:
#' The `"changelog"` check uses a half-open version window `(from_ver, to_ver]`:
#' a call is flagged only if the installed version is *greater than*
#' `from_ver` *and* *at most* `to_ver`. This means the risk is scoped to
#' versions where the breaking change is known to apply.
#'
#' @seealso [audit_script()] to generate the input; [repro_report()] to render
#'   the results; the `reproducr` GitHub repository to contribute new database
#'   entries.
#'
#' @examples
#' script <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "x <- dplyr::summarise(mtcars, n = dplyr::n())",
#'   "y <- stats::rnorm(100)",
#'   "z <- base::sort(letters)"
#' ), script)
#'
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' risks  <- risk_score(report)
#' print(risks)
#'
#' # High-severity items only
#' risk_score(report, min_risk = "high")
#'
#' # Only the changelog check
#' risk_score(report, methods = "changelog")
#'
#' @export
risk_score <- function(audit,
                       methods  = c("changelog", "seed_check", "locale_check"),
                       min_risk = "low") {

  if (!inherits(audit, "audit_report")) {
    stop("`audit` must be an `audit_report` object from `audit_script()`.",
         call. = FALSE)
  }
  min_risk <- match.arg(min_risk, c("low", "medium", "high"))
  methods  <- match.arg(methods,
                        c("changelog", "seed_check", "locale_check"),
                        several.ok = TRUE)

  min_int  <- .risk_int(min_risk)
  results  <- list()

  # ---------------------------------------------------------------------- 1.
  if ("changelog" %in% methods && nrow(audit$calls) > 0L) {
    for (i in seq_len(nrow(audit$calls))) {
      row     <- audit$calls[i, , drop = FALSE]
      key     <- paste0(row$pkg, "::", row$fn)
      entries <- .get_breaking_changes(key)
      if (is.null(entries)) next

      inst_ver <- row$pkg_version
      if (is.na(inst_ver)) next

      for (entry in entries) {
        if (!.version_in_window(inst_ver, entry$from_version, entry$to_version)) next

        entry_int <- .risk_int(entry$risk)
        if (is.na(entry_int) || entry_int < min_int) next

        results[[length(results) + 1L]] <- data.frame(
          file        = row$file,
          line        = row$line,
          call        = key,
          pkg_version = inst_ver,
          risk        = entry$risk,
          check       = "changelog",
          description = entry$description,
          reference   = entry$reference,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # ---------------------------------------------------------------------- 2.
  if ("seed_check" %in% methods && .risk_int("medium") >= min_int) {
    stochastic_keys <- c(
      "stats::sample",  "stats::runif",   "stats::rnorm",
      "stats::rbinom",  "stats::rpois",   "stats::rexp",
      "stats::rgamma",  "stats::rbeta",   "stats::rcauchy",
      "stats::rchisq",  "stats::rf",      "stats::rt",
      "stats::rgeom",   "stats::rhyper",  "stats::rnbinom",
      "stats::rweibull","base::sample",   "base::sample.int"
    )

    if (nrow(audit$calls) > 0L) {
      call_keys  <- paste0(audit$calls$pkg, "::", audit$calls$fn)
      stoch_rows <- audit$calls[call_keys %in% stochastic_keys, , drop = FALSE]

      if (nrow(stoch_rows) > 0L) {
        # Cache file contents to avoid re-reading the same file repeatedly
        file_cache <- list()

        for (i in seq_len(nrow(stoch_rows))) {
          row  <- stoch_rows[i, , drop = FALSE]
          fkey <- row$file

          if (is.null(file_cache[[fkey]])) {
            file_cache[[fkey]] <- tryCatch(
              readLines(fkey, warn = FALSE),
              error = function(e) character(0)
            )
          }

          file_lines   <- file_cache[[fkey]]
          win_start    <- max(1L, row$line - 50L)
          window       <- file_lines[seq(win_start, row$line)]
          has_seed     <- any(grepl("set\\.seed\\s*\\(", window, perl = TRUE))

          if (!has_seed) {
            results[[length(results) + 1L]] <- data.frame(
              file        = row$file,
              line        = row$line,
              call        = paste0(row$pkg, "::", row$fn),
              pkg_version = row$pkg_version,
              risk        = "medium",
              check       = "seed_check",
              description = sprintf(
                paste0("%s() is stochastic but no set.seed() was found in the ",
                       "50 lines above this call (line %d). ",
                       "Output will differ across runs without a fixed seed."),
                row$fn, row$line
              ),
              reference   = paste0(
                "https://stat.ethz.ch/R-manual/R-devel/library/base/",
                "html/Random.html"
              ),
              stringsAsFactors = FALSE
            )
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------- 3.
  if ("locale_check" %in% methods && .risk_int("low") >= min_int) {
    locale_keys <- c(
      "base::sort",    "base::order",   "base::format",
      "base::toupper", "base::tolower", "base::strftime",
      "base::as.Date", "base::sprintf"
    )

    if (nrow(audit$calls) > 0L) {
      call_keys    <- paste0(audit$calls$pkg, "::", audit$calls$fn)
      locale_rows  <- audit$calls[call_keys %in% locale_keys, , drop = FALSE]
      current_loc  <- Sys.getlocale("LC_COLLATE")

      for (i in seq_len(nrow(locale_rows))) {
        row <- locale_rows[i, , drop = FALSE]
        results[[length(results) + 1L]] <- data.frame(
          file        = row$file,
          line        = row$line,
          call        = paste0(row$pkg, "::", row$fn),
          pkg_version = row$pkg_version,
          risk        = "low",
          check       = "locale_check",
          description = sprintf(
            paste0("%s() output is locale-sensitive. Current locale: %s. ",
                   "Results may differ on machines with different LC_COLLATE ",
                   "or LC_TIME settings."),
            row$fn, current_loc
          ),
          reference   = paste0(
            "https://stat.ethz.ch/R-manual/R-devel/library/base/",
            "html/locales.html"
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # ---------------------------------------------------------------------- build output
  if (length(results) == 0L) {
    out <- .empty_risk_df()
  } else {
    out          <- do.call(rbind, results)
    out$.risk_ord <- .risk_int(out$risk)
    out          <- out[order(-out$.risk_ord, out$file, out$line), ]
    out$.risk_ord <- NULL
    row.names(out) <- NULL
  }

  class(out) <- c("risk_report", "data.frame")
  out
}

# ---- S3 methods -------------------------------------------------------------

#' @export
print.risk_report <- function(x, ...) {
  if (nrow(x) == 0L) {
    cat("\n-- reproducr risk score --\n\n",
        "  No risks detected. All checks passed.\n\n", sep = "")
    return(invisible(x))
  }

  n_high   <- sum(x$risk == "high",   na.rm = TRUE)
  n_medium <- sum(x$risk == "medium", na.rm = TRUE)
  n_low    <- sum(x$risk == "low",    na.rm = TRUE)

  cat(
    "\n-- reproducr risk score --\n\n",
    sprintf("  %-10s %d\n", "HIGH:",   n_high),
    sprintf("  %-10s %d\n", "MEDIUM:", n_medium),
    sprintf("  %-10s %d\n", "LOW:",    n_low),
    "\n",
    sep = ""
  )

  for (i in seq_len(nrow(x))) {
    r   <- x[i, , drop = FALSE]
    pfx <- switch(r$risk,
      high   = "[HIGH]   ",
      medium = "[MEDIUM] ",
      low    = "[LOW]    "
    )
    cat(pfx, r$call,
        sprintf(" (line %d in %s)\n", r$line, basename(r$file)))
    cat("         Check    : ", r$check, "\n", sep = "")
    cat("         Details  : ",
        .wrap_text(r$description, width = 65L, indent = "                    "),
        "\n", sep = "")
    cat("         Reference: ", r$reference, "\n\n", sep = "")
  }

  invisible(x)
}

#' @export
as.data.frame.risk_report <- function(x, ...) {
  class(x) <- "data.frame"
  x
}

# ---- internal ---------------------------------------------------------------

.empty_risk_df <- function() {
  data.frame(
    file        = character(0),
    line        = integer(0),
    call        = character(0),
    pkg_version = character(0),
    risk        = character(0),
    check       = character(0),
    description = character(0),
    reference   = character(0),
    stringsAsFactors = FALSE
  )
}
