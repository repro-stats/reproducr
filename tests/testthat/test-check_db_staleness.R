test_that("check_db_staleness() returns a staleness_report data frame", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_s3_class(result, "staleness_report")
  expect_true(all(c(
    "key", "pkg", "fn", "from_version", "to_version",
    "current_version", "status", "gap"
  ) %in% names(result)))
})

test_that("check_db_staleness() status column only contains valid values", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  expect_true(all(result$status %in%
    c("ok", "stale_ceiling", "stale_floor", "unknown")))
})

test_that("check_db_staleness() key column matches pkg::fn format", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  expect_true(all(grepl(
    "^[a-zA-Z][a-zA-Z0-9.]*::[a-zA-Z][a-zA-Z0-9._]*$",
    result$key,
    perl = TRUE
  )))
})

test_that("check_db_staleness() pkg and fn columns are consistent with key", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  reconstructed <- paste0(result$pkg, "::", result$fn)
  expect_equal(reconstructed, result$key)
})

test_that("check_db_staleness() from_version column is present and non-empty", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  expect_true("from_version" %in% names(result))
  expect_true(all(nchar(result$from_version) > 0L))
})

test_that("check_db_staleness() filters to requested packages", {
  result <- check_db_staleness(
    packages = "dplyr", source = "installed", verbose = FALSE
  )
  expect_true(all(result$pkg == "dplyr"))
})

test_that("check_db_staleness() warns on unknown package name", {
  expect_warning(
    check_db_staleness(
      packages = c("dplyr", "not_a_real_package"),
      source   = "installed",
      verbose  = FALSE
    ),
    "not found in database"
  )
})

test_that("check_db_staleness() errors when no matching packages found", {
  expect_error(
    suppressWarnings(
      check_db_staleness(
        packages = "definitely_not_a_package",
        source   = "installed",
        verbose  = FALSE
      )
    ),
    "No matching packages"
  )
})

test_that("check_db_staleness() gap column is NA for ok entries", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  ok_rows <- result[result$status == "ok", ]
  if (nrow(ok_rows) > 0L) expect_true(all(is.na(ok_rows$gap)))
})

test_that("check_db_staleness() gap column is non-NA for stale_ceiling entries", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  stale_rows <- result[result$status == "stale_ceiling", ]
  skip_if(nrow(stale_rows) == 0L, "no stale_ceiling entries in current database state")
  expect_true(all(!is.na(stale_rows$gap)))
  expect_true(all(grepl("to_version", stale_rows$gap, fixed = TRUE)))
})

test_that("check_db_staleness() gap column is non-NA for stale_floor entries", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  floor_rows <- result[result$status == "stale_floor", ]
  skip_if(nrow(floor_rows) == 0L, "no stale_floor entries in current database state")
  expect_true(all(!is.na(floor_rows$gap)))
  expect_true(all(grepl("from_version", floor_rows$gap, fixed = TRUE)))
})

test_that("check_db_staleness() stale entries appear before ok entries", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  if (nrow(result) > 1L) {
    status_ord <- c(stale_ceiling = 1L, stale_floor = 2L, ok = 3L, unknown = 4L)
    ord <- status_ord[result$status]
    expect_true(all(diff(ord) >= 0L))
  }
})

test_that("check_db_staleness() from_version_major_threshold = Inf disables floor check", {
  result <- check_db_staleness(
    source                       = "installed",
    verbose                      = FALSE,
    from_version_major_threshold = Inf
  )
  expect_equal(sum(result$status == "stale_floor"), 0L)
})

test_that("check_db_staleness() from_version_major_threshold = 1L catches wide windows", {
  result <- check_db_staleness(
    source                       = "installed",
    verbose                      = FALSE,
    from_version_major_threshold = 1L
  )
  expect_true(all(result$status %in%
    c("ok", "stale_ceiling", "stale_floor", "unknown")))
})

test_that("check_db_staleness() returns invisibly", {
  ret <- withVisible(check_db_staleness(source = "installed", verbose = FALSE))
  expect_false(ret$visible)
})

test_that("check_db_staleness() verbose = TRUE prints messages", {
  expect_message(
    check_db_staleness(source = "installed", verbose = TRUE),
    "checking"
  )
})

# ---- print.staleness_report(): details = TRUE (default) --------------------

test_that("print.staleness_report() produces expected output", {
  result <- check_db_staleness(source = "installed", verbose = FALSE)
  expect_output(print(result), "reproducr database staleness report")
  expect_output(print(result), "STALE CEILING|OK|UNKNOWN|STALE FLOOR")
})

test_that("print.staleness_report() shows 'All entries are current' when none stale", {
  mock <- data.frame(
    key = "dplyr::filter", pkg = "dplyr", fn = "filter",
    from_version = "0.8.99", to_version = "99.9.9",
    current_version = "1.1.4", status = "ok", gap = NA_character_,
    stringsAsFactors = FALSE
  )
  class(mock) <- c("staleness_report", "data.frame")
  expect_output(print(mock), "All entries are current")
})

test_that("print.staleness_report() shows stale ceiling details by default", {
  mock <- data.frame(
    key = "dplyr::filter", pkg = "dplyr", fn = "filter",
    from_version = "0.8.99", to_version = "1.0.9",
    current_version = "1.1.4", status = "stale_ceiling",
    gap = "to_version 1.0.9 -> current 1.1.4",
    stringsAsFactors = FALSE
  )
  class(mock) <- c("staleness_report", "data.frame")
  expect_output(print(mock), "STALE CEILING")
  expect_output(print(mock), "dplyr::filter")
  expect_output(print(mock), "extend to_version")
})

