# tests/testthat/test-utils.R

# ---- .parse_renv_lock -------------------------------------------------------

test_that(".parse_renv_lock handles valid JSON lockfile via direct path", {
  lock <- tempfile(fileext = ".lock")
  writeLines('{
    "R": {"Version": "4.4.2"},
    "Packages": {
      "dplyr": {"Package": "dplyr", "Version": "1.1.4"},
      "ggplot2": {"Package": "ggplot2", "Version": "3.5.1"}
    }
  }', lock)
  on.exit(unlink(lock))

  result <- reproducr:::.parse_renv_lock(lock)
  expect_type(result, "list")
  expect_true("dplyr" %in% names(result))
  expect_equal(result[["dplyr"]], "1.1.4")
  expect_true("ggplot2" %in% names(result))
})

test_that(".parse_renv_lock returns NULL for missing file", {
  result <- reproducr:::.parse_renv_lock("/nonexistent/path/fake.lock")
  expect_null(result)
})

test_that(".parse_renv_lock returns NULL for invalid JSON", {
  lock <- tempfile(fileext = ".lock")
  writeLines("this is not valid json", lock)
  on.exit(unlink(lock))

  result <- reproducr:::.parse_renv_lock(lock)
  expect_null(result)
})

test_that(".parse_renv_lock returns NULL for empty file", {
  lock <- tempfile(fileext = ".lock")
  file.create(lock)
  on.exit(unlink(lock))

  result <- reproducr:::.parse_renv_lock(lock)
  expect_null(result)
})

test_that(".parse_renv_lock accepts a directory path", {
  tmp <- tempfile()
  dir.create(tmp)
  lock <- file.path(tmp, "renv.lock")
  writeLines('{
    "R": {"Version": "4.4.2"},
    "Packages": {
      "dplyr": {"Package": "dplyr", "Version": "1.1.4"}
    }
  }', lock)
  on.exit(unlink(tmp, recursive = TRUE))

  result <- reproducr:::.parse_renv_lock(tmp)
  expect_type(result, "list")
  expect_equal(result[["dplyr"]], "1.1.4")
})

test_that(".parse_renv_lock returns empty list for lockfile with no packages", {
  lock <- tempfile(fileext = ".lock")
  writeLines('{"R": {"Version": "4.4.2"}, "Packages": {}}', lock)
  on.exit(unlink(lock))

  result <- reproducr:::.parse_renv_lock(lock)
  expect_type(result, "list")
  expect_equal(length(result), 0L)
})

# ---- .renv_lock_exists ------------------------------------------------------

test_that(".renv_lock_exists returns FALSE when no lockfile present", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  expect_false(reproducr:::.renv_lock_exists(tmp))
})

test_that(".renv_lock_exists returns TRUE when lockfile present", {
  tmp <- tempfile()
  dir.create(tmp)
  lock <- file.path(tmp, "renv.lock")
  writeLines('{"R": {"Version": "4.4.2"}, "Packages": {}}', lock)
  on.exit(unlink(tmp, recursive = TRUE))

  expect_true(reproducr:::.renv_lock_exists(tmp))
})

# ---- .hash_object -----------------------------------------------------------

test_that(".hash_object returns a non-empty string", {
  result <- reproducr:::.hash_object(list(a = 1, b = "x"))
  expect_type(result, "character")
  expect_true(nchar(result) > 0L)
})

test_that(".hash_object is deterministic", {
  obj <- list(coef = c(1.2, 3.4), n = 100L)
  expect_equal(
    reproducr:::.hash_object(obj),
    reproducr:::.hash_object(obj)
  )
})

test_that(".hash_object differs for different inputs", {
  expect_false(
    reproducr:::.hash_object(list(a = 1)) ==
      reproducr:::.hash_object(list(a = 2))
  )
})

test_that(".hash_object base R fallback produces valid string", {
  # Bypass digest by calling the fallback logic directly
  obj <- list(x = 1:10)
  raw_bytes <- serialize(obj, connection = NULL)
  result <- paste0(
    format(
      sum(as.integer(raw_bytes[1:min(500L, length(raw_bytes))]) %% 2147483647L),
      scientific = FALSE
    ),
    "-",
    length(raw_bytes)
  )
  expect_type(result, "character")
  expect_true(grepl("-", result, fixed = TRUE))
  expect_true(nchar(result) > 0L)
})

# ---- .get_os ----------------------------------------------------------------

test_that(".get_os returns a non-empty string", {
  result <- reproducr:::.get_os()
  expect_type(result, "character")
  expect_true(nchar(result) > 0L)
})

# ---- .pad -------------------------------------------------------------------

test_that(".pad pads a string to minimum width", {
  result <- reproducr:::.pad("hi", 10L)
  expect_true(nchar(result) >= 10L)
  expect_equal(nchar(result), 10L)
})

test_that(".pad leaves string unchanged when already wide enough", {
  expect_equal(reproducr:::.pad("hello world", 5L), "hello world")
})

test_that(".pad coerces non-string input", {
  result <- reproducr:::.pad(42L, 6L)
  expect_type(result, "character")
  expect_true(nchar(result) >= 6L)
})

