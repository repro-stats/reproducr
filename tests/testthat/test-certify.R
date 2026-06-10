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
  expect_equal(length(certs), 1L) # still one tag, not two
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
