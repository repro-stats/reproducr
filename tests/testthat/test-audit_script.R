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

# ---- audit_script(): no-calls verbose message (lines 81-84) ----------------

test_that("audit_script() emits no-calls message when verbose = TRUE", {
  script <- withr::local_tempfile(fileext = ".R")
  writeLines(c("x <- 1 + 1", "y <- mean(c(1, 2, 3))"), script)

  expect_message(
    audit_script(script, renv = FALSE, verbose = TRUE),
    "no qualified pkg::fn calls detected"
  )
})

# ---- audit_script(): silent no-calls empty structure (lines 99-102) --------

test_that("audit_script() silent no-calls path returns correctly shaped calls df", {
  script <- withr::local_tempfile(fileext = ".R")
  writeLines("# only comments\n# pkg::fn in a comment", script)

  report <- suppressMessages(
    audit_script(script, renv = FALSE, verbose = FALSE)
  )
  expect_equal(nrow(report$calls), 0L)
  expect_equal(
    names(report$calls),
    c("file", "line", "pkg", "fn", "pkg_version")
  )
})

# ---- summary.audit_report(): empty calls branch (line 167) -----------------

test_that("summary.audit_report() returns zero counts when report has no calls", {
  script <- withr::local_tempfile(fileext = ".R")
  writeLines("x <- 1", script)

  report <- audit_script(script, renv = FALSE, verbose = FALSE)
  s <- summary(report)

  expect_equal(s$n_calls, 0L)
  expect_equal(s$n_pkgs, 0L)
  expect_equal(length(s$calls_per_pkg), 0L)
})

# ---- .extract_calls(): empty file returns NULL (line 199) ------------------

test_that(".extract_calls() returns NULL for an empty file", {
  f <- withr::local_tempfile(fileext = ".R")
  file.create(f)
  expect_null(reproducr:::.extract_calls(f, pkg_versions = list()))
})

# ---- .extract_calls(): Rmd chunk parsing (lines 207-221) -------------------

test_that(".extract_calls() extracts calls only from inside Rmd code chunks", {
  rmd <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c(
    "# Report",
    "Prose mentioning stats::rnorm which should be ignored.",
    "```{r setup}",
    "x <- stats::rnorm(10)",
    "y <- dplyr::filter(mtcars, cyl == 4)",
    "```",
    "More prose with base::mean — also ignored.",
    "```{r analysis}",
    "z <- stats::lm(mpg ~ wt, data = mtcars)",
    "```"
  ), rmd)

  result <- reproducr:::.extract_calls(rmd, pkg_versions = list())
  expect_false(is.null(result))
  expect_true("stats" %in% result$pkg)
  expect_true("dplyr" %in% result$pkg)
  expect_equal(nrow(result[result$pkg == "base", ]), 0L)
})

test_that(".extract_calls() returns NULL for Rmd with no R chunks", {
  rmd <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c(
    "# Report",
    "Prose with stats::rnorm.",
    "```",
    "non-R code block",
    "```"
  ), rmd)
  expect_null(reproducr:::.extract_calls(rmd, pkg_versions = list()))
})

test_that(".extract_calls() returns NULL for Rmd chunk containing only comments", {
  rmd <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c(
    "```{r}",
    "# stats::rnorm mentioned in comment only",
    "```"
  ), rmd)
  expect_null(reproducr:::.extract_calls(rmd, pkg_versions = list()))
})

# ---- .extract_calls(): NA pkg_version for unlisted package (line 248) ------

test_that(".extract_calls() stores NA pkg_version for packages absent from version list", {
  f <- withr::local_tempfile(fileext = ".R")
  writeLines("x <- unknownpkg::somefn(1)", f)
  result <- reproducr:::.extract_calls(f, pkg_versions = list())
  expect_false(is.null(result))
  expect_true(is.na(result$pkg_version[1L]))
})
