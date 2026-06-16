#' Certify analytical outputs as a reproducibility baseline
#'
#' @description
#' Hashes a named list of R objects (model coefficients, summary statistics,
#' key scalars, data frames) and saves them alongside full environment metadata
#' to a local certification file (`.reproducr.rds` by default). Later runs
#' can call [check_drift()] to verify that results have not changed.
#'
#' Think of `certify()` as a "signed receipt" for a completed analysis run.
#'
#' @param outputs A fully named list of R objects to certify. Each element is
#'   hashed using SHA-256 (or a base-R fallback if `digest` is not available).
#'   Common choices: `coef(model)`, `summary(model)$r.squared`, a results
#'   `data.frame`, or any key scalar.
#' @param tag `character(1)`. A human-readable label for this certification,
#'   e.g. `"submission-v1"` or `"pre-review"`. Tags must be unique within a
#'   certification file; passing a duplicate tag overwrites the existing record
#'   with a warning.
#' @param script `character(1)` or `NULL`. Path to the script that produced
#'   these outputs. Used for documentation in the certification record only;
#'   not validated. Default `NULL`.
#' @param file `character(1)`. Base path for the certification store. The
#'   actual file written is `paste0(file, ".rds")`. Default `".reproducr"`,
#'   which writes `.reproducr.rds` in the current working directory.
#'   Commit this file to version control.
#'
#' @return Invisibly returns the certification record (a list). Prints a
#'   one-line summary to the console.
#'
#' @section Certification store:
#' All certifications for a project are accumulated in a single `.reproducr.rds`
#' file. You can have multiple tags representing different stages (e.g. before
#' and after peer review). Use [list_certs()] to inspect stored tags.
#'
#' @section Version control:
#' Commit `.reproducr.rds` to your project's version control repository.
#' This makes the certification auditable and shareable with collaborators.
#'
#' @seealso [check_drift()] to compare current outputs against a baseline;
#'   [list_certs()] to inspect stored certifications.
#'
#' @examples
#' model <- lm(mpg ~ wt, data = mtcars)
#'
#' cert_file <- tempfile()
#'
#' certify(
#'   outputs = list(
#'     coefs     = coef(model),
#'     r_squared = summary(model)$r.squared,
#'     n_obs     = nrow(mtcars)
#'   ),
#'   tag = "baseline-v1",
#'   script = "analysis.R",
#'   file = cert_file
#' )
#'
#' # See what is stored
#' list_certs(file = cert_file)
#'
#' @export
certify <- function(outputs, tag, script = NULL, file = ".reproducr") {
  # --- input validation -------------------------------------------------------
  if (!is.list(outputs) || length(outputs) == 0L) {
    stop("`outputs` must be a non-empty list.", call. = FALSE)
  }
  nms <- names(outputs)
  if (is.null(nms) || any(nchar(trimws(nms)) == 0L)) {
    stop("`outputs` must be a fully named list with no empty names.", call. = FALSE) # nolint
  }
  if (missing(tag) || !is.character(tag) || length(tag) != 1L || nchar(trimws(tag)) == 0L) { # nolint
    stop("`tag` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.null(script) && (!is.character(script) || length(script) != 1L)) {
    stop("`script` must be NULL or a single character string.", call. = FALSE)
  }

  # --- load existing certs and check for duplicate tag -----------------------
  certs <- .load_certs(file)
  if (tag %in% names(certs)) {
    warning(sprintf("Tag '%s' already exists in '%s'. Overwriting.", tag, file),
      call. = FALSE
    )
  }

  # --- hash each output -------------------------------------------------------
  hashes <- lapply(outputs, function(obj) {
    tryCatch(
      .hash_object(obj),
      error = function(e) {
        warning("Could not hash output '", deparse(substitute(obj)), "': ",
          conditionMessage(e),
          call. = FALSE
        )
        NA_character_
      }
    )
  })

  # --- build record -----------------------------------------------------------
  record <- list(
    tag = tag,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    script = script,
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    r_platform = R.version$platform,
    os = .get_os(),
    hashes = hashes,
    values = outputs, # stored for cross-platform numeric tolerance comparison
    n_outputs = length(outputs),
    output_names = names(outputs),
    output_classes = vapply(
      outputs,
      function(x) paste(class(x), collapse = ", "),
      character(1L)
    ),
    output_dims = vapply(outputs, function(x) {
      if (is.data.frame(x)) {
        return(paste(dim(x), collapse = " x "))
      }
      if (is.matrix(x)) {
        return(paste(dim(x), collapse = " x "))
      }
      if (is.vector(x)) {
        return(as.character(length(x)))
      }
      NA_character_
    }, character(1L))
  )

  certs[[tag]] <- record
  .save_certs(certs, file)

  message(sprintf(
    "reproducr: certified %d output(s) [%s] under tag '%s'",
    length(outputs), format(Sys.time(), "%Y-%m-%d"), tag
  ))
  invisible(record)
}


#' Check analytical outputs for drift against a certified baseline
#'
#' @description
#' Re-hashes a set of named R objects and compares them against a previously
#' stored certification. Reports which outputs are unchanged (`"ok"`), have
#' changed (`"drifted"`), are present in the baseline but not supplied
#' (`"missing"`), or are new outputs not in the baseline (`"new"`).
#'
#' For numeric outputs whose hashes differ, `check_drift()` falls back to an
#' element-wise absolute difference comparison using `tolerance`. This makes
#' drift detection robust to benign floating-point variation across platforms
#' (e.g. Linux CI vs macOS local), while still catching genuine numerical
#' changes. The fallback requires that the certification was created with
#' `certify()` version >= 0.2.0, which stores raw values alongside hashes.
#'
#' @param outputs A fully named list of current R objects -- the same names used
#'   in the [certify()] call being compared against.
#' @param against `character(1)`. The certification tag to compare against.
#'   Use `"latest"` (the default) to automatically select the most recently
#'   added certification.
#' @param file `character(1)`. Base path of the certification store.
#'   Default `".reproducr"` (reads `.reproducr.rds`).
#' @param tolerance `numeric(1)`. Numeric tolerance for element-wise comparison
#'   of numeric outputs whose hashes differ. Outputs whose maximum absolute
#'   difference is within `tolerance` are reported as `"ok"`. Set to `0` for
#'   exact hash matching only. Default `1e-10`.
#'
#' @return Invisibly returns a `data.frame` of class
#'   `c("drift_report", "data.frame")` with columns `output`, `status`
#'   (`"ok"`, `"drifted"`, `"missing"`, `"new"`), `max_delta`, and `note`.
#'   Also emits a summary via `message()`.
#'
#' @seealso [certify()] to create a baseline; [list_certs()] to see available
#'   tags.
#'
#' @examples
#' cert_file <- tempfile()
#' model <- lm(mpg ~ wt, data = mtcars)
#'
#' certify(list(coefs = coef(model)), tag = "v1", file = cert_file)
#'
#' # Same outputs -- should report "ok"
#' result <- check_drift(list(coefs = coef(model)),
#'   against = "v1", file = cert_file
#' )
#' print(result)
#'
#' # Different model -- should report "drifted"
#' model2 <- lm(mpg ~ hp, data = mtcars)
#' check_drift(list(coefs = coef(model2)),
#'   against = "v1", file = cert_file
#' )
#'
#' @export
check_drift <- function(outputs,
                        against = "latest",
                        file = ".reproducr",
                        tolerance = 1e-10) {
  if (!is.list(outputs) || is.null(names(outputs))) {
    stop("`outputs` must be a fully named list.", call. = FALSE)
  }

  certs <- .load_certs(file)
  if (length(certs) == 0L) {
    stop(sprintf(
      "No certifications found in '%s.rds'. Run certify() first.", file
    ), call. = FALSE)
  }

  if (identical(against, "latest")) {
    against <- names(certs)[length(certs)]
    message(sprintf("reproducr: comparing against latest tag: '%s'", against))
  }

  if (!against %in% names(certs)) {
    stop(sprintf(
      "Tag '%s' not found. Available tags: %s",
      against, paste(names(certs), collapse = ", ")
    ), call. = FALSE)
  }

  baseline <- certs[[against]]
  baseline_hashes <- baseline$hashes
  baseline_values <- baseline$values # NULL for certs made before v0.2.0
  baseline_names <- names(baseline_hashes)
  current_names <- names(outputs)

  results <- vector("list", length(current_names) +
    sum(!baseline_names %in% current_names))
  idx <- 0L

  for (nm in current_names) {
    curr_hash <- tryCatch(
      .hash_object(outputs[[nm]]),
      error = function(e) NA_character_
    )

    if (!nm %in% baseline_names) {
      idx <- idx + 1L
      results[[idx]] <- data.frame(
        output = nm,
        status = "new",
        max_delta = NA_real_,
        note = "Not present in the baseline certification.",
        stringsAsFactors = FALSE
      )
      next
    }

    base_hash <- baseline_hashes[[nm]]

    if (identical(curr_hash, base_hash)) {
      idx <- idx + 1L
      results[[idx]] <- data.frame(
        output = nm,
        status = "ok",
        max_delta = 0,
        note = "",
        stringsAsFactors = FALSE
      )
      next
    }

    # --- Hashes differ: attempt numeric tolerance comparison -----------------
    max_delta <- NA_real_
    note <- "Hash mismatch."

    if (tolerance > 0 && is.numeric(outputs[[nm]])) {
      stored_val <- baseline_values[[nm]]

      if (!is.null(stored_val) && is.numeric(stored_val)) {
        curr_val <- outputs[[nm]]

        if (length(curr_val) == length(stored_val)) {
          delta <- max(abs(curr_val - stored_val), na.rm = TRUE)

          if (is.finite(delta) && delta <= tolerance) {
            # Within tolerance — benign platform floating point variation, treat as ok
            idx <- idx + 1L
            results[[idx]] <- data.frame(
              output = nm,
              status = "ok",
              max_delta = delta,
              note = sprintf(
                "Within tolerance (max |delta|: %s)", signif(delta, 3L)
              ),
              stringsAsFactors = FALSE
            )
            next
          } else if (is.finite(delta)) {
            max_delta <- delta
            note <- sprintf(
              "Numeric drift (max |delta|: %s, tolerance: %s).",
              signif(delta, 3L), signif(tolerance, 3L)
            )
          } else {
            note <- "Hash mismatch (non-finite delta; possible NaN/Inf change)."
          }
        } else {
          note <- sprintf(
            "Hash mismatch (length changed: %d -> %d).",
            length(stored_val), length(curr_val)
          )
        }
      } else {
        # baseline$values absent — old certification format
        note <- paste0(
          "Hash mismatch (numeric tolerance unavailable; ",
          "re-run certify() to enable cross-platform comparison)."
        )
      }
    }

    idx <- idx + 1L
    results[[idx]] <- data.frame(
      output = nm,
      status = "drifted",
      max_delta = max_delta,
      note = note,
      stringsAsFactors = FALSE
    )
  }

  for (nm in baseline_names[!baseline_names %in% current_names]) {
    idx <- idx + 1L
    results[[idx]] <- data.frame(
      output = nm,
      status = "missing",
      max_delta = NA_real_,
      note = "Present in baseline but not supplied to check_drift().",
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, results[seq_len(idx)])
  if (is.null(out)) {
    out <- data.frame(
      output = character(0), status = character(0),
      max_delta = numeric(0), note = character(0),
      stringsAsFactors = FALSE
    )
  }
  row.names(out) <- NULL

  n_ok <- sum(out$status == "ok", na.rm = TRUE)
  n_drifted <- sum(out$status == "drifted", na.rm = TRUE)
  n_missing <- sum(out$status == "missing", na.rm = TRUE)
  n_new <- sum(out$status == "new", na.rm = TRUE)

  verdict <- if (n_drifted > 0L || n_missing > 0L) {
    "DRIFT DETECTED"
  } else {
    "ALL OUTPUTS MATCH"
  }

  message(sprintf("-- reproducr drift check vs '%s' --", against))
  message(sprintf("  Verdict  : %s", verdict))
  message(sprintf("  OK       : %d", n_ok))
  message(sprintf("  Drifted  : %d", n_drifted))
  message(sprintf("  Missing  : %d", n_missing))
  message(sprintf("  New      : %d", n_new))

  if (n_drifted > 0L) {
    drifted_nms <- paste(
      paste0("    - ", out$output[out$status == "drifted"]),
      collapse = "\n"
    )
    message("  Drifted outputs:\n", drifted_nms)
  }

  class(out) <- c("drift_report", "data.frame")
  invisible(out)
}


#' List all certifications stored in a certification file
#'
#' @description
#' A convenience function to inspect what certification tags are stored and
#' their key metadata, without needing to read the raw `.rds` file.
#'
#' @param file `character(1)`. Base path of the certification store.
#'   Default `".reproducr"`.
#'
#' @return A `data.frame` with columns `tag`, `timestamp`, `r_version`,
#'   `os`, `n_outputs`, `script` -- one row per certification.
#'   Returns an empty data frame if no certifications exist.
#'
#' @examples
#' cert_file <- tempfile()
#' model <- lm(mpg ~ wt, data = mtcars)
#'
#' certify(list(coefs = coef(model)), tag = "v1", file = cert_file)
#' certify(list(coefs = coef(model)), tag = "v2", file = cert_file)
#'
#' list_certs(file = cert_file)
#'
#' @export
list_certs <- function(file = ".reproducr") {
  certs <- .load_certs(file)

  if (length(certs) == 0L) {
    message("reproducr: no certifications found in '", file, ".rds'.")
    return(invisible(data.frame(
      tag = character(0), timestamp = character(0),
      r_version = character(0), os = character(0),
      n_outputs = integer(0), script = character(0),
      stringsAsFactors = FALSE
    )))
  }

  out <- do.call(rbind, lapply(certs, function(rec) {
    data.frame(
      tag = rec$tag,
      timestamp = rec$timestamp,
      r_version = rec$r_version,
      os = if (!is.null(rec$os)) rec$os else NA_character_,
      n_outputs = rec$n_outputs,
      script = if (!is.null(rec$script)) rec$script else NA_character_,
      stringsAsFactors = FALSE
    )
  }))
  row.names(out) <- NULL
  out
}


# ---- S3 methods -------------------------------------------------------------

#' @export
print.drift_report <- function(x, ...) {
  if (nrow(x) == 0L) {
    cat("\n-- reproducr drift report --\n\n  (empty)\n\n")
    return(invisible(x))
  }

  cat("\n-- reproducr drift report --\n\n")
  status_labels <- c(
    ok      = "[OK]     ",
    drifted = "[DRIFT]  ",
    missing = "[MISSING]",
    new     = "[NEW]    "
  )

  for (i in seq_len(nrow(x))) {
    label <- status_labels[x$status[i]]
    if (is.na(label)) label <- "[?]      "
    cat(label, " ", x$output[i], sep = "")
    if (!is.na(x$max_delta[i]) && x$max_delta[i] > 0) {
      cat(sprintf(" (max delta: %s)", signif(x$max_delta[i], 3L)))
    }
    if (nchar(trimws(x$note[i])) > 0L) {
      cat("\n            ", x$note[i], sep = "")
    }
    cat("\n")
  }
  cat("\n")
  invisible(x)
}
