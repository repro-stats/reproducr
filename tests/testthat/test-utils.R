# ---- .hash_object(): base-R fallback (lines 24-31) -------------------------

test_that(".hash_object() base-R fallback produces a stable non-empty string", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "digest") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  result <- reproducr:::.hash_object(42L)
  expect_type(result, "character")
  expect_true(grepl("-", result, fixed = TRUE))
  expect_identical(reproducr:::.hash_object(42L), result)
})

test_that(".hash_object() base-R fallback differs for different objects", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "digest") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  expect_false(
    identical(reproducr:::.hash_object(1L), reproducr:::.hash_object(2L))
  )
})

# ---- .parse_renv_lock(): all paths (lines 131-161) -------------------------

test_that(".parse_renv_lock() returns NULL for missing renv.lock", {
  d <- withr::local_tempdir()
  expect_null(reproducr:::.parse_renv_lock(d))
})

test_that(".parse_renv_lock() returns NULL for empty renv.lock", {
  d <- withr::local_tempdir()
  file.create(file.path(d, "renv.lock"))
  expect_null(reproducr:::.parse_renv_lock(d))
})

test_that(".parse_renv_lock() accepts a direct .lock file path", {
  lock <- withr::local_tempfile(fileext = ".lock")
  writeLines(
    '{"R":{"Version":"4.3.0"},"Packages":{"dplyr":{"Package":"dplyr","Version":"1.1.0"}}}',
    lock
  )
  result <- reproducr:::.parse_renv_lock(lock)
  expect_type(result, "list")
  expect_equal(result[["dplyr"]], "1.1.0")
})

test_that(".parse_renv_lock() parses multiple packages correctly", {
  lock <- withr::local_tempfile(fileext = ".lock")
  writeLines(
    paste0(
      '{"R":{"Version":"4.3.0"},"Packages":{',
      '"dplyr":{"Package":"dplyr","Version":"1.1.0"},',
      '"tidyr":{"Package":"tidyr","Version":"1.3.0"}',
      "}}"
    ),
    lock
  )
  result <- reproducr:::.parse_renv_lock(lock)
  expect_equal(result[["dplyr"]], "1.1.0")
  expect_equal(result[["tidyr"]], "1.3.0")
})

test_that(".parse_renv_lock() returns empty list when Packages block absent", {
  lock <- withr::local_tempfile(fileext = ".lock")
  writeLines('{"R":{"Version":"4.3.0"}}', lock)
  result <- reproducr:::.parse_renv_lock(lock)
  expect_true(is.null(result) || (is.list(result) && length(result) == 0L))
})

test_that(".parse_renv_lock() regex fallback returns correct versions", {
  lock <- withr::local_tempfile(fileext = ".lock")
  writeLines(
    paste0(
      '{"R":{"Version":"4.3.0"},"Packages":{',
      '"ggplot2":{"Package":"ggplot2","Version":"3.4.0"}',
      "}}"
    ),
    lock
  )
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "jsonlite") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  result <- reproducr:::.parse_renv_lock(lock)
  expect_type(result, "list")
  expect_equal(result[["ggplot2"]], "3.4.0")
})

test_that(".parse_renv_lock() regex fallback returns empty list for no Packages", {
  lock <- withr::local_tempfile(fileext = ".lock")
  writeLines('{"R":{"Version":"4.3.0"}}', lock)
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "jsonlite") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  result <- reproducr:::.parse_renv_lock(lock)
  expect_true(is.null(result) || (is.list(result) && length(result) == 0L))
})

# ---- .resolve_pkg_versions(): fallback paths (lines 171-182) ---------------

test_that(".resolve_pkg_versions() falls back to installed when renv.lock parses empty", {
  d <- withr::local_tempdir()
  withr::local_dir(d)
  writeLines('{"R":{"Version":"4.3.0"}}', file.path(d, "renv.lock"))

  result <- reproducr:::.resolve_pkg_versions(use_renv = TRUE, verbose = FALSE)
  expect_type(result, "list")
  expect_true(length(result) > 0L)
})

test_that(".resolve_pkg_versions() emits verbose message for renv fallback", {
  d <- withr::local_tempdir()
  withr::local_dir(d)
  writeLines('{"R":{"Version":"4.3.0"}}', file.path(d, "renv.lock"))

  expect_message(
    reproducr:::.resolve_pkg_versions(use_renv = TRUE, verbose = TRUE),
    "renv.lock found but could not be parsed"
  )
})

test_that(".resolve_pkg_versions() uses installed library when use_renv = FALSE", {
  result <- reproducr:::.resolve_pkg_versions(use_renv = FALSE, verbose = FALSE)
  expect_type(result, "list")
  expect_true(length(result) > 0L)
  expect_true(any(c("base", "stats", "utils") %in% names(result)))
})

# ---- .get_os(): Sys.info() failure fallback (line 240) ---------------------

test_that(".get_os() falls back to .Platform$OS.type when Sys.info() errors", {
  local_mocked_bindings(
    Sys.info = function() stop("mocked Sys.info error"),
    .package = "base"
  )
  result <- reproducr:::.get_os()
  expect_type(result, "character")
  expect_true(nchar(result) > 0L)
  expect_equal(result, .Platform$OS.type)
})
