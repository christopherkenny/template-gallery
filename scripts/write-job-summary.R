args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"
results_path <- if (length(args) >= 2) args[[2]] else "data/build-results.yml"

suppressPackageStartupMessages(library(yaml))

manifest <- yaml::read_yaml(manifest_path)
results <- yaml::read_yaml(results_path)

entries_by_slug <- setNames(manifest$entries, vapply(manifest$entries, function(entry) entry$slug, character(1)))
result_slugs <- names(results$results %||% list())

status_label <- function(result) {
  if (is.null(result$status)) {
    return("missing")
  }
  result$status
}

mode_label <- function(entry) {
  entry$ci$mode %||% "unknown"
}

lines <- c(
  "## Build Summary",
  "",
  sprintf("- Success: %d", results$summary$success %||% 0L),
  sprintf("- Failure: %d", results$summary$failure %||% 0L),
  sprintf("- Missing: %d", results$summary$missing %||% 0L),
  "- The site is still rendered from the latest run even when some entries fail.",
  "",
  "| Template | Mode | Status | PDF |",
  "| --- | --- | --- | --- |"
)

for (slug in result_slugs) {
  entry <- entries_by_slug[[slug]]
  result <- results$results[[slug]]
  pdf_text <- if (!is.null(result$pdf) && nzchar(result$pdf)) sprintf("[pdf](%s)", result$pdf) else ""
  lines <- c(
    lines,
    sprintf("| %s | %s | %s | %s |", entry$name, mode_label(entry), status_label(result), pdf_text)
  )
}

cat(paste(lines, collapse = "\n"))
