test_that("certify() writes a .rds file to disk", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  model <- lm(mpg ~ wt, data = mtcars)
  certify(list(coefs = coef(model)), tag = "v1", file = cf)

  expect_true(file.exists(paste0(cf, ".rds")))
})

test_that("certify() stores the correct tag in the record", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 42L), tag = "my-tag", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_true("my-tag" %in% names(certs))
  expect_equal(certs[["my-tag"]]$tag, "my-tag")
})

test_that("certify() stores the correct number of outputs", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  model <- lm(mpg ~ wt, data = mtcars)
  certify(
    list(coefs = coef(model), r2 = summary(model)$r.squared, n = nrow(mtcars)),
    tag = "v1",
    file = cf
  )
  certs <- readRDS(paste0(cf, ".rds"))

  expect_equal(certs[["v1"]]$n_outputs, 3L)
})

test_that("certify() stores R version and OS in the record", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_false(is.null(certs[["v1"]]$r_version))
  expect_false(is.null(certs[["v1"]]$os))
})

test_that("certify() stores the script path when supplied", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", script = "analysis.R", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_equal(certs[["v1"]]$script, "analysis.R")
})

test_that("certify() accumulates multiple tags in the same file", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  certify(list(x = 2L), tag = "v2", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_true("v1" %in% names(certs))
  expect_true("v2" %in% names(certs))
  expect_equal(length(certs), 2L)
})

test_that("certify() errors on unnamed outputs", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  expect_error(certify(list(1, 2, 3), tag = "v1", file = cf), "fully named")
  expect_error(certify(list(a = 1, 2), tag = "v1", file = cf), "fully named")
})

test_that("certify() errors on empty outputs list", {
  cf <- tempfile()
  expect_error(certify(list(), tag = "v1", file = cf))
})

test_that("certify() errors on missing tag", {
  cf <- tempfile()
  expect_error(certify(list(x = 1), file = cf))
})

test_that("certify() errors on empty string tag", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  expect_error(certify(list(x = 1), tag = "", file = cf))
})

test_that("certify() errors on non-list outputs", {
  cf <- tempfile()
  expect_error(certify(c(a = 1, b = 2), tag = "v1", file = cf))
})

test_that("certify() errors on non-character script argument", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  expect_error(certify(list(x = 1), tag = "v1", script = 42, file = cf))
})

test_that("certify() warns and overwrites on duplicate tag", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "dup", file = cf)
  expect_warning(
    certify(list(x = 99L), tag = "dup", file = cf),
    "already exists"
  )

  certs <- readRDS(paste0(cf, ".rds"))
  expect_equal(length(certs), 1L)
})

test_that("certify() returns the certification record invisibly", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  ret <- withVisible(certify(list(x = 1L), tag = "v1", file = cf))
  expect_false(ret$visible)
  expect_true(is.list(ret$value))
  expect_equal(ret$value$tag, "v1")
})

test_that("certify() hashes differ for different objects", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "a", file = cf)
  certify(list(x = 99L), tag = "b", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_false(identical(certs[["a"]]$hashes$x, certs[["b"]]$hashes$x))
})

test_that("certify() hashes are identical for identical objects", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  obj <- list(a = 1:10, b = "hello")
  certify(obj, tag = "run1", file = cf)
  certify(obj, tag = "run2", file = cf)
  certs <- readRDS(paste0(cf, ".rds"))

  expect_identical(certs[["run1"]]$hashes, certs[["run2"]]$hashes)
})

# ---- certify(): hash warning path (lines 91-94) -----------------------------

test_that("certify() warns and stores NA hash when an output cannot be hashed", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  local_mocked_bindings(
    .hash_object = function(obj) stop("mocked hash failure"),
    .package = "reproducr"
  )

  expect_warning(
    certify(list(x = 42L), tag = "v1", file = cf),
    "Could not hash"
  )

  certs <- readRDS(paste0(cf, ".rds"))
  expect_true(is.na(certs[["v1"]]$hashes$x))
})

# ---- certify(): values field (0.2.1) ----------------------------------------

test_that("certify() stores raw values alongside hashes", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  model <- lm(mpg ~ wt, data = mtcars)
  certify(
    outputs = list(coefs = coef(model), n = nrow(mtcars)),
    tag     = "v1",
    file    = cf
  )
  certs <- readRDS(paste0(cf, ".rds"))

  expect_false(is.null(certs[["v1"]]$values))
  expect_named(certs[["v1"]]$values, c("coefs", "n"))
  expect_equal(certs[["v1"]]$values$n, nrow(mtcars))
})

# ---- check_drift(): tolerance comparison (0.2.1) ----------------------------

