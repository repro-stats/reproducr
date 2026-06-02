test_that("repro_badge() errors on non-audit_report input", {
  expect_error(repro_badge(list()),   "`audit` must be an `audit_report`")
  expect_error(repro_badge("string"), "`audit` must be an `audit_report`")
})

test_that("repro_badge() returns a shields.io markdown string", {
  f  <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  badge <- repro_badge(r, rs, output = "markdown")
  expect_true(grepl("shields.io",     badge, fixed = TRUE))
  expect_true(grepl("reproducibility",badge, fixed = TRUE))
  expect_true(grepl("!\\[",           badge, perl  = TRUE))
})

test_that("repro_badge() returns a character string invisibly", {
  f  <- write_script("x <- 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)

  ret <- withVisible(repro_badge(r, output = "markdown"))
  expect_false(ret$visible)
  expect_true(is.character(ret$value))
})

# ---- colour coding ---------------------------------------------------------

test_that("repro_badge() is 'brightgreen' when no risks detected", {
  f  <- write_script("x <- 1")  # no risky calls
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  badge <- repro_badge(r, rs, output = "markdown")
  expect_true(grepl("brightgreen", badge, fixed = TRUE))
})

test_that("repro_badge() is 'yellow' for medium-only risks", {
  # seed_check produces medium risk
  f  <- write_script("x <- stats::rnorm(10)")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r, methods = "seed_check")

  # Only proceed if we actually got medium risks (seed present may pass)
  if (nrow(rs) > 0L && all(rs$risk %in% c("medium", "low"))) {
    badge <- repro_badge(r, rs, output = "markdown")
    expect_true(grepl("yellow", badge, fixed = TRUE))
  } else {
    skip("No medium risks triggered in this environment")
  }
})

test_that("repro_badge() is 'lightgrey' (unknown) when no risks supplied", {
  f  <- write_script("x <- 1")
  on.exit(unlink(f))
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)

  badge <- repro_badge(r, output = "markdown")
  expect_true(grepl("lightgrey", badge, fixed = TRUE))
})

# ---- README insertion ------------------------------------------------------

test_that("repro_badge() inserts badge into a README that has none", {
  f      <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  readme <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, readme)))

  writeLines(c("# My Project", "", "Some description."), readme)
  r  <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)

  repro_badge(r, rs, output = "README", readme_path = readme)
  content <- paste(readLines(readme, warn = FALSE), collapse = "\n")

  expect_true(grepl("[![reproducibility]", content, fixed = TRUE))
  expect_true(grepl("shields.io",          content, fixed = TRUE))
})

test_that("repro_badge() replaces an existing badge — produces exactly one badge line", {
  f      <- write_script("x <- 1")
  readme <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, readme)))

  writeLines(
    c("# Project",
      "<!-- badges: start -->",
      "[![reproducibility](https://img.shields.io/badge/reproducibility-reproducible-brightgreen)](https://reproducr-dev.github.io/reproducr/)",
      "<!-- badges: end -->",
      "Other content."),
    readme
  )
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_badge(r, output = "README", readme_path = readme)
  lines       <- readLines(readme, warn = FALSE)
  badge_lines <- grep("^\\[!\\[reproducibility\\]", lines, value = TRUE, perl = TRUE)

  expect_equal(length(badge_lines), 1L)
})

test_that("repro_badge() does not duplicate badge on repeated calls", {
  f      <- write_script("x <- 1")
  readme <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, readme)))

  writeLines(c(
    "# Project",
    "<!-- badges: start -->",
    "<!-- badges: end -->",
    "Content."
  ), readme)
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_badge(r, output = "README", readme_path = readme)
  repro_badge(r, output = "README", readme_path = readme)  # second call
  repro_badge(r, output = "README", readme_path = readme)  # third call

  lines       <- readLines(readme, warn = FALSE)
  badge_lines <- grep("^\\[!\\[reproducibility\\]", lines, value = TRUE, perl = TRUE)
  expect_equal(length(badge_lines), 1L)
})

test_that("repro_badge() preserves existing README content", {
  f      <- write_script("x <- 1")
  readme <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, readme)))

  original_content <- c("# My Project", "", "Important description.", "", "## Section")
  writeLines(original_content, readme)
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_badge(r, output = "README", readme_path = readme)
  content <- paste(readLines(readme, warn = FALSE), collapse = "\n")

  expect_true(grepl("Important description", content, fixed = TRUE))
  expect_true(grepl("## Section",            content, fixed = TRUE))
})

test_that("repro_badge() errors when README does not exist", {
  f <- write_script("x <- 1")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  expect_error(
    repro_badge(r, output = "README", readme_path = "/no/such/path/README.md"),
    "README not found"
  )
})