args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(jsonlite))

manifest <- yaml::read_yaml(manifest_path)

normalize_string <- function(x, default = "") {
  if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) {
    return(default)
  }
  as.character(x)
}

entries <- Filter(function(entry) {
  entry$ci$mode %in% c("local", "external", "external-template") && isTRUE(entry$ci$enabled)
}, manifest$entries)

matrix <- list(include = lapply(entries, function(entry) {
  list(
    slug = normalize_string(entry$slug),
    name = normalize_string(entry$name),
    kind = normalize_string(entry$kind),
    engine = normalize_string(entry$engine),
    needs_r = isTRUE(entry$ci$needs_r),
    mode = normalize_string(entry$ci$mode),
    repo = normalize_string(entry$repo),
    install_target = normalize_string(entry$ci$install_target),
    path = normalize_string(entry$ci$path, "."),
    render_target = normalize_string(entry$ci$render_target, "project"),
    input = normalize_string(entry$ci$input),
    extra_files = I(as.character(unlist(entry$ci$extra_files %||% character()))),
    output_pdf = normalize_string(entry$ci$output_pdf),
    artifact_pdf = normalize_string(entry$ci$artifact_pdf)
  )
}))

cat(jsonlite::toJSON(matrix, auto_unbox = TRUE))
