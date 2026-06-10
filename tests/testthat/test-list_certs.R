test_that("list_certs() returns a data frame with required columns", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  lc <- list_certs(file = cf)

  expect_true(is.data.frame(lc))
  expect_true(all(c("tag", "timestamp", "r_version", "os", "n_outputs", "script")
  %in% names(lc)))
})

test_that("list_certs() returns one row per certification", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  certify(list(x = 2L), tag = "v2", file = cf)
  certify(list(x = 3L), tag = "v3", file = cf)
  lc <- list_certs(file = cf)

  expect_equal(nrow(lc), 3L)
})

test_that("list_certs() tag column matches the tags passed to certify()", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "alpha", file = cf)
  certify(list(x = 2L), tag = "beta", file = cf)
  certify(list(x = 3L), tag = "gamma-3", file = cf)
  lc <- list_certs(file = cf)

  expect_true("alpha" %in% lc$tag)
  expect_true("beta" %in% lc$tag)
  expect_true("gamma-3" %in% lc$tag)
})

test_that("list_certs() n_outputs column is correct", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(a = 1L, b = 2L, c = 3L), tag = "three", file = cf)
  certify(list(a = 1L), tag = "one", file = cf)
  lc <- list_certs(file = cf)

  expect_equal(lc$n_outputs[lc$tag == "three"], 3L)
  expect_equal(lc$n_outputs[lc$tag == "one"], 1L)
})

test_that("list_certs() script column is NA when no script was supplied", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", file = cf)
  lc <- list_certs(file = cf)

  expect_true(is.na(lc$script[lc$tag == "v1"]))
})

test_that("list_certs() script column records the supplied script path", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "v1", script = "my_analysis.R", file = cf)
  lc <- list_certs(file = cf)

  expect_equal(lc$script[lc$tag == "v1"], "my_analysis.R")
})

test_that("list_certs() returns an empty data frame when no file exists", {
  cf <- tempfile()
  # No certification file created — should not error

  expect_message(lc <- list_certs(file = cf), "no certifications found")
  expect_true(is.data.frame(lc))
  expect_equal(nrow(lc), 0L)
  expect_true("tag" %in% names(lc))
})

test_that("list_certs() preserves insertion order", {
  cf <- tempfile()
  on.exit(unlink(paste0(cf, ".rds"), force = TRUE))

  certify(list(x = 1L), tag = "first", file = cf)
  certify(list(x = 2L), tag = "second", file = cf)
  certify(list(x = 3L), tag = "third", file = cf)
  lc <- list_certs(file = cf)

  expect_equal(lc$tag, c("first", "second", "third"))
})