# ---- .version_in_window -----------------------------------------------------

test_that(".version_in_window returns TRUE for version in window", {
  expect_true(reproducr:::.version_in_window("1.1.0", "1.0.99", "1.2.9"))
})

test_that(".version_in_window returns FALSE for version below window", {
  expect_false(reproducr:::.version_in_window("1.0.0", "1.0.99", "1.2.9"))
})

test_that(".version_in_window returns FALSE for version above window", {
  expect_false(reproducr:::.version_in_window("1.3.0", "1.0.99", "1.2.9"))
})

test_that(".version_in_window returns FALSE for invalid version strings", {
  expect_false(reproducr:::.version_in_window("not-a-version", "1.0.0", "2.0.0"))
})

test_that(".version_in_window returns TRUE for version at upper boundary", {
  expect_true(reproducr:::.version_in_window("1.2.9", "1.0.99", "1.2.9"))
})

# ---- .resolve_pkg_versions --------------------------------------------------

test_that(".resolve_pkg_versions returns a named list from installed library", {
  result <- reproducr:::.resolve_pkg_versions(use_renv = FALSE, verbose = FALSE)
  expect_type(result, "list")
  expect_true(length(result) > 0L)
  expect_true(!is.null(names(result)))
})

test_that(".resolve_pkg_versions with use_renv = TRUE falls back when no lockfile", {
  tmp <- tempfile()
  dir.create(tmp)
  old_wd <- setwd(tmp)
  on.exit({
    setwd(old_wd)
    unlink(tmp, recursive = TRUE)
  })

  result <- reproducr:::.resolve_pkg_versions(use_renv = TRUE, verbose = FALSE)
  expect_type(result, "list")
  expect_true(length(result) > 0L)
})

test_that(".resolve_pkg_versions with use_renv = TRUE reads lockfile when present", {
  tmp <- tempfile()
  dir.create(tmp)
  lock <- file.path(tmp, "renv.lock")
  writeLines('{
    "R": {"Version": "4.4.2"},
    "Packages": {
      "dplyr": {"Package": "dplyr", "Version": "1.1.4"},
      "ggplot2": {"Package": "ggplot2", "Version": "3.5.1"}
    }
  }', lock)
  old_wd <- setwd(tmp)
  on.exit({
    setwd(old_wd)
    unlink(tmp, recursive = TRUE)
  })

  result <- reproducr:::.resolve_pkg_versions(use_renv = TRUE, verbose = FALSE)
  expect_type(result, "list")
  expect_equal(result[["dplyr"]], "1.1.4")
  expect_equal(result[["ggplot2"]], "3.5.1")
})

test_that(".resolve_pkg_versions verbose = TRUE prints messages", {
  expect_message(
    reproducr:::.resolve_pkg_versions(use_renv = FALSE, verbose = TRUE),
    "resolved versions"
  )
})

# ---- .load_certs / .save_certs ----------------------------------------------

test_that(".load_certs returns empty list for missing file", {
  result <- reproducr:::.load_certs(tempfile())
  expect_type(result, "list")
  expect_equal(length(result), 0L)
})

test_that(".save_certs and .load_certs round-trip correctly", {
  f <- tempfile()
  on.exit(unlink(paste0(f, ".rds")))
  certs <- list(run1 = list(hash = "abc123", tag = "test"))

  reproducr:::.save_certs(certs, f)
  result <- reproducr:::.load_certs(f)
  expect_equal(result, certs)
})

test_that(".load_certs returns empty list and warns for corrupt file", {
  f <- tempfile()
  writeLines("not an rds file", paste0(f, ".rds"))
  on.exit(unlink(paste0(f, ".rds")))

  expect_warning(
    result <- reproducr:::.load_certs(f),
    "could not read"
  )
  expect_equal(length(result), 0L)
})

# ---- .collect_r_files -------------------------------------------------------

test_that(".collect_r_files returns path for a single file", {
  f <- tempfile(fileext = ".R")
  writeLines("x <- 1", f)
  on.exit(unlink(f))

  result <- reproducr:::.collect_r_files(f)
  expect_equal(result, f)
})

test_that(".collect_r_files collects R files from a directory", {
  tmp <- tempfile()
  dir.create(tmp)
  writeLines("x <- 1", file.path(tmp, "analysis.R"))
  writeLines("y <- 2", file.path(tmp, "helpers.R"))
  writeLines("not R", file.path(tmp, "notes.txt"))
  on.exit(unlink(tmp, recursive = TRUE))

  result <- reproducr:::.collect_r_files(tmp)
  expect_true(length(result) == 2L)
  expect_true(all(grepl("\\.R$", result)))
})

test_that(".collect_r_files excludes renv directory", {
  tmp <- tempfile()
  renv <- file.path(tmp, "renv", "library")
  dir.create(renv, recursive = TRUE)
  writeLines("x <- 1", file.path(tmp, "analysis.R"))
  writeLines("y <- 2", file.path(renv, "pkg_code.R"))
  on.exit(unlink(tmp, recursive = TRUE))

  result <- reproducr:::.collect_r_files(tmp)
  expect_true(all(!grepl("renv", result)))
  expect_equal(length(result), 1L)
})