test_that("check_drift() marks numeric output ok when delta <= tolerance", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = 1.0000000000000), tag = "v1", file = cf)

  result <- check_drift(
    outputs = list(x = 1.0000000000001),
    against = "v1",
    file    = cf
  )
  expect_equal(result$status[result$output == "x"], "ok")
  expect_true(result$max_delta[result$output == "x"] > 0)
  expect_match(result$note[result$output == "x"], "Within tolerance")
})

test_that("check_drift() respects tolerance = 0 (exact match only)", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = 1.0), tag = "v1", file = cf)

  result <- check_drift(
    outputs   = list(x = 1.0000000000001),
    against   = "v1",
    file      = cf,
    tolerance = 0
  )
  expect_equal(result$status[result$output == "x"], "drifted")
})

test_that("check_drift() reports drifted with delta when change exceeds tolerance", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = 1.0), tag = "v1", file = cf)

  result <- check_drift(
    outputs = list(x = 2.0),
    against = "v1",
    file    = cf
  )
  expect_equal(result$status[result$output == "x"], "drifted")
  expect_equal(result$max_delta[result$output == "x"], 1.0)
  expect_match(result$note[result$output == "x"], "Numeric drift")
  expect_match(result$note[result$output == "x"], "tolerance")
})

test_that("check_drift() handles NaN introduced in current output", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = 1.0), tag = "v1", file = cf)

  # max(abs(NaN), na.rm = TRUE) returns -Inf with a base R warning; suppress it
  result <- suppressWarnings(
    check_drift(outputs = list(x = NaN), against = "v1", file = cf)
  )
  expect_equal(result$status[result$output == "x"], "drifted")
  expect_match(result$note[result$output == "x"], "non-finite")
})

test_that("check_drift() handles Inf introduced in current output", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = 1.0), tag = "v1", file = cf)

  result <- check_drift(outputs = list(x = Inf), against = "v1", file = cf)
  expect_equal(result$status[result$output == "x"], "drifted")
  expect_match(result$note[result$output == "x"], "non-finite")
})

test_that("check_drift() reports drifted with length note when vector length changes", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(outputs = list(x = c(1.0, 2.0, 3.0)), tag = "v1", file = cf)

  result <- check_drift(
    outputs = list(x = c(1.0, 2.0)),
    against = "v1",
    file    = cf
  )
  expect_equal(result$status[result$output == "x"], "drifted")
  expect_match(result$note[result$output == "x"], "length changed")
  expect_match(result$note[result$output == "x"], "3")
  expect_match(result$note[result$output == "x"], "2")
})

test_that("check_drift() degrades gracefully when baseline has no values field", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  old_record <- list(
    v1 = list(
      tag          = "v1",
      timestamp    = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      hashes       = list(x = "abc123"),
      values       = NULL,
      n_outputs    = 1L,
      output_names = "x"
    )
  )
  saveRDS(old_record, paste0(cf, ".rds"))

  result <- check_drift(
    outputs = list(x = 99.0),
    against = "v1",
    file    = cf
  )
  expect_equal(result$status[result$output == "x"], "drifted")
  expect_match(result$note[result$output == "x"], "re-run certify")
})

# ---- print.drift_report() (lines 434-435, 448, 451, 454) --------------------

test_that("print.drift_report() handles an empty report", {
  empty <- structure(
    data.frame(
      output = character(0),
      status = character(0),
      max_delta = numeric(0),
      note = character(0),
      stringsAsFactors = FALSE
    ),
    class = c("drift_report", "data.frame")
  )
  out <- capture.output(print(empty))
  expect_true(any(grepl("empty", out)))
})

test_that("print.drift_report() prints max_delta when non-zero", {
  rep <- structure(
    data.frame(
      output = "coefs",
      status = "ok",
      max_delta = 1.23e-12,
      note = "",
      stringsAsFactors = FALSE
    ),
    class = c("drift_report", "data.frame")
  )
  out <- paste(capture.output(print(rep)), collapse = "\n")
  expect_match(out, "max delta")
  expect_match(out, "1.23e-12")
})

test_that("print.drift_report() prints note when non-empty", {
  rep <- structure(
    data.frame(
      output = "x",
      status = "drifted",
      max_delta = 0.5,
      note = "Numeric drift (max |delta|: 0.5, tolerance: 1e-10).",
      stringsAsFactors = FALSE
    ),
    class = c("drift_report", "data.frame")
  )
  out <- paste(capture.output(print(rep)), collapse = "\n")
  expect_match(out, "Numeric drift")
})

test_that("print.drift_report() returns invisibly", {
  rep <- structure(
    data.frame(
      output = "x",
      status = "ok",
      max_delta = 0,
      note = "",
      stringsAsFactors = FALSE
    ),
    class = c("drift_report", "data.frame")
  )
  ret <- withVisible(print(rep))
  expect_false(ret$visible)
})
