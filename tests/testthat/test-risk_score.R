test_that("risk_score() errors on non-audit_report input", {
  expect_error(risk_score(list()),       "`audit` must be an `audit_report`")
  expect_error(risk_score(data.frame()), "`audit` must be an `audit_report`")
  expect_error(risk_score("a string"),   "`audit` must be an `audit_report`")
})

test_that("risk_score() returns a data frame with required columns", {
  f  <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_s3_class(rs, "data.frame")
  expect_true(all(
    c("file", "line", "call", "pkg_version", "risk", "check", "description", "reference")
    %in% names(rs)
  ))
})

test_that("risk_score() returns empty data frame with correct columns on clean script", {
  f  <- write_script("x <- 1 + 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_equal(nrow(rs), 0L)
  expect_true("risk" %in% names(rs))
  expect_true("check" %in% names(rs))
})

test_that("risk_score() orders results high-risk first", {
  f <- write_script(
    "x <- base::sort(letters)",    # low  (locale_check)
    "y <- stats::rnorm(10)",       # medium (seed_check)
    "z <- readr::read_csv('f')"    # high (changelog) — if version in window
  )
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  if (nrow(rs) > 1L) {
    risk_ints <- c(high = 3L, medium = 2L, low = 1L)[rs$risk]
    expect_true(all(diff(risk_ints) <= 0L))  # non-increasing = high first
  }
})

# ---- changelog check -------------------------------------------------------

test_that("risk_score() changelog check returns 'changelog' in check column", {
  f  <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "changelog")

  if (nrow(rs) > 0L) {
    expect_true(all(rs$check == "changelog"))
  }
})

test_that("risk_score() changelog check does not fire for unknown packages", {
  f  <- write_script("x <- mypkg::myfun(42)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "changelog")

  # mypkg is not in the database — should return no results
  expect_equal(nrow(rs), 0L)
})

# ---- seed check ------------------------------------------------------------

test_that("risk_score() seed_check flags stats::rnorm without set.seed()", {
  f  <- write_script("x <- stats::rnorm(100)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs) > 0L)
  expect_true(any(rs$check == "seed_check"))
  expect_true(any(rs$risk  == "medium"))
})

test_that("risk_score() seed_check flags stats::sample without set.seed()", {
  f  <- write_script("x <- stats::sample(10)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs) > 0L)
  expect_true(any(rs$check == "seed_check"))
})

test_that("risk_score() seed_check does NOT flag rnorm when set.seed() is nearby", {
  f  <- write_script("set.seed(42)", "x <- stats::rnorm(100)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_equal(nrow(rs[rs$check == "seed_check", ]), 0L)
})

test_that("risk_score() seed_check flags rnorm when set.seed() is too far away", {
  # set.seed > 50 lines above the call
  lines <- c("set.seed(42)", rep("x <- 1", 55L), "z <- stats::rnorm(10)")
  f  <- write_script(lines)
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(any(rs$check == "seed_check"))
})

test_that("risk_score() seed_check flags multiple stochastic functions", {
  f <- write_script(
    "x <- stats::rnorm(10)",
    "y <- stats::rbinom(10, 1, 0.5)",
    "z <- stats::runif(10)"
  )
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs[rs$check == "seed_check", ]) >= 3L)
})

# ---- locale check ----------------------------------------------------------

test_that("risk_score() locale_check flags base::sort", {
  f  <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(any(rs$check == "locale_check"))
  expect_true(any(rs$risk  == "low"))
})

test_that("risk_score() locale_check flags base::format", {
  f  <- write_script("x <- base::format(3.14159, digits = 3)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(any(rs$check == "locale_check"))
})

test_that("risk_score() locale_check returns only locale_check rows when isolated", {
  f  <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(all(rs$check == "locale_check"))
})

# ---- min_risk filter -------------------------------------------------------

test_that("risk_score() min_risk = 'high' excludes medium and low", {
  f <- write_script(
    "x <- base::sort(letters)",
    "y <- stats::rnorm(10)"
  )
  on.exit(unlink(f))
  r    <- audit_script(f, renv = FALSE, verbose = FALSE)
  high <- risk_score(r, min_risk = "high")

  if (nrow(high) > 0L) {
    expect_true(all(high$risk == "high"))
  }
})

test_that("risk_score() min_risk = 'low' returns all risks", {
  f <- write_script(
    "x <- base::sort(letters)",
    "y <- stats::rnorm(10)"
  )
  on.exit(unlink(f))
  r   <- audit_script(f, renv = FALSE, verbose = FALSE)
  all <- risk_score(r, min_risk = "low")
  hi  <- risk_score(r, min_risk = "high")

  expect_true(nrow(all) >= nrow(hi))
})

# ---- methods selection -----------------------------------------------------

test_that("risk_score() runs only the requested method(s)", {
  f  <- write_script("x <- stats::rnorm(10)", "y <- base::sort(letters)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)

  rs_seed   <- risk_score(r, methods = "seed_check")
  rs_locale <- risk_score(r, methods = "locale_check")

  expect_true(all(rs_seed$check   == "seed_check"))
  expect_true(all(rs_locale$check == "locale_check"))
})

# ---- S3 methods ------------------------------------------------------------

test_that("print.risk_report() outputs 'No risks detected' for empty report", {
  f  <- write_script("x <- 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_output(print(rs), "No risks detected")
})

test_that("print.risk_report() outputs risk counts for non-empty report", {
  f  <- write_script("x <- stats::rnorm(10)", "y <- base::sort(letters)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  if (nrow(rs) > 0L) {
    expect_output(print(rs), "MEDIUM|LOW|HIGH")
  }
})

test_that("print.risk_report() returns its input invisibly", {
  f  <- write_script("x <- 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  ret <- withVisible(print(rs))
  expect_false(ret$visible)
})

test_that("as.data.frame.risk_report() drops the risk_report class", {
  f  <- write_script("x <- 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)
  df <- as.data.frame(rs)

  expect_false(inherits(df, "risk_report"))
  expect_true(is.data.frame(df))
})
