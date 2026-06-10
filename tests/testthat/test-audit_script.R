test_that("audit_script() returns an audit_report S3 object", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_s3_class(r, "audit_report")
  expect_true(is.data.frame(r$calls))
  expect_true(is.list(r$env))
  expect_true(inherits(r$timestamp, "POSIXct"))
  expect_true(is.character(r$paths))
  expect_equal(length(r$paths), 1L)
})

test_that("audit_script() result has required columns in calls data frame", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_true(all(c("file", "line", "pkg", "fn", "pkg_version") %in% names(r$calls)))
})

test_that("audit_script() detects pkg::fn calls across packages", {
  f <- write_script(
    "x <- dplyr::filter(mtcars, cyl == 4)",
    "y <- dplyr::summarise(x, n = dplyr::n())",
    "z <- stats::rnorm(10)"
  )
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_true(any(r$calls$pkg == "dplyr" & r$calls$fn == "filter"))
  expect_true(any(r$calls$pkg == "dplyr" & r$calls$fn == "summarise"))
  expect_true(any(r$calls$pkg == "stats" & r$calls$fn == "rnorm"))
})

test_that("audit_script() skips pure comment lines", {
  f <- write_script(
    "# dplyr::should_not_detect()",
    "x <- dplyr::select(mtcars, mpg)"
  )
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_false(any(r$calls$fn == "should_not_detect"))
  expect_true(any(r$calls$fn == "select"))
})

test_that("audit_script() skips trailing inline comments", {
  f <- write_script("x <- 1  # dplyr::not_this()")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_equal(nrow(r$calls), 0L)
})

test_that("audit_script() detects pkg:::fn (internal namespace) calls", {
  f <- write_script("x <- rlang:::is_string('hello')")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_true(any(r$calls$pkg == "rlang" & r$calls$fn == "is_string"))
})

test_that("audit_script() records correct line numbers", {
  f <- write_script(
    "a <- 1",
    "b <- dplyr::filter(mtcars, cyl == 4)"
  )
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  filter_row <- r$calls[r$calls$fn == "filter", , drop = FALSE]
  expect_equal(filter_row$line, 2L)
})

test_that("audit_script() records multiple calls on the same line", {
  f <- write_script("x <- dplyr::filter(dplyr::mutate(mtcars, z = 1), cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  dplyr_calls <- r$calls[r$calls$pkg == "dplyr", ]
  expect_true(nrow(dplyr_calls) >= 2L)
})

test_that("audit_script() errors informatively when no R files are found", {
  td <- tempdir()
  empty_dir <- file.path(td, paste0("reproducr_empty_", as.integer(Sys.time())))
  dir.create(empty_dir)
  on.exit(unlink(empty_dir, recursive = TRUE))

  expect_error(
    audit_script(empty_dir, renv = FALSE, verbose = FALSE),
    "No .R, .Rmd, or .qmd files"
  )
})

test_that("audit_script() scans a directory recursively", {
  td <- tempdir()
  dir <- file.path(td, paste0("reproducr_scan_", as.integer(Sys.time())))
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  writeLines("x <- dplyr::filter(mtcars, cyl==4)", file.path(dir, "a.R"))
  writeLines("y <- stats::rnorm(10)", file.path(dir, "b.R"))

  r <- audit_script(dir, renv = FALSE, verbose = FALSE)
  expect_equal(length(r$paths), 2L)
  expect_true(any(r$calls$pkg == "dplyr"))
  expect_true(any(r$calls$pkg == "stats"))
})

test_that("audit_script() excludes renv/ subdirectory from scan", {
  td <- tempdir()
  dir <- file.path(td, paste0("reproducr_renv_", as.integer(Sys.time())))
  dir.create(file.path(dir, "renv"), recursive = TRUE)
  on.exit(unlink(dir, recursive = TRUE))

  writeLines("x <- dplyr::filter(mtcars, cyl==4)", file.path(dir, "analysis.R"))
  writeLines("y <- base::stop('renv internal')", file.path(dir, "renv", "internal.R"))

  r <- audit_script(dir, renv = FALSE, verbose = FALSE)
  expect_false(any(r$calls$fn == "stop" & grepl("renv", r$calls$file)))
})

test_that("audit_script() captures environment fingerprint", {
  f <- write_script("x <- 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_true(!is.null(r$env$r_version))
  expect_true(!is.null(r$env$os))
  expect_true(!is.null(r$env$locale))
  expect_true(!is.null(r$env$timezone))
})

test_that("audit_script() returns renv_used = FALSE when renv = FALSE", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_false(r$renv_used)
})

test_that("print.audit_report() outputs expected header text", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_output(print(r), "reproducr audit report")
  expect_output(print(r), "Files scanned")
  expect_output(print(r), "R version")
})

test_that("print.audit_report() returns its input invisibly", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  ret <- withVisible(print(r))
  expect_false(ret$visible)
  expect_s3_class(ret$value, "audit_report")
})

test_that("summary.audit_report() returns a list with required fields", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  s <- summary(r)

  expect_true(is.list(s))
  expect_true(all(c("n_files", "n_calls", "n_pkgs", "env", "timestamp") %in% names(s)))
})

test_that("summary.audit_report() n_calls matches nrow(report$calls)", {
  f <- write_script(
    "x <- dplyr::filter(mtcars, cyl == 4)",
    "y <- stats::rnorm(10)"
  )
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  s <- summary(r)

  expect_equal(s$n_calls, nrow(r$calls))
})
