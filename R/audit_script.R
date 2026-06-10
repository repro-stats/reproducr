#' Audit an R script for reproducibility risks
#'
#' @description
#' Parses one or more R source files and extracts every qualified
#' `package::function` call, resolving the installed version of each package.
#' The resulting `audit_report` object is the entry point for the rest of the
#' `reproducr` workflow.
#'
#' @param path `character(1)`. Path to a `.R`, `.Rmd`, or `.qmd` file **or**
#'   a directory. When a directory is supplied, all R-ish source files are
#'   scanned recursively, excluding `renv/` and `packrat/` subdirectories.
#'   Defaults to `"."` (the current working directory).
#' @param renv `logical(1)`. If `TRUE` and a `renv.lock` file exists in the
#'   current working directory, package versions are read from the lockfile
#'   rather than the currently installed library. Useful for stable version
#'   reporting in CI environments. Default `TRUE`.
#' @param verbose `logical(1)`. Whether to print progress messages.
#'   Default `TRUE`.
#'
#' @return An S3 object of class `"audit_report"`, a list containing:
#' \describe{
#'   \item{`calls`}{A `data.frame` with one row per detected `pkg::fn` call,
#'     columns `file`, `line`, `pkg`, `fn`, `pkg_version`.}
#'   \item{`env`}{A list with R version, platform, OS, locale, and timezone.}
#'   \item{`renv_used`}{`logical` -- were versions sourced from a lockfile?}
#'   \item{`timestamp`}{`POSIXct` timestamp of when the audit was run.}
#'   \item{`paths`}{Character vector of files that were scanned.}
#' }
#'
#' @section Detection approach:
#' `audit_script()` uses regular-expression matching on source text to extract
#' qualified calls of the form `pkg::fn` or `pkg:::fn`. It intentionally skips
#' comment lines (lines beginning with `#`, after trimming whitespace). For more
#' robust analysis, tools that operate on the parse tree (e.g. `lintr`) should
#' be used alongside `reproducr`.
#'
#' @section What counts as a qualifying call?:
#' Only *qualified* calls -- those using `::` or `:::` -- are detected.
#' Unqualified calls (e.g. `filter(df, x > 0)` without `dplyr::`) are not
#' detected because he package cannot be determined unambiguously from source
#' text alone. This is by design: qualifying calls is also a reproducibility
#' best practice.
#'
#' @seealso [reproducr::risk_score()] to check detected calls against the
#' breaking-changes database; [reproducr::repro_report()] to render the
#' full audit; [reproducr::certify()] to lock a set of outputs as a baseline.
#'
#' @examples
#' # Write a temporary script to audit
#' script <- tempfile(fileext = ".R")
#' writeLines(c(
#'   "set.seed(237)",
#'   "x <- dplyr::filter(mtcars, cyl == 4)",
#'   "y <- dplyr::summarise(x, mean_mpg = mean(mpg))",
#'   "z <- stats::rnorm(nrow(y))"
#' ), script)
#'
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' print(report)
#'
#' # See the detected calls as a data frame
#' report$calls
#'
#' @export
audit_script <- function(path = ".", renv = TRUE, verbose = TRUE) {
  stopifnot(is.character(path), length(path) == 1L)
  stopifnot(is.logical(renv), length(renv) == 1L)
  stopifnot(is.logical(verbose), length(verbose) == 1L)

  path <- normalizePath(path, mustWork = TRUE)

  files <- .collect_r_files(path)
  if (length(files) == 0L) {
    stop(
      "No .R, .Rmd, or .qmd files found at: ", path, "\n",
      "  If this is a directory, ensure it contains R source files."
    )
  }

  if (verbose) {
    message(sprintf(
      "reproducr: scanning %d file(s) for qualified calls...",
      length(files)
    ))
  }

  pkg_versions <- .resolve_pkg_versions(use_renv = renv, verbose = verbose)

  all_calls <- do.call(
    rbind,
    c(
      lapply(files, .extract_calls, pkg_versions = pkg_versions),
      list(NULL)
    ) # ensures rbind always gets at least one arg
  )

  if (is.null(all_calls) || nrow(all_calls) == 0L) {
    if (verbose) {
      message(
        "reproducr: no qualified pkg::fn calls detected. ",
        "Consider using explicit namespacing (pkg::fn) in your scripts."
      )
    }
    all_calls <- .empty_calls_df()
  }

  env_info <- list(
    r_version  = paste(R.version$major, R.version$minor, sep = "."),
    r_platform = R.version$platform,
    os         = .get_os(),
    locale     = Sys.getlocale("LC_ALL"),
    timezone   = Sys.timezone()
  )

  structure(
    list(
      calls     = all_calls,
      env       = env_info,
      renv_used = isTRUE(renv) && .renv_lock_exists(),
      timestamp = Sys.time(),
      paths     = files
    ),
    class = "audit_report"
  )
}

# ---- S3 methods -------------------------------------------------------------

