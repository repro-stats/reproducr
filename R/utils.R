# Internal utilities for reproducr
# Not exported. All helpers prefixed with . to signal internal use.

# ---- hashing ----------------------------------------------------------------

#' Hash an R object to a stable string
#'
#' Uses `digest::digest()` when available (SHA-256), falling back to a
#' serialise-based approach that only requires base R. The fallback is weaker
#' (not cryptographic) but sufficient for change detection.
#'
#' @param obj Any R object.
#' @return A character string representing the hash.
#' @noRd
.hash_object <- function(obj) {
  if (requireNamespace("digest", quietly = TRUE)) {
    digest::digest(obj, algo = "sha256")
  } else {
    raw_bytes <- serialize(obj, connection = NULL)
    paste0(
      format(sum(as.integer(raw_bytes[1:min(500L, length(raw_bytes))]) %% 2147483647L),
             scientific = FALSE),
      "-",
      length(raw_bytes)
    )
  }
}

# ---- certification file I/O -------------------------------------------------

#' Load certification records from disk
#' @noRd
.load_certs <- function(file) {
  rds_path <- .cert_path(file)
  if (!file.exists(rds_path)) return(list())
  tryCatch(readRDS(rds_path), error = function(e) {
    warning("reproducr: could not read certification file '", rds_path,
            "': ", conditionMessage(e), call. = FALSE)
    list()
  })
}

#' Save certification records to disk
#' @noRd
.save_certs <- function(certs, file) {
  rds_path <- .cert_path(file)
  dir.create(dirname(rds_path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(certs, rds_path)
  invisible(rds_path)
}

#' Resolve the actual path of the .rds certification store
#' @noRd
.cert_path <- function(file) paste0(file, ".rds")

# ---- file collection --------------------------------------------------------

#' Collect R-ish source files from a path (file or directory)
#' @noRd
.collect_r_files <- function(path) {
  if (utils::file_test("-f", path)) return(path)
  all_files <- list.files(path, recursive = TRUE, full.names = TRUE)
  r_files <- all_files[grepl("\\.(R|Rmd|qmd|r)$", all_files, perl = TRUE)]
  # Exclude renv library and common non-analysis dirs
  r_files[!grepl("/(renv|packrat|node_modules|\\.[^/]+)/", r_files, perl = TRUE)]
}

# ---- renv integration -------------------------------------------------------

#' Check whether an renv.lock file is present
#' @noRd
.renv_lock_exists <- function(root = getwd()) {
  file.exists(file.path(root, "renv.lock"))
}

#' Parse renv.lock and return a named list of pkg -> version
#' @noRd
.parse_renv_lock <- function(root = getwd()) {
  lock_path <- file.path(root, "renv.lock")
  lock_text  <- paste(readLines(lock_path, warn = FALSE), collapse = "\n")

  pkg_matches <- gregexpr('"Package":\\s*"([^"]+)"', lock_text, perl = TRUE)
  ver_matches <- gregexpr('"Version":\\s*"([^"]+)"', lock_text, perl = TRUE)

  pkgs <- gsub('"Package":\\s*"([^"]+)"', "\\1",
               regmatches(lock_text, pkg_matches)[[1]], perl = TRUE)
  vers <- gsub('"Version":\\s*"([^"]+)"', "\\1",
               regmatches(lock_text, ver_matches)[[1]], perl = TRUE)

  if (length(pkgs) != length(vers) || length(pkgs) == 0) return(list())
  setNames(as.list(vers), pkgs)
}

#' Resolve package versions: renv.lock if available, else installed library
#' @noRd
.resolve_pkg_versions <- function(use_renv = TRUE, verbose = TRUE) {
  if (use_renv && .renv_lock_exists()) {
    versions <- tryCatch(.parse_renv_lock(), error = function(e) list())
    if (length(versions) > 0) {
      if (verbose) message("reproducr: reading package versions from renv.lock (",
                           length(versions), " packages)")
      return(versions)
    }
    if (verbose) message("reproducr: renv.lock found but could not be parsed, ",
                         "falling back to installed library")
  }

  inst <- utils::installed.packages()[, c("Package", "Version"), drop = FALSE]
  versions <- setNames(as.list(inst[, "Version"]), inst[, "Package"])
  if (verbose) message("reproducr: resolved versions for ", length(versions),
                       " installed packages")
  versions
}

# ---- version comparison -----------------------------------------------------

#' Return TRUE if `installed` version sits in the half-open risk window
#' (from_ver, to_ver] — i.e., the breaking change was introduced in to_ver.
#' @noRd
.version_in_window <- function(installed, from_ver, to_ver) {
  tryCatch({
    iv <- package_version(as.character(installed))
    fv <- package_version(as.character(from_ver))
    tv <- package_version(as.character(to_ver))
    iv > fv && iv <= tv
  }, error = function(e) FALSE)
}

# ---- OS detection -----------------------------------------------------------

#' Return a short OS description string
#' @noRd
.get_os <- function() {
  si <- tryCatch(Sys.info(), error = function(e) NULL)
  if (!is.null(si)) {
    paste(si[["sysname"]], si[["release"]])
  } else {
    .Platform$OS.type
  }
}

# ---- text utilities ---------------------------------------------------------

#' Word-wrap a string for console output
#' @noRd
.wrap_text <- function(text, width = 72, indent = "") {
  words   <- strsplit(as.character(text), " ", fixed = TRUE)[[1]]
  lines   <- character(0)
  current <- ""
  for (w in words) {
    candidate <- if (nchar(current) == 0L) w else paste(current, w)
    if (nchar(candidate) > width && nchar(current) > 0L) {
      lines   <- c(lines, current)
      current <- w
    } else {
      current <- candidate
    }
  }
  if (nchar(current) > 0L) lines <- c(lines, current)
  paste(lines, collapse = paste0("\n", indent))
}

#' Map risk level string to integer for sorting
#' @noRd
.risk_int <- function(risk) {
  c(high = 3L, medium = 2L, low = 1L)[risk]
}

#' Pad a string to a fixed width
#' @noRd
.pad <- function(s, width) {
  s <- as.character(s)
  pad <- width - nchar(s)
  if (pad > 0) paste0(s, strrep(" ", pad)) else s
}
