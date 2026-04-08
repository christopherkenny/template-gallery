args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))
suppressPackageStartupMessages(library(jsonlite))

source(file.path("scripts", "utils.R"))

manifest <- yaml::read_yaml(manifest_path)

entries <- Filter(function(entry) {
  is_ci_enabled(entry)
}, manifest$entries)

matrix <- list(include = lapply(entries, function(entry) {
  ci <- ci_config(entry)
  extra_files <- as.character(unlist(ci$extra_files %||% character()))
  extra_system_packages <- as.character(unlist(ci$extra_system_packages %||% character()))
  extra_r_packages <- as.character(unlist(ci$extra_r_packages %||% character()))
  extra_tex_packages <- as.character(unlist(ci$extra_tex_packages %||% character()))
  render_args <- as.character(unlist(ci$render_args %||% character()))

  list(
    slug = normalize_text(entry$slug),
    name = normalize_text(entry$name),
    engine = normalize_text(entry$engine),
    needs_r = isTRUE(ci$needs_r) || length(extra_r_packages) > 0,
    repo = normalize_text(entry$repo),
    install_target = normalize_text(ci$install_target),
    path = normalize_text(ci$path, "."),
    render_target = normalize_text(ci$render_target, "file"),
    input = normalize_text(ci$input),
    extra_files = I(extra_files),
    has_extra_files = length(extra_files) > 0,
    output_pdf = normalize_text(ci$output_pdf),
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
