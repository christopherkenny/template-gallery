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
  paste(sprintf("`%s`", unlist(badges)), collapse = " ")
}

status_text <- function(entry) {
  result <- build_results$results[[entry$slug]]

  if (!is.null(result$status) && identical(result$status, "success")) {
    return("Passing local example build")
  }

  if (!is.null(result$status) && identical(result$status, "failure")) {
    return("Local example build failed")
  }

  if (identical(entry$ci$mode, "local")) {
    return("Local example configured but not built in this run")
  }

  if (identical(entry$ci$mode, "harness-pending")) {
    return("Filter harness pending")
  }

  if (!is.null(entry$ci$reason)) {
    return(entry$ci$reason)
  }

  "Not yet built in CI"
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
    "Local example builds in this run: %d passing, %d failing.",
    build_results$summary$success %||% 0L,
    build_results$summary$failure %||% 0L
  ),
  "",
  "The first CI pass builds the templates vendored into this repo today, while keeping the",
  "full inventory visible so we can grow toward external clone-based builds and filter harnesses.",
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
