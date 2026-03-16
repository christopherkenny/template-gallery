args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(jsonlite))

manifest <- yaml::read_yaml(manifest_path)

entries <- Filter(function(entry) {
  entry$ci$mode %in% c("local", "external") && isTRUE(entry$ci$enabled)
}, manifest$entries)

matrix <- list(include = lapply(entries, function(entry) {
  list(
    slug = entry$slug,
    name = entry$name,
    mode = entry$ci$mode,
    repo = entry$repo,
    path = entry$ci$path,
    input = entry$ci$input,
    output_pdf = entry$ci$output_pdf,
    artifact_pdf = entry$ci$artifact_pdf
  )
}))

cat(jsonlite::toJSON(matrix, auto_unbox = TRUE))
