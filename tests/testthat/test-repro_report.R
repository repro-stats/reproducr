test_that("repro_report() errors on non-audit_report input", {
  expect_error(repro_report(list()), "`audit` must be an `audit_report`")
  expect_error(repro_report("text"), "`audit` must be an `audit_report`")
})

test_that("repro_report() returns a character string", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)
  out <- repro_report(r, rs, format = "text", style = "minimal")

  expect_true(is.character(out))
  expect_true(nchar(out) > 0L)
})

test_that("repro_report() returns invisibly for text format", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  ret <- withVisible(repro_report(r, format = "text", style = "minimal"))

  expect_false(ret$visible)
})

# ---- minimal style ---------------------------------------------------------

test_that("repro_report() minimal style contains R version", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "minimal")

  expect_true(grepl(r$env$r_version, out, fixed = TRUE))
})

test_that("repro_report() minimal style contains file count", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "minimal")

  expect_true(grepl("Files scanned|files scanned|1", out))
})

test_that("repro_report() minimal style contains verdict", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  rs <- risk_score(r)
  out <- repro_report(r, rs, format = "text", style = "minimal")

  expect_true(grepl("REPRODUCIBLE|CAUTION|AT RISK|UNKNOWN", out))
})

test_that("repro_report() minimal style includes risk section when risks present", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_risks <- data.frame(
    call = "dplyr::summarise", file = f, line = 1L,
    pkg = "dplyr", fn = "summarise", pkg_version = "1.1.0",
    risk = "medium", check = "changelog",
    description = "test risk entry", reference = "https://example.com",
    stringsAsFactors = FALSE
  )
  class(mock_risks) <- c("risk_report", "data.frame")

  out <- repro_report(report, mock_risks, format = "text", style = "minimal")
  expect_true(grepl("Risks|MEDIUM", out, ignore.case = TRUE))
})

test_that("repro_report() minimal style includes drift section when drift present", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_drift <- data.frame(
    output = "result1", status = "drifted", note = "hash changed",
    stringsAsFactors = FALSE
  )
  class(mock_drift) <- c("drift_report", "data.frame")

  out <- repro_report(report, drift = mock_drift, format = "text", style = "minimal")
  expect_true(grepl("Drift|DRIFTED|drifted", out, ignore.case = TRUE))
})

# ---- academic style --------------------------------------------------------

test_that("repro_report() academic style contains 'R (version'", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "academic")

  expect_true(grepl("R \\(version", out))
})

test_that("repro_report() academic style mentions detected packages", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "academic")

  expect_true(grepl("dplyr", out))
})

test_that("repro_report() academic style with risks mentions concern count", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_risks <- data.frame(
    call = "dplyr::filter", file = f, line = 1L,
    pkg = "dplyr", fn = "filter", pkg_version = "1.1.0",
    risk = "high", check = "changelog",
    description = "test", reference = "https://example.com",
    stringsAsFactors = FALSE
  )
  class(mock_risks) <- c("risk_report", "data.frame")

  out <- repro_report(report, mock_risks, format = "text", style = "academic")
  expect_true(grepl("concern|risk|potential", out, ignore.case = TRUE))
})

test_that("repro_report() academic style with no calls handles gracefully", {
  f <- write_script("x <- 1 + 1")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(report, format = "text", style = "academic")

  expect_true(grepl("no qualified", out, ignore.case = TRUE))
})

test_that("repro_report() academic style is a single prose paragraph", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "academic")
  lines <- strsplit(trimws(out), "\n")[[1]]
  lines <- lines[nchar(trimws(lines)) > 0L]

  expect_true(length(lines) >= 2L)
})

# ---- pharma style ----------------------------------------------------------

test_that("repro_report() pharma style contains 'Sign-off'", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "pharma")

  expect_true(grepl("Sign-off", out))
})

test_that("repro_report() pharma style contains 'Risk register'", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "pharma")

  expect_true(grepl("Risk register|Risk Register", out))
})

test_that("repro_report() pharma style contains 'Execution environment'", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(r, format = "text", style = "pharma")

  expect_true(grepl("Execution environment|execution environment", out))
})

test_that("repro_report() pharma style with risks shows risk register entries", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_risks <- data.frame(
    call = "dplyr::filter", file = f, line = 1L,
    pkg = "dplyr", fn = "filter", pkg_version = "1.1.0",
    risk = "high", check = "changelog",
    description = paste(rep("x", 130L), collapse = ""),
    reference = "https://example.com",
    stringsAsFactors = FALSE
  )
  class(mock_risks) <- c("risk_report", "data.frame")

  out <- repro_report(report, mock_risks, format = "text", style = "pharma")
  expect_true(grepl("HIGH|dplyr::filter", out))
})

