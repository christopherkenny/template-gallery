args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(jsonlite))

manifest <- yaml::read_yaml(manifest_path)

entries <- Filter(function(entry) {
  identical(entry$ci$mode, "local") && isTRUE(entry$ci$enabled)
}, manifest$entries)

matrix <- list(include = lapply(entries, function(entry) {
  list(
    slug = entry$slug,
    name = entry$name,
    path = entry$ci$path,
    input = entry$ci$input,
    output_pdf = entry$ci$output_pdf,
    artifact_pdf = entry$ci$artifact_pdf
  )
}))

cat(jsonlite::toJSON(matrix, auto_unbox = TRUE))