#' @rdname audit_script
#' @param x An `audit_report` object (for `print`).
#' @param ... Additional arguments (currently unused).
#' @export
print.audit_report <- function(x, ...) {
  n_files <- length(x$paths)
  n_pkgs <- length(unique(x$calls$pkg[!is.na(x$calls$pkg)]))
  n_calls <- nrow(x$calls)
  src <- if (isTRUE(x$renv_used)) "renv.lock" else "installed library"

  cat(
    "\n",
    sprintf(
      "-- reproducr audit report [%s] --\n",
      format(x$timestamp, "%Y-%m-%d %H:%M")
    ),
    "\n",
    sprintf("  %-18s %s\n", "Files scanned:", n_files),
    sprintf("  %-18s %s\n", "Packages found:", n_pkgs),
    sprintf("  %-18s %s\n", "Calls detected:", n_calls),
    sprintf("  %-18s %s\n", "R version:", x$env$r_version),
    sprintf("  %-18s %s\n", "Platform:", x$env$os),
    sprintf("  %-18s %s\n", "Versions from:", src),
    "\n",
    "  Next step: risks <- risk_score(report)\n",
    "\n",
    sep = ""
  )
  invisible(x)
}

#' @rdname audit_script
#' @param object An `audit_report` object (for `summary`).
#' @export
summary.audit_report <- function(object, ...) {
  calls_per_pkg <- if (nrow(object$calls) > 0L) {
    tapply(object$calls$fn, object$calls$pkg, length)
  } else {
    integer(0)
  }
  list(
    n_files       = length(object$paths),
    n_calls       = nrow(object$calls),
    n_pkgs        = length(calls_per_pkg),
    calls_per_pkg = calls_per_pkg,
    env           = object$env,
    renv_used     = object$renv_used,
    timestamp     = object$timestamp
  )
}

# ---- internal ---------------------------------------------------------------

.empty_calls_df <- function() {
  data.frame(
    file = character(0),
    line = integer(0),
    pkg = character(0),
    fn = character(0),
    pkg_version = character(0),
    stringsAsFactors = FALSE
  )
}

.extract_calls <- function(file, pkg_versions) {
  lines <- tryCatch(
    readLines(file, warn = FALSE, encoding = "UTF-8"),
    error = function(e) character(0)
  )
  if (length(lines) == 0L) {
    return(NULL)
  }

  # For Rmd/qmd files, only parse lines inside fenced R code blocks.
  # Prose lines (including inline `pkg::fn()` backtick code) are skipped
  # to avoid false positives from documentation examples.
  is_rmd <- grepl("\\.(Rmd|rmd|qmd)$", file, perl = TRUE)
  if (is_rmd) {
    in_chunk <- FALSE
    keep <- logical(length(lines))
    for (i in seq_along(lines)) {
      ln <- lines[[i]]
      if (!in_chunk && grepl("^```\\{[rR]", ln, perl = TRUE)) {
        in_chunk <- TRUE
        next # skip the opening fence line itself
      }
      if (in_chunk && grepl("^```\\s*$", ln, perl = TRUE)) {
        in_chunk <- FALSE
        next # skip the closing fence line itself
      }
      keep[[i]] <- in_chunk
    }
    lines <- ifelse(keep, lines, "")
  }

  # Pattern: pkg::fn or pkg:::fn
  # pkg: starts with letter, followed by letters/digits/dots
  # fn:  starts with letter, followed by letters/digits/dots/underscores
  pattern <- "([a-zA-Z][a-zA-Z0-9.]*)::{1,3}([a-zA-Z.][a-zA-Z0-9._]*)"

  results <- vector("list", length(lines))
  n_results <- 0L

  for (i in seq_along(lines)) {
    ln <- lines[[i]]

    # Skip pure comment lines (possibly indented)
    if (grepl("^\\s*#", ln, perl = TRUE)) next

    # Strip inline comments before matching (simple approach: split on " #")
    # This avoids matching calls mentioned only in comments
    ln_stripped <- sub("\\s#.*$", "", ln, perl = TRUE)

    m <- gregexpr(pattern, ln_stripped, perl = TRUE)
    matched <- regmatches(ln_stripped, m)[[1L]]
    if (length(matched) == 0L) next

    for (call_str in matched) {
      parts <- strsplit(call_str, ":{2,3}", perl = TRUE)[[1L]]
      if (length(parts) != 2L) next

      pkg <- parts[[1L]]
      fn <- parts[[2L]]

      ver <- pkg_versions[[pkg]]
      if (is.null(ver)) ver <- NA_character_

      n_results <- n_results + 1L
      results[[n_results]] <- data.frame(
        file = file,
        line = i,
        pkg = pkg,
        fn = fn,
        pkg_version = as.character(ver),
        stringsAsFactors = FALSE
      )
    }
  }

  if (n_results == 0L) {
    return(NULL)
  }
  do.call(rbind, results[seq_len(n_results)])
}