test_that("repro_report() pharma style with drift shows drift assessment", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_drift <- data.frame(
    output = "result1", status = "ok", note = "",
    stringsAsFactors = FALSE
  )
  class(mock_drift) <- c("drift_report", "data.frame")

  out <- repro_report(report, drift = mock_drift, format = "text", style = "pharma")
  expect_true(grepl("Drift assessment|drift", out, ignore.case = TRUE))
})

test_that("repro_report() pharma style with no calls shows no calls message", {
  f <- write_script("x <- 1 + 1")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)
  out <- repro_report(report, format = "text", style = "pharma")

  expect_true(grepl("No qualified|no qualified", out, ignore.case = TRUE))
})

# ---- HTML format -----------------------------------------------------------

test_that("repro_report() html format writes a valid HTML file", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  out <- tempfile(fileext = ".html")
  on.exit(unlink(c(f, out)))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "html", style = "minimal", output_file = out)
  expect_true(file.exists(out))
  content <- paste(readLines(out, warn = FALSE), collapse = "")
  expect_true(grepl("<!DOCTYPE html>", content, fixed = TRUE))
  expect_true(grepl("<body>", content, fixed = TRUE))
})

test_that("repro_report() html format file has non-zero size", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  out <- tempfile(fileext = ".html")
  on.exit(unlink(c(f, out)))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "html", style = "pharma", output_file = out)
  expect_true(file.info(out)$size > 0L)
})

test_that("repro_report() html academic style renders correctly", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  out <- tempfile(fileext = ".html")
  on.exit(unlink(c(f, out)))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "html", style = "academic", output_file = out)
  expect_true(file.exists(out))
  content <- paste(readLines(out, warn = FALSE), collapse = "")
  expect_true(grepl("<!DOCTYPE html>", content, fixed = TRUE))
})

# ---- Markdown format -------------------------------------------------------

test_that("repro_report() md format writes a file to disk", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  out <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, out)))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "md", style = "minimal", output_file = out)
  expect_true(file.exists(out))
})

test_that("repro_report() md format contains markdown headings", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  out <- tempfile(fileext = ".md")
  on.exit(unlink(c(f, out)))
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "md", style = "minimal", output_file = out)
  content <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("^#", content, perl = TRUE))
})

test_that("repro_report() uses a default output_file name when none supplied", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit({
    unlink(f)
    unlink("reproducr_report.md", force = TRUE)
    unlink("reproducr_report.html", force = TRUE)
  })
  r <- audit_script(f, renv = FALSE, verbose = FALSE)

  repro_report(r, format = "md", style = "minimal")
  expect_true(file.exists("reproducr_report.md"))
})

# ---- verdict branches ------------------------------------------------------

test_that("repro_report() shows AT RISK verdict for high-risk report", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_risks <- data.frame(
    call = "dplyr::summarise", file = f, line = 1L,
    pkg = "dplyr", fn = "summarise", pkg_version = "1.1.0",
    risk = "high", check = "changelog",
    description = "test high risk entry", reference = "https://example.com",
    stringsAsFactors = FALSE
  )
  class(mock_risks) <- c("risk_report", "data.frame")

  out <- repro_report(report, mock_risks, format = "text", style = "minimal")
  expect_true(grepl("AT RISK", out))
})

test_that("repro_report() shows CAUTION verdict for medium-risk report", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_risks <- data.frame(
    call = "dplyr::summarise", file = f, line = 1L,
    pkg = "dplyr", fn = "summarise", pkg_version = "1.1.0",
    risk = "medium", check = "changelog",
    description = "test medium risk entry", reference = "https://example.com",
    stringsAsFactors = FALSE
  )
  class(mock_risks) <- c("risk_report", "data.frame")

  out <- repro_report(report, mock_risks, format = "text", style = "minimal")
  expect_true(grepl("CAUTION", out))
})

test_that("repro_report() shows UNKNOWN verdict when risks is NULL", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  out <- repro_report(report, risks = NULL, format = "text", style = "minimal")
  expect_true(grepl("unknown|UNKNOWN", out, ignore.case = TRUE))
})

test_that("repro_report() AT RISK when drift detected", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)

  mock_drift <- data.frame(
    output = "result1", status = "drifted", note = "hash changed",
    stringsAsFactors = FALSE
  )
  class(mock_drift) <- c("drift_report", "data.frame")

  out <- repro_report(report,
    risks = NULL, drift = mock_drift,
    format = "text", style = "minimal"
  )
  expect_true(grepl("AT RISK", out))
})

