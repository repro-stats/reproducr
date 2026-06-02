#!/usr/bin/env Rscript
# sync_db.R
# Compile entries from reproducr-db into R/breaking_changes_db.R
#
# Usage (from reproducr package root):
#   Rscript data-raw/sync_db.R
#
# Requires reproducr-db to be cloned alongside the reproducr repo:
#   ../reproducr-db/entries/
#
# Or set the REPRODUCR_DB_PATH environment variable to point to
# the reproducr-db clone.

library(jsonlite)

db_path <- Sys.getenv(
  "REPRODUCR_DB_PATH",
  unset = file.path(dirname(getwd()), "reproducr-db")
)

entries_path <- file.path(db_path, "entries")

if (!dir.exists(entries_path)) {
  stop(
    "reproducr-db not found at: ", entries_path, "\n",
    "Clone it with:\n",
    "  git clone https://github.com/reproducr-dev/reproducr-db ../reproducr-db\n",
    "Or set REPRODUCR_DB_PATH to the correct path."
  )
}

# ---- Read all JSON entries --------------------------------------------------

json_files <- list.files(entries_path, pattern = "\\.json$",
                         recursive = TRUE, full.names = TRUE)

cat(sprintf("Found %d entry files in %s\n", length(json_files), entries_path))

entries <- lapply(json_files, function(f) {
  tryCatch(
    jsonlite::fromJSON(f, simplifyVector = TRUE),
    error = function(e) {
      warning("Failed to parse: ", f, " — ", conditionMessage(e))
      NULL
    }
  )
})
entries <- Filter(Negate(is.null), entries)
cat(sprintf("Successfully parsed %d entries\n", length(entries)))

# ---- Group by pkg::fn -------------------------------------------------------

keys <- vapply(entries, function(e) paste0(e$pkg, "::", e$fn), character(1L))
grouped <- split(entries, keys)

# Sort keys alphabetically by package then function
grouped <- grouped[order(names(grouped))]

# ---- Generate R code --------------------------------------------------------

header <- readLines("R/breaking_changes_db.R")
# Keep everything up to and including the .BREAKING_CHANGES_DB <- list( line
db_start <- grep("^\\.BREAKING_CHANGES_DB <- list\\(", header)
if (length(db_start) == 0L) stop("Could not find .BREAKING_CHANGES_DB in R/breaking_changes_db.R")
preamble <- header[seq_len(db_start)]

# Group entries by package for section comments
pkgs <- unique(vapply(entries, `[[`, character(1L), "pkg"))
pkgs <- sort(pkgs)

lines <- c(preamble, "")

for (pkg in pkgs) {
  pkg_keys <- names(grouped)[startsWith(names(grouped), paste0(pkg, "::"))]
  if (length(pkg_keys) == 0L) next

  lines <- c(lines, sprintf("  # ---- %s %s", pkg,
                              paste(rep("-", max(1, 66 - nchar(pkg))),
                                    collapse = "")))

  for (key in pkg_keys) {
    group <- grouped[[key]]
    fn    <- group[[1L]]$fn

    lines <- c(lines, "", sprintf('  "%s::%s" = list(', pkg, fn))

    for (i in seq_along(group)) {
      e <- group[[i]]
      comma <- if (i < length(group)) "," else ""

      # Word-wrap description at 70 chars using paste0
      desc_clean <- gsub('"', '\\\\"', e$description)
      desc_lines <- strwrap(desc_clean, width = 60)
      if (length(desc_lines) == 1L) {
        desc_r <- sprintf('"%s"', desc_lines)
      } else {
        parts <- sprintf('"%s"', desc_lines)
        parts[-length(parts)] <- paste0(parts[-length(parts)], ",")
        desc_r <- paste0(
          "paste0(\n        ",
          paste(parts, collapse = "\n        "),
          "\n      )"
        )
      }

      lines <- c(
        lines,
        "    list(",
        sprintf('      from_version = "%s",', e$from_version),
        sprintf('      to_version   = "%s",', e$to_version),
        sprintf('      risk         = "%s",', e$risk),
        sprintf('      description  = %s,', desc_r),
        sprintf('      reference = "%s"', e$reference),
        sprintf("    )%s", comma)
      )
    }
    lines <- c(lines, "  ),", "")
  }
}

# Close the list and add trailing content
lines <- c(lines, ")")
lines <- c(lines, "")

# Write output
out_path <- "R/breaking_changes_db.R"
writeLines(lines, out_path)
cat(sprintf("\nWritten %d lines to %s\n", length(lines), out_path))
cat(sprintf("Database now contains %d entries across %d pkg::fn keys\n",
            length(entries), length(grouped)))
