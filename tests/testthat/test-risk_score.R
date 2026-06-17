test_that("risk_score() errors on non-audit_report input", {
  expect_error(risk_score(list()), "`audit` must be an `audit_report`")
  expect_error(risk_score(data.frame()), "`audit` must be an `audit_report`")
  expect_error(risk_score("a string"), "`audit` must be an `audit_report`")
})

test_that("risk_score() returns a data frame with required columns", {
  f <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_s3_class(rs, "data.frame")
  expect_true(all(c(
    "file", "line", "call", "pkg_version", "risk", "check",
    "description", "reference"
  ) %in% names(rs)))
})

test_that("risk_score() returns empty data frame with correct columns on clean script", {
  f <- write_script("x <- 1 + 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_equal(nrow(rs), 0L)
  expect_true("risk" %in% names(rs))
  expect_true("check" %in% names(rs))
})

test_that("risk_score() orders results high-risk first", {
  f <- write_script(
    "x <- base::sort(letters)",
    "y <- stats::rnorm(10)",
    "z <- readr::read_csv('f')"
  )
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  if (nrow(rs) > 1L) {
    risk_ints <- c(high = 3L, medium = 2L, low = 1L)[rs$risk]
    expect_true(all(diff(risk_ints) <= 0L))
  }
})

# ---- changelog check -------------------------------------------------------

test_that("risk_score() changelog check returns 'changelog' in check column", {
  f <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "changelog")

  if (nrow(rs) > 0L) expect_true(all(rs$check == "changelog"))
})