# ---- all styles and formats ------------------------------------------------

test_that("repro_report() renders all styles and formats without error", {
  f <- write_script("x <- dplyr::filter(mtcars, cyl == 4)")
  on.exit(unlink(f))
  report <- audit_script(f, renv = FALSE, verbose = FALSE)
  risks <- risk_score(report)

  out <- repro_report(report, risks, format = "text", style = "academic")
  expect_type(out, "character")

  md_out <- tempfile(fileext = ".md")
  on.exit(unlink(md_out), add = TRUE)
  repro_report(report, risks, format = "md", style = "pharma", output_file = md_out)
  expect_true(file.exists(md_out))

  html_out <- tempfile(fileext = ".html")
  on.exit(unlink(html_out), add = TRUE)
  repro_report(report, risks, format = "html", style = "minimal", output_file = html_out)
  expect_true(file.exists(html_out))

  html_out2 <- tempfile(fileext = ".html")
  on.exit(unlink(html_out2), add = TRUE)
  repro_report(report, risks, format = "html", style = "pharma", output_file = html_out2)
  expect_true(file.exists(html_out2))
})

# ---- .md_to_html internals -------------------------------------------------

test_that(".md_to_html produces valid HTML with title", {
  md <- "# Test\n\nHello world.\n"
  result <- reproducr:::.md_to_html(md, title = "My Report")
  expect_true(grepl("<!DOCTYPE html>", result, fixed = TRUE))
  expect_true(grepl("My Report", result, fixed = TRUE))
  expect_true(grepl("<body>", result, fixed = TRUE))
})

test_that(".md_to_html produces complete HTML document structure", {
  md <- "# Heading\n\nSome text.\n\n## Subheading\n\nMore text.\n"
  result <- reproducr:::.md_to_html(md, title = "Test Report")

  expect_true(grepl("<!DOCTYPE html>", result, fixed = TRUE))
  expect_true(grepl("<title>Test Report</title>", result, fixed = TRUE))
  expect_true(grepl("</html>", result, fixed = TRUE))
  expect_true(grepl("<style>", result, fixed = TRUE))
})

# ---- .md_to_html(): commonmark fallback (lines 376-389) --------------------

test_that(".md_to_html() fallback produces valid HTML when commonmark unavailable", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "commonmark") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  result <- reproducr:::.md_to_html(
    "# Hello\n\n## Section\n\n**bold** and `code`\n\n- item\n\n> quote"
  )
  expect_match(result, "<!DOCTYPE html>")
  expect_match(result, "<h1>")
  expect_match(result, "<h2>")
  expect_match(result, "<strong>")
  expect_match(result, "<code>")
  expect_match(result, "<li>")
  expect_match(result, "<blockquote>")
})

test_that(".md_to_html() fallback emits install suggestion for commonmark", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) {
      if (pkg == "commonmark") FALSE else base::requireNamespace(pkg, ...)
    },
    .package = "base"
  )
  expect_message(reproducr:::.md_to_html("# Hello"), "commonmark")
})

# ---- .render_academic(): no-calls else branch (line 212) -------------------

test_that(".render_academic() returns expected text when audit has no pkg::fn calls", {
  script <- withr::local_tempfile(fileext = ".R")
  writeLines("x <- 1", script)
  report <- audit_script(script, renv = FALSE, verbose = FALSE)
  risks <- risk_score(report)
  verdict <- list(level = "reproducible", summary = "REPRODUCIBLE", emoji = "v")

  result <- reproducr:::.render_academic(report, risks, verdict)
  expect_match(result, "no qualified package calls detected")
})

# ---- .render_pharma(): n_next = 6 branch (line 324) ------------------------

test_that(".render_pharma() uses section 6 for sign-off when drift is supplied", {
  script <- withr::local_tempfile(fileext = ".R")
  writeLines("x <- stats::rnorm(10)", script)
  report <- audit_script(script, renv = FALSE, verbose = FALSE)
  risks <- risk_score(report)

  cf <- withr::local_tempfile()
  certify(outputs = list(x = 1.0), tag = "v1", file = cf)
  drift <- check_drift(list(x = 1.0), against = "v1", file = cf)
  out <- withr::local_tempfile(fileext = ".md")

  result <- repro_report(report, risks,
    drift = drift,
    format = "md", style = "pharma", output_file = out
  )
  expect_match(result, "## 6. Sign-off")
})
