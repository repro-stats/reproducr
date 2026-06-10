#' Check whether breaking-changes database entries are stale
#'
#' @description
#' Compares the `to_version` ceiling and `from_version` floor of each entry
#' in the breaking-changes database against the current version of that
#' package on CRAN. Two types of staleness are detected:
#'
#' - **`stale_ceiling`** -- the package has released a new version above
#'   the `to_version` ceiling. The window may need extending.
#' - **`stale_floor`** -- the current CRAN version is so far ahead of
#'   `from_version` that the window captures users who are already well
#'   past the breaking-change transition. The entry may need closing or
#'   the `from_version` floor raising.
#'
#' This function is primarily intended for use by `reproducr` maintainers
#' and contributors. It is also run as a scheduled GitHub Actions workflow
#' on the `reproducr` repository to automatically open issues when staleness
#' is detected.
#'
#' @param packages `character` or `NULL`. Package names to check. If `NULL`
#'   (the default), all packages tracked in the breaking-changes database are
#'   checked.
#' @param verbose `logical(1)`. Print progress messages. Default `TRUE`.
#' @param source `character(1)`. Where to resolve current package versions.
#'   One of:
#'   \describe{
#'     \item{`"cran"`}{Query the CRAN package database via
#'       `utils::available.packages()`. Requires an internet connection.}
#'     \item{`"installed"`}{Use locally installed versions via
#'       `utils::installed.packages()`. Fast and offline, but only reflects
#'       what is installed on the current machine.}
#'   }
#'   Default `"cran"`.
#' @param from_version_major_threshold `integer(1)` or `Inf`. Number of full
#'   major versions the current CRAN release must be *ahead* of `from_version`
#'   before the entry is flagged as having a stale floor. Set to `Inf` to
#'   disable this check. Default `1L`.
#'
#' @return A `data.frame` of class `c("staleness_report", "data.frame")`
#'   with one row per database entry. Columns:
#'   \describe{
#'     \item{`key`}{The `pkg::fn` key.}
#'     \item{`pkg`}{Package name.}
#'     \item{`fn`}{Function name.}
#'     \item{`from_version`}{The floor version currently in the database.}
#'     \item{`to_version`}{The ceiling version currently in the database.}
#'     \item{`current_version`}{The current version on CRAN or installed.}
#'     \item{`status`}{One of `"ok"`, `"stale_ceiling"`, `"stale_floor"`,
#'       or `"unknown"`.}
#'     \item{`gap`}{Description of the version gap. `NA` when status is
#'       `"ok"` or `"unknown"`.}
#'   }
#'   Rows are ordered: stale_ceiling first, stale_floor second, then ok,
#'   then unknown.
#'
#' @seealso
#' [reproducr::risk_score()] which uses the database at runtime;
#' `vignette("contributing-to-the-database")` for the database schema and
#' version window design principles.
#'
#' @examples
#' \dontrun{
#' # Check all tracked packages against CRAN
#' report <- check_db_staleness()
#' print(report)
#'
#' # Check specific packages only
#' check_db_staleness(packages = c("dplyr", "tidyr"))
#'
#' # Offline check using installed versions
#' check_db_staleness(source = "installed")
#'
#' # Filter to stale entries only
#' report <- check_db_staleness()
#' report[report$status != "ok", ]
#' }
#'
#' @export
check_db_staleness <- function(packages = NULL,
                               verbose = TRUE,
                               source = "cran",
                               from_version_major_threshold = 1L) {
  source <- match.arg(source, c("cran", "installed"))
  # Accept Inf to disable floor check; otherwise coerce to integer
  from_version_major_threshold <- if (is.infinite(from_version_major_threshold)) {
    Inf
  } else {
    as.integer(from_version_major_threshold)
  }

  # Collect all unique packages tracked in the database
  all_keys <- .list_db_keys()
  all_pkgs <- unique(vapply(
    strsplit(all_keys, "::"),
    `[[`, 1L,
    FUN.VALUE = character(1L)
  ))

  # Filter to requested packages
  if (!is.null(packages)) {
    unknown_pkgs <- setdiff(packages, all_pkgs)
    if (length(unknown_pkgs) > 0L) {
      warning(
        "Package(s) not found in database: ",
        paste(unknown_pkgs, collapse = ", "),
        call. = FALSE
      )
    }
    all_pkgs <- intersect(packages, all_pkgs)
    if (length(all_pkgs) == 0L) {
      stop("No matching packages found in the database.", call. = FALSE)
    }
  }

  # Resolve current versions
  if (verbose) {
    message(sprintf(
      "reproducr: checking %d package(s) against %s...",
      length(all_pkgs), source
    ))
  }

  current_versions <- .resolve_current_versions(all_pkgs, source, verbose)

  # Build results
  results <- list()

  for (key in all_keys) {
    parts <- strsplit(key, "::")[[1L]]
    pkg <- parts[[1L]]
    fn <- parts[[2L]]

    if (!is.null(packages) && !pkg %in% packages) next

    entries <- .get_breaking_changes(key)
    if (is.null(entries)) next

    curr_ver <- current_versions[[pkg]]

    for (entry in entries) {
      # Skip intentionally closed entries
      if (isTRUE(entry$closed)) next

      to_ver <- entry$to_version
      from_ver <- entry$from_version

      # ---- to_version (ceiling) staleness ----------------------------------
      ceiling_status <- .assess_staleness(curr_ver, to_ver)

      # ---- from_version (floor) staleness ----------------------------------
      floor_status <- .assess_floor_staleness(
        curr_ver, from_ver, from_version_major_threshold
      )

      # Combine: ceiling staleness takes precedence
      status <- if (ceiling_status == "stale") {
        "stale_ceiling"
      } else if (floor_status == "stale") {
        "stale_floor"
      } else if (ceiling_status == "unknown") {
        "unknown"
      } else {
        "ok"
      }

      gap <- if (status == "stale_ceiling" && !is.na(curr_ver)) {
        sprintf("to_version %s -> current %s", to_ver, curr_ver)
      } else if (status == "stale_floor" && !is.na(curr_ver)) {
        sprintf(
          "from_version %s << current %s (>= %d major version(s) behind)",
          from_ver, curr_ver, from_version_major_threshold
        )
      } else {
        NA_character_
      }

      results[[length(results) + 1L]] <- data.frame(
        key = key,
        pkg = pkg,
        fn = fn,
        from_version = from_ver,
        to_version = to_ver,
        current_version = if (is.na(curr_ver)) NA_character_ else curr_ver,
        status = status,
        gap = gap,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(results) == 0L) {
    out <- .empty_staleness_df()
  } else {
    out <- do.call(rbind, results)
    status_ord <- c(
      stale_ceiling = 1L, stale_floor = 2L,
      ok = 3L, unknown = 4L
    )
    out$.ord <- status_ord[out$status]
    out <- out[order(out$.ord, out$pkg, out$fn), ]
    out$.ord <- NULL
    row.names(out) <- NULL
  }

  class(out) <- c("staleness_report", "data.frame")

  n_stale_ceiling <- sum(out$status == "stale_ceiling", na.rm = TRUE)
  n_stale_floor <- sum(out$status == "stale_floor", na.rm = TRUE)
  n_ok <- sum(out$status == "ok", na.rm = TRUE)
  n_unknown <- sum(out$status == "unknown", na.rm = TRUE)

  if (verbose) {
    message(sprintf(
      "reproducr: %d stale ceiling, %d stale floor, %d ok, %d unknown",
      n_stale_ceiling, n_stale_floor, n_ok, n_unknown
    ))
  }

  if (n_stale_ceiling > 0L) {
    stale_c <- out[out$status == "stale_ceiling", , drop = FALSE]
    message(
      "\nStale ceiling entries (to_version below current release):\n",
      paste(sprintf("  %s  [%s]", stale_c$key, stale_c$gap),
        collapse = "\n"
      )
    )
  }

  if (n_stale_floor > 0L) {
    stale_f <- out[out$status == "stale_floor", , drop = FALSE]
    message(
      "\nStale floor entries (from_version too old -- window too wide):\n",
      paste(sprintf("  %s  [%s]", stale_f$key, stale_f$gap),
        collapse = "\n"
      )
    )
  }

  invisible(out)
}

# ---- S3 methods -------------------------------------------------------------

#' @export
print.staleness_report <- function(x, ...) {
  n_stale_ceiling <- sum(x$status == "stale_ceiling", na.rm = TRUE)
  n_stale_floor <- sum(x$status == "stale_floor", na.rm = TRUE)
  n_ok <- sum(x$status == "ok", na.rm = TRUE)
  n_unknown <- sum(x$status == "unknown", na.rm = TRUE)

  cat("\n-- reproducr database staleness report --\n\n")
  cat(sprintf("  %-22s %d\n", "STALE CEILING:", n_stale_ceiling))
  cat(sprintf("  %-22s %d\n", "STALE FLOOR:", n_stale_floor))
  cat(sprintf("  %-22s %d\n", "OK:", n_ok))
  cat(sprintf("  %-22s %d\n", "UNKNOWN:", n_unknown))
  cat("\n")

  if (n_stale_ceiling > 0L) {
    stale <- x[x$status == "stale_ceiling", , drop = FALSE]
    cat("Stale ceiling entries (to_version below current release):\n\n")
    for (i in seq_len(nrow(stale))) {
      cat(sprintf(
        "  [STALE CEILING] %s\n    to_version=%s | current=%s\n    Action: extend to_version or close entry.\n\n",
        stale$key[i], stale$to_version[i], stale$current_version[i]
      ))
    }
  }

  if (n_stale_floor > 0L) {
    stale <- x[x$status == "stale_floor", , drop = FALSE]
    cat("Stale floor entries (from_version too old -- window too wide):\n\n")
    for (i in seq_len(nrow(stale))) {
      cat(sprintf(
        "  [STALE FLOOR] %s\n    from_version=%s | current=%s\n    Action: raise from_version or close entry.\n\n",
        stale$key[i], stale$from_version[i], stale$current_version[i]
      ))
    }
  }

  if (n_stale_ceiling == 0L && n_stale_floor == 0L) {
    cat("  All entries are current.\n\n")
  }

  invisible(x)
}

# ---- internal helpers -------------------------------------------------------

#' Resolve current package versions from CRAN or installed library
#' @noRd
.resolve_current_versions <- function(pkgs, source, verbose) {
  versions <- setNames(
    rep(NA_character_, length(pkgs)),
    pkgs
  )

  if (source == "cran") {
    tryCatch(
      {
        avail <- utils::available.packages(
          repos = getOption("repos", "https://cloud.r-project.org")
        )
        for (pkg in pkgs) {
          if (pkg %in% rownames(avail)) {
            versions[[pkg]] <- avail[pkg, "Version"]
          } else if (pkg %in% c(
            "base", "stats", "utils",
            "tools", "methods"
          )) {
            versions[[pkg]] <- paste(R.version$major, R.version$minor,
              sep = "."
            )
          }
        }
      },
      error = function(e) {
        if (verbose) {
          message(
            "reproducr: CRAN query failed, falling back to installed library"
          )
        }
        inst <- utils::installed.packages()[
          , c("Package", "Version"),
          drop = FALSE
        ]
        for (pkg in pkgs) {
          if (pkg %in% inst[, "Package"]) {
            idx <- which(inst[, "Package"] == pkg)[[1L]]
            versions[[pkg]] <<- inst[idx, "Version"]
          }
        }
      }
    )
  } else {
    inst <- utils::installed.packages()[
      , c("Package", "Version"),
      drop = FALSE
    ]
    for (pkg in pkgs) {
      if (pkg %in% inst[, "Package"]) {
        idx <- which(inst[, "Package"] == pkg)[[1L]]
        versions[[pkg]] <- inst[idx, "Version"]
      } else if (pkg %in% c("base", "stats", "utils", "tools", "methods")) {
        versions[[pkg]] <- paste(R.version$major, R.version$minor, sep = ".")
      }
    }
  }

  versions
}

#' Assess to_version (ceiling) staleness
#' @noRd
.assess_staleness <- function(current_ver, to_ver) {
  if (is.na(current_ver)) {
    return("unknown")
  }
  tryCatch(
    {
      cv <- package_version(as.character(current_ver))
      tv <- package_version(as.character(to_ver))
      if (cv > tv) "stale" else "ok"
    },
    error = function(e) "unknown"
  )
}

#' Assess from_version (floor) staleness
#'
#' Returns "stale" when current_ver is >= threshold major versions ahead of
#' from_ver, indicating the window may be too wide.
#' @noRd
.assess_floor_staleness <- function(current_ver, from_ver, threshold) {
  if (is.na(current_ver)) {
    return("ok")
  }
  if (is.infinite(threshold)) {
    return("ok")
  }
  tryCatch(
    {
      cv <- package_version(as.character(current_ver))
      fv <- package_version(as.character(from_ver))
      major_gap <- unclass(cv)[[1L]][1L] - unclass(fv)[[1L]][1L]
      if (!is.na(major_gap) && major_gap >= threshold) "stale" else "ok"
    },
    error = function(e) "unknown"
  )
}

#' Empty staleness data frame with correct columns
#' @noRd
.empty_staleness_df <- function() {
  data.frame(
    key = character(0),
    pkg = character(0),
    fn = character(0),
    from_version = character(0),
    to_version = character(0),
    current_version = character(0),
    status = character(0),
    gap = character(0),
    stringsAsFactors = FALSE
  )
}
