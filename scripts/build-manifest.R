args <- commandArgs(trailingOnly = TRUE)
source_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
overrides_path <- if (length(args) >= 2) args[[2]] else "data/template-overrides.yml"
output_path <- if (length(args) >= 3) args[[3]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))

source(file.path("scripts", "utils.R"))

repo_name_from_url <- function(url) {
  sub("^.*/", "", url)
}

compact_ci <- function(ci_override) {
  if (is.null(ci_override) || !is.list(ci_override) || length(ci_override) == 0) {
    return(NULL)
  }

  if (!nzchar(normalize_text(ci_override$install_target))) {
    return(NULL)
  }

  ci <- list()
  ci$install_target <- normalize_text(ci_override$install_target)
  ci$input <- normalize_text(ci_override$input)
  ci$output_pdf <- normalize_text(ci_override$output_pdf)

  if (isTRUE(ci_override$needs_r)) {
    ci$needs_r <- TRUE
  }

  if (normalize_text(ci_override$path, ".") != ".") {
    ci$path <- normalize_text(ci_override$path, ".")
  }

  if (normalize_text(ci_override$render_target, "file") != "file") {
    ci$render_target <- normalize_text(ci_override$render_target, "file")
  }

  for (field in c("extra_files", "extra_system_packages", "extra_r_packages", "extra_tex_packages", "render_args")) {
    value <- ci_override[[field]]
    if (!is.null(value) && length(value) > 0) {
      ci[[field]] <- unname(as.character(unlist(value, use.names = FALSE)))
    }
  }

  ci
}

compact_list <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  x[!vapply(x, is.null, logical(1))]
}

source_data <- yaml::read_yaml(source_path)
overrides <- yaml::read_yaml(overrides_path)

entries <- unlist(lapply(source_data, function(group) {
  lapply(group$extensions, function(extension) {
    repo_name <- repo_name_from_url(extension$link)
    override <- overrides[[repo_name]] %||% list()
    ci_override <- override$ci %||% list()

    compact_list(list(
      slug = override$slug %||% repo_name,
      name = extension$name,
      category = group$category,
      description = extension$description,
      repo = extension$link,
      image = extension$image,
      type = extension$type,
      badges = override$badges %||% extension$badges %||% list(),
      kind = override$kind %||% "template",
      engine = override$engine,
      ci = compact_ci(ci_override)
    ))
  })
}), recursive = FALSE, use.names = FALSE)

manifest <- list(
  source = "https://raw.githubusercontent.com/christopherkenny/christopherkenny.github.io/main/webscripts/templates.yml",
  entries = entries
)

yaml::write_yaml(manifest, output_path)
cat(sprintf("Wrote %s from %s and %s.\n", output_path, source_path, overrides_path))