test_that("print.staleness_report() shows stale floor details by default", {
  mock <- data.frame(
    key = "dplyr::filter", pkg = "dplyr", fn = "filter",
    from_version = "0.8.99", to_version = "1.2.9",
    current_version = "1.1.4", status = "stale_floor",
    gap = "from_version 0.8.99 << current 1.1.4",
    stringsAsFactors = FALSE
  )
  class(mock) <- c("staleness_report", "data.frame")
  expect_output(print(mock), "STALE FLOOR")
  expect_output(print(mock), "dplyr::filter")
  expect_output(print(mock), "raise from_version")
})

# ---- print.staleness_report(): details = FALSE ------------------------------

test_that("print.staleness_report() details = FALSE shows counts but not entry breakdown", {
  mock <- data.frame(
    key = "dplyr::filter", pkg = "dplyr", fn = "filter",
    from_version = "0.8.99", to_version = "1.0.9",
    current_version = "1.1.4", status = "stale_ceiling",
    gap = "to_version 1.0.9 -> current 1.1.4",
    stringsAsFactors = FALSE
  )
  class(mock) <- c("staleness_report", "data.frame")

  out <- paste(capture.output(print(mock, details = FALSE)), collapse = "\n")
  expect_match(out, "STALE CEILING")       # counts still shown
  expect_false(grepl("extend to_version", out, fixed = TRUE))  # entry breakdown suppressed
  expect_false(grepl("dplyr::filter", out, fixed = TRUE))
})

test_that("print.staleness_report() details = FALSE still shows all-current message", {
  mock <- data.frame(
    key = "dplyr::filter", pkg = "dplyr", fn = "filter",
    from_version = "0.8.99", to_version = "99.9.9",
    current_version = "1.1.4", status = "ok", gap = NA_character_,
    stringsAsFactors = FALSE
  )
  class(mock) <- c("staleness_report", "data.frame")
  expect_output(print(mock, details = FALSE), "All entries are current")
})

test_that("check_db_staleness() returns empty df when all entries closed", {
  result <- check_db_staleness(
    packages = "stats", source = "installed", verbose = FALSE
  )
  expect_equal(nrow(result), 0L)
})

# ---- internal helpers -------------------------------------------------------

test_that(".assess_staleness() returns 'stale' when current > to_version", {
  expect_equal(reproducr:::.assess_staleness("1.2.0", "1.1.9"), "stale")
  expect_equal(reproducr:::.assess_staleness("4.4.2", "3.6.9"), "stale")
})

test_that(".assess_staleness() returns 'ok' when current <= to_version", {
  expect_equal(reproducr:::.assess_staleness("1.1.0", "1.1.9"), "ok")
  expect_equal(reproducr:::.assess_staleness("1.1.9", "1.1.9"), "ok")
})

test_that(".assess_staleness() returns 'unknown' for NA current version", {
  expect_equal(reproducr:::.assess_staleness(NA_character_, "1.1.9"), "unknown")
})

test_that(".assess_floor_staleness() returns 'stale' when gap >= threshold", {
  expect_equal(reproducr:::.assess_floor_staleness("4.0.0", "2.0.0", 2L), "stale")
  expect_equal(reproducr:::.assess_floor_staleness("4.7.2", "3.0.2", 1L), "stale")
})

test_that(".assess_floor_staleness() returns 'ok' when gap < threshold", {
  expect_equal(reproducr:::.assess_floor_staleness("4.7.2", "3.0.2", 2L), "ok")
  expect_equal(reproducr:::.assess_floor_staleness("1.2.0", "1.0.0", 1L), "ok")
})

test_that(".assess_floor_staleness() returns 'ok' when threshold is Inf", {
  expect_equal(reproducr:::.assess_floor_staleness("9.0.0", "1.0.0", Inf), "ok")
})

test_that(".assess_floor_staleness() returns 'ok' for NA current version", {
  expect_equal(reproducr:::.assess_floor_staleness(NA_character_, "1.0.0", 1L), "ok")
})

# ---- .resolve_current_versions(): CRAN error fallback ----------------------

test_that(".resolve_current_versions() falls back to installed when CRAN errors", {
  local_mocked_bindings(
    available.packages = function(...) stop("no internet"),
    .package = "utils"
  )
  result <- check_db_staleness(source = "cran", verbose = FALSE)
  expect_s3_class(result, "staleness_report")
})

# ---- stale ceiling/floor verbose message paths -----------------------------

test_that("check_db_staleness() emits stale ceiling message when entries are stale", {
  local_mocked_bindings(
    .assess_staleness       = function(...) "stale",
    .assess_floor_staleness = function(...) "ok",
    .package = "reproducr"
  )
  expect_message(
    check_db_staleness(source = "installed", verbose = TRUE),
    "Stale ceiling"
  )
})

test_that("check_db_staleness() emits stale floor message when entries are stale", {
  local_mocked_bindings(
    .assess_staleness       = function(...) "ok",
    .assess_floor_staleness = function(...) "stale",
    .package = "reproducr"
  )
  expect_message(
    check_db_staleness(source = "installed", verbose = TRUE),
    "Stale floor"
  )
})