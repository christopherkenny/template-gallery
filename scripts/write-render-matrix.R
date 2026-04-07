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
  identical(entry$ci$mode, "external-template") && isTRUE(entry$ci$enabled)
}, manifest$entries)

matrix <- list(include = lapply(entries, function(entry) {
  extra_files <- as.character(unlist(entry$ci$extra_files %||% character()))
  extra_system_packages <- as.character(unlist(entry$ci$extra_system_packages %||% character()))
  extra_r_packages <- as.character(unlist(entry$ci$extra_r_packages %||% character()))
  extra_tex_packages <- as.character(unlist(entry$ci$extra_tex_packages %||% character()))
  render_args <- as.character(unlist(entry$ci$render_args %||% character()))

  list(
    slug = normalize_string(entry$slug),
    name = normalize_string(entry$name),
    engine = normalize_string(entry$engine),
    needs_r = isTRUE(entry$ci$needs_r) || length(extra_r_packages) > 0,
    mode = normalize_string(entry$ci$mode),
    repo = normalize_string(entry$repo),
    install_target = normalize_string(entry$ci$install_target),
    path = normalize_string(entry$ci$path, "."),
    render_target = normalize_string(entry$ci$render_target, "project"),
    input = normalize_string(entry$ci$input),
    extra_files = I(extra_files),
    has_extra_files = length(extra_files) > 0,
    output_pdf = normalize_string(entry$ci$output_pdf),
    extra_system_packages = I(extra_system_packages),
    has_extra_system_packages = length(extra_system_packages) > 0,
    extra_r_packages = I(extra_r_packages),
    has_extra_r_packages = length(extra_r_packages) > 0,
    extra_tex_packages = I(extra_tex_packages),
    has_extra_tex_packages = length(extra_tex_packages) > 0,
    render_args = I(render_args),
    has_render_args = length(render_args) > 0
  )
}))

cat(jsonlite::toJSON(matrix, auto_unbox = TRUE))
