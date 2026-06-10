#' Generate a reproducibility status badge
#'
#' @description
#' Produces a [shields.io](https://shields.io) Markdown badge reflecting the
#' current reproducibility status of a project. The badge is colour-coded:
#'
#' - **Green** (`reproducible`) -- no risks detected.
#' - **Yellow** (`caution`) -- medium-severity risks only.
#' - **Red** (`at risk`) -- one or more high-severity risks or drifted outputs.
#' - **Grey** (`unknown`) -- no risk information supplied.
#'
#' Can be inserted automatically into a `README.md` (e.g. from a GitHub
#' Actions workflow).
#'
#' @param audit An `audit_report` from [reproducr::audit_script()].
#' @param risks A `risk_report` from [reproducr::risk_score()]. Optional.
#' @param drift A `drift_report` from [reproducr::check_drift()]. Optional.
#' @param output `character(1)`. `"markdown"` (return the badge string) or
#'   `"README"` (insert/update the badge in `README.md`). Default `"markdown"`.
#' @param readme_path `character(1)`. Path to the README file when
#'   `output = "README"`. Default `"README.md"`.
#'
#' @return Invisibly returns the badge Markdown string.
#'
#' @seealso [reproducr::repro_report()], [reproducr::risk_score()],
#'   [reproducr::check_drift()]
#'
#' @examples
#' script <- tempfile(fileext = ".R")
#' writeLines("x <- dplyr::filter(mtcars, cyl == 4)", script)
#' report <- audit_script(script, renv = FALSE, verbose = FALSE)
#' risks <- risk_score(report)
#'
#' badge <- repro_badge(report, risks)
#' cat(badge)
#'
#' @export
repro_badge <- function(audit,
                        risks = NULL,
                        drift = NULL,
                        output = "markdown",
                        readme_path = "README.md") {
  if (!inherits(audit, "audit_report")) {
    stop("`audit` must be an `audit_report` object from `audit_script()`.",
      call. = FALSE
    )
  }
  output <- match.arg(output, c("markdown", "README"))

  verdict <- .compute_verdict(risks, drift)

  badge_meta <- list(
    reproducible = list(label = "reproducible", color = "brightgreen"),
    caution      = list(label = "caution", color = "yellow"),
    at_risk      = list(label = "at%20risk", color = "red"),
    unknown      = list(label = "unknown", color = "lightgrey")
  )[[verdict$level]]

  badge_url <- sprintf(
    "https://img.shields.io/badge/reproducibility-%s-%s",
    badge_meta$label, badge_meta$color
  )
  # Linked badge: [![alt](img)](link) -- standard tidyverse convention
  badge_md <- sprintf(
    "[![reproducibility](%s)](https://repro-stats.github.io/reproducr/)",
    badge_url
  )

  if (output == "README") {
    if (!file.exists(readme_path)) {
      stop("README not found at '", readme_path, "'. ",
        "Create the file first or set readme_path.",
        call. = FALSE
      )
    }
    lines <- readLines(readme_path, warn = FALSE)

    # Replace existing reproducibility badge line
    badge_line_idx <- grep("^\\[!\\[reproducibility\\]", lines, perl = TRUE)

    if (length(badge_line_idx) > 0L) {
      lines[badge_line_idx[[1L]]] <- badge_md
    } else {
      # Insert after <!-- badges: start --> if present
      start_idx <- grep("<!-- badges: start -->", lines, fixed = TRUE)
      if (length(start_idx) > 0L) {
        lines <- c(
          lines[seq_len(start_idx[[1L]])],
          badge_md,
          lines[seq(start_idx[[1L]] + 1L, length(lines))]
        )
      } else {
        lines <- c(badge_md, "", lines)
      }
    }

    writeLines(lines, readme_path)
    message("reproducr: badge updated in '", readme_path, "'")
  } else {
    cat(badge_md, "\n")
  }

  invisible(badge_md)
}