test_that("risk_score() changelog check does not fire for unknown packages", {
  f <- write_script("x <- mypkg::myfun(42)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "changelog")

  expect_equal(nrow(rs), 0L)
})

# ---- seed check ------------------------------------------------------------

test_that("risk_score() seed_check flags stats::rnorm without set.seed()", {
  f <- write_script("x <- stats::rnorm(100)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs) > 0L)
  expect_true(any(rs$check == "seed_check"))
  expect_true(any(rs$risk == "medium"))
})

test_that("risk_score() seed_check flags stats::sample without set.seed()", {
  f <- write_script("x <- stats::sample(10)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs) > 0L)
  expect_true(any(rs$check == "seed_check"))
})

test_that("risk_score() seed_check does NOT flag rnorm when set.seed() is nearby", {
  f <- write_script("set.seed(237)", "x <- stats::rnorm(100)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_equal(nrow(rs[rs$check == "seed_check", ]), 0L)
})

test_that("risk_score() seed_check flags rnorm when set.seed() is too far away", {
  lines <- c("set.seed(237)", rep("x <- 1", 55L), "z <- stats::rnorm(10)")
  f <- write_script(lines)
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
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
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  expect_true(nrow(rs[rs$check == "seed_check", ]) >= 3L)
})

# ---- locale check ----------------------------------------------------------

test_that("risk_score() locale_check flags base::sort", {
  f <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(any(rs$check == "locale_check"))
  expect_true(any(rs$risk == "low"))
})

test_that("risk_score() locale_check flags base::format", {
  f <- write_script("x <- base::format(3.14159, digits = 3)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(any(rs$check == "locale_check"))
})

test_that("risk_score() locale_check returns only locale_check rows when isolated", {
  f <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(all(rs$check == "locale_check"))
})

# ---- min_risk filter -------------------------------------------------------

test_that("risk_score() min_risk = 'high' excludes medium and low", {
  f <- write_script("x <- base::sort(letters)", "y <- stats::rnorm(10)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  high <- risk_score(r, min_risk = "high")

  expect_true(nrow(high) == 0L || all(high$risk == "high"))
})

test_that("risk_score() min_risk = 'low' returns all risks", {
  f <- write_script("x <- base::sort(letters)", "y <- stats::rnorm(10)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  all_risks <- risk_score(r, min_risk = "low")
  hi <- risk_score(r, min_risk = "high")

  expect_true(nrow(all_risks) >= nrow(hi))
})

# ---- methods selection -----------------------------------------------------

test_that("risk_score() runs only the requested method(s)", {
  f <- write_script("x <- stats::rnorm(10)", "y <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs_seed <- risk_score(r, methods = "seed_check")
  rs_locale <- risk_score(r, methods = "locale_check")

  expect_true(all(rs_seed$check == "seed_check"))
  expect_true(all(rs_locale$check == "locale_check"))
})

# ---- major_version_grace ---------------------------------------------------

test_that("risk_score() major_version_grace suppresses entries past transition", {
  f <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  idx <- r$calls$pkg == "dplyr" & r$calls$fn == "summarise"
  skip_if(!any(idx), "dplyr::summarise not detected in audit")

  r$calls$pkg_version[idx] <- "3.0.0"
  rs_grace_1   <- risk_score(r, methods = "changelog", major_version_grace = 1L)
  rs_grace_inf <- risk_score(r, methods = "changelog", major_version_grace = Inf)

  dplyr_grace    <- rs_grace_1[rs_grace_1$call == "dplyr::summarise", ]
  dplyr_no_grace <- rs_grace_inf[rs_grace_inf$call == "dplyr::summarise", ]

  expect_equal(nrow(dplyr_grace), 0L)
  expect_true(is.data.frame(dplyr_no_grace))
})

test_that("risk_score() major_version_grace = Inf disables suppression", {
  f <- write_script("x <- dplyr::summarise(mtcars, n = dplyr::n())")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  rs <- risk_score(r, methods = "changelog", major_version_grace = Inf)
  expect_s3_class(rs, "data.frame")
})

test_that(".major_version_gap() computes correct major version difference", {
  expect_equal(reproducr:::.major_version_gap("4.7.2", "3.0.2"), 1L)
  expect_equal(reproducr:::.major_version_gap("5.0.0", "3.0.0"), 2L)
  expect_equal(reproducr:::.major_version_gap("1.1.0", "1.0.0"), 0L)
  expect_equal(reproducr:::.major_version_gap("2.0.0", "2.0.0"), 0L)
})

test_that(".major_version_gap() returns NA for invalid version strings", {
  expect_true(is.na(reproducr:::.major_version_gap("not-a-version", "1.0.0")))
  expect_true(is.na(reproducr:::.major_version_gap("1.0.0", "not-a-version")))
})

# ---- S3 methods ------------------------------------------------------------

test_that("print.risk_report() outputs 'No risks detected' for empty report", {
  f <- write_script("x <- 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  expect_output(print(rs), "No risks detected")
})

test_that("print.risk_report() outputs risk counts for non-empty report", {
  f <- write_script("x <- stats::rnorm(10)", "y <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  if (nrow(rs) > 0L) expect_output(print(rs), "MEDIUM|LOW|HIGH")
})

test_that("print.risk_report() returns its input invisibly", {
  f <- write_script("x <- 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  ret <- withVisible(print(rs))
  expect_false(ret$visible)
})

test_that("as.data.frame.risk_report() drops the risk_report class", {
  f <- write_script("x <- 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)
  df <- as.data.frame(rs)

  expect_false(inherits(df, "risk_report"))
  expect_true(is.data.frame(df))
})

# ---- [.risk_report(): class stripping (line 351) ---------------------------

test_that("[.risk_report() strips class when required columns are removed", {
  # base::sort always triggers locale_check — guarantees at least one risk row
  f <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(nrow(rs) > 0L)
  sub <- rs[, c("call", "risk"), drop = FALSE]
  expect_false(inherits(sub, "risk_report"))
  expect_true(is.data.frame(sub))
})

test_that("[.risk_report() preserves class when all required columns retained", {
  f <- write_script("x <- base::sort(letters)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "locale_check")

  expect_true(nrow(rs) > 0L)
  sub <- rs[1L, , drop = FALSE]
  expect_s3_class(sub, "risk_report")
})
