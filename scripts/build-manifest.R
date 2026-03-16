args <- commandArgs(trailingOnly = TRUE)
source_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
overrides_path <- if (length(args) >= 2) args[[2]] else "data/template-overrides.yml"
output_path <- if (length(args) >= 3) args[[3]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

repo_name_from_url <- function(url) {
  sub("^.*/", "", url)
}

source_data <- yaml::read_yaml(source_path)
overrides <- yaml::read_yaml(overrides_path)

entries <- list()

for (group in source_data) {
  for (extension in group$extensions) {
    repo_name <- repo_name_from_url(extension$link)
    override <- overrides[[repo_name]] %||% list()

    entry <- list(
      slug = override$slug %||% repo_name,
      name = extension$name,
      category = group$category,
      description = extension$description,
      repo = extension$link,
      image = extension$image,
      type = extension$type,
      badges = extension$badges %||% list(),
      kind = override$kind %||% "template",
      engine = override$engine,
      ci = override$ci %||% list(
        mode = "external",
        enabled = FALSE,
        reason = "External repository integration is planned but not implemented in the first pass."
      )
    )

    entries[[length(entries) + 1L]] <- entry
  }
}

manifest <- list(
  schema_version = 1,
  source = list(
    canonical_templates_yaml = "https://raw.githubusercontent.com/christopherkenny/christopherkenny.github.io/main/webscripts/templates.yml",
    synced_on = as.character(Sys.Date()),
    local_source = source_path,
    overrides = overrides_path
  ),
  entries = entries
)

yaml::write_yaml(manifest, output_path)
cat(sprintf("Wrote %s from %s and %s.\n", output_path, source_path, overrides_path))
