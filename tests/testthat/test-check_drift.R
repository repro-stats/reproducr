test_that("check_drift() returns 'ok' for identical outputs", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)
  outs  <- list(coefs = coef(model), n = nrow(mtcars))

  certify(outs, tag = "base", file = cf)
  result <- check_drift(outs, against = "base", file = cf)

  expect_true(all(result$status == "ok"))
})

test_that("check_drift() returns 'drifted' when outputs change", {
  cf     <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model1 <- lm(mpg ~ wt, data = mtcars)
  model2 <- lm(mpg ~ hp, data = mtcars)

  certify(list(coefs = coef(model1)), tag = "v1", file = cf)
  result <- check_drift(list(coefs = coef(model2)), against = "v1", file = cf)

  expect_true(any(result$status == "drifted"))
})

test_that("check_drift() returns 'missing' for outputs in baseline but not supplied", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)

  certify(list(coefs = coef(model), n = nrow(mtcars)), tag = "v1", file = cf)
  result <- check_drift(list(coefs = coef(model)), against = "v1", file = cf)

  expect_true(any(result$status == "missing"))
  expect_true("n" %in% result$output[result$status == "missing"])
})

test_that("check_drift() returns 'new' for outputs not in baseline", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)

  certify(list(coefs = coef(model)), tag = "v1", file = cf)
  result <- check_drift(
    list(coefs = coef(model), extra = 42L),
    against = "v1", file = cf
  )

  expect_true(any(result$status == "new"))
  expect_true("extra" %in% result$output[result$status == "new"])
})

test_that("check_drift() 'latest' resolves to the most recently added tag", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)
  outs  <- list(coefs = coef(model))

  certify(outs, tag = "v1", file = cf)
  certify(outs, tag = "v2", file = cf)

  expect_message(
    check_drift(outs, against = "latest", file = cf),
    "v2"
  )
})

test_that("check_drift() handles all four statuses simultaneously", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)

  certify(
    list(
      same    = coef(model),
      changed = coef(model),
      removed = 99L
    ),
    tag  = "v1",
    file = cf
  )

  model2 <- lm(mpg ~ hp, data = mtcars)
  result <- check_drift(
    list(
      same    = coef(model),
      changed = coef(model2),
      added   = 42L
    ),
    against = "v1",
    file    = cf
  )

  expect_true(any(result$status == "ok"      & result$output == "same"))
  expect_true(any(result$status == "drifted" & result$output == "changed"))
  expect_true(any(result$status == "missing" & result$output == "removed"))
  expect_true(any(result$status == "new"     & result$output == "added"))
})

test_that("check_drift() returns a data frame with required columns", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)
  outs  <- list(coefs = coef(model))

  certify(outs, tag = "v1", file = cf)
  result <- check_drift(outs, against = "v1", file = cf)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("output", "status", "max_delta", "note") %in% names(result)))
})

test_that("check_drift() errors when no certifications exist", {
  cf <- tempfile()
  expect_error(
    check_drift(list(x = 1L), against = "v1", file = cf),
    "No certifications found"
  )
})

test_that("check_drift() errors on unknown tag", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  expect_error(
    check_drift(list(x = 1L), against = "no_such_tag", file = cf),
    "not found"
  )
})

test_that("check_drift() errors on unnamed outputs", {
  cf <- tempfile()
  expect_error(
    check_drift(list(1, 2), against = "v1", file = cf),
    "fully named"
  )
})

test_that("check_drift() returns invisibly", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)
  outs  <- list(coefs = coef(model))

  certify(outs, tag = "v1", file = cf)
  ret <- withVisible(check_drift(outs, against = "v1", file = cf))

  expect_false(ret$visible)
})

test_that("check_drift() works with diverse R object types", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  outs <- list(
    scalar_int  = 42L,
    scalar_dbl  = 3.14159,
    char_vec    = c("a", "b", "c"),
    logical_vec = c(TRUE, FALSE, TRUE),
    matrix_obj  = matrix(1:9, 3, 3),
    data_frame  = data.frame(x = 1:3, y = letters[1:3]),
    named_list  = list(a = 1, b = 2)
  )

  certify(outs, tag = "types-test", file = cf)
  result <- check_drift(outs, against = "types-test", file = cf)

  expect_true(all(result$status == "ok"))
})

test_that("print.drift_report() outputs expected text", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  model <- lm(mpg ~ wt, data = mtcars)
  outs  <- list(coefs = coef(model))

  certify(outs, tag = "v1", file = cf)
  result <- check_drift(outs, against = "v1", file = cf)

  expect_output(print(result), "reproducr drift report")
  expect_output(print(result), "\\[OK\\]")
})

test_that("print.drift_report() returns its input invisibly", {
  cf    <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))
  outs  <- list(x = 1L)

  certify(outs, tag = "v1", file = cf)
  result <- check_drift(outs, against = "v1", file = cf)
  ret    <- withVisible(print(result))

  expect_false(ret$visible)
})
