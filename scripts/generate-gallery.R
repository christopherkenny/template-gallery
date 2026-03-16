args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"
results_path <- if (length(args) >= 2) args[[2]] else "data/build-results.yml"
output_path <- if (length(args) >= 3) args[[3]] else "index.qmd"

suppressPackageStartupMessages(library(yaml))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

manifest <- yaml::read_yaml(manifest_path)
build_results <- if (file.exists(results_path)) {
  yaml::read_yaml(results_path)
} else {
  list(summary = list(success = 0L, failure = 0L, missing = 0L), results = list())
}

entries <- manifest$entries
categories <- unique(vapply(entries, function(entry) entry$category, character(1)))

badge_text <- function(badges) {
  paste(sprintf("`%s`", as.character(unlist(badges))), collapse = " ")
}

mode_text <- function(entry) {
  mode <- entry$ci$mode %||% "unknown"

  if (identical(mode, "external-template")) {
    return("Installed and tested via `quarto use template`")
  }

  if (identical(mode, "local")) {
    return("Vendored local project")
  }

  if (identical(mode, "external")) {
    return("External repository render")
  }

  if (identical(mode, "harness-pending")) {
    return("Not yet enabled")
  }

  "Not yet enabled"
}

status_text <- function(entry) {
  result <- build_results$results[[entry$slug]]

  if (!is.null(result$status) && identical(result$status, "success")) {
    return("Passing CI")
  }

  if (!is.null(result$status) && identical(result$status, "failure")) {
    return("Failing CI")
  }

  if (!is.null(entry$ci$reason)) {
    return(entry$ci$reason)
  }

  "Not enabled in CI"
}

pdf_link <- function(entry) {
  result <- build_results$results[[entry$slug]]
  if (!is.null(result$pdf) && nzchar(result$pdf)) {
    return(sprintf("[Sample PDF](%s)", result$pdf))
  }
  NULL
}

lines <- c(
  "---",
  "title: Quarto Template Gallery",
  "---",
  "",
  "This gallery is generated from [`data/template-manifest.yml`](data/template-manifest.yml),",
  "which is a local working snapshot of the canonical template list in",
  "[`christopherkenny.github.io/webscripts/templates.yml`](https://github.com/christopherkenny/christopherkenny.github.io/blob/main/webscripts/templates.yml).",
  "",
  sprintf(
    "Enabled CI builds in this run: %d passing, %d failing.",
    build_results$summary$success %||% 0L,
    build_results$summary$failure %||% 0L
  ),
  "",
  "Enabled templates and filters are exercised through the Quarto CLI using repo-provided",
  "example files or materialized template projects, while the full inventory remains visible.",
  ""
)

for (category in categories) {
  lines <- c(lines, sprintf("## %s", category), "")
  category_entries <- Filter(function(entry) identical(entry$category, category), entries)

  for (entry in category_entries) {
    lines <- c(
      lines,
      sprintf("### %s", entry$name),
      "",
      entry$description,
      "",
      sprintf("Repository: [%s](%s)", entry$repo, entry$repo),
      "",
      sprintf("Type: %s", entry$type),
      "",
      sprintf("Badges: %s", badge_text(entry$badges)),
      "",
      sprintf("CI mode: %s", mode_text(entry)),
      "",
      sprintf("CI status: %s", status_text(entry)),
      ""
    )

    sample_pdf <- pdf_link(entry)
    if (!is.null(sample_pdf)) {
      lines <- c(lines, sample_pdf, "")
    }

    if (!is.null(entry$image)) {
      lines <- c(lines, sprintf("![](%s){fig-alt=\"%s preview\" width=\"280\"}", entry$image, entry$name), "")
    }
  }
}

writeLines(lines, con = output_path, useBytes = TRUE)
cat(sprintf("Wrote %s.\n", output_path))
