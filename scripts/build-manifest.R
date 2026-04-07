args <- commandArgs(trailingOnly = TRUE)
source_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
overrides_path <- if (length(args) >= 2) args[[2]] else "data/template-overrides.yml"
output_path <- if (length(args) >= 3) args[[3]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))

repo_name_from_url <- function(url) {
  sub("^.*/", "", url)
}

source_data <- yaml::read_yaml(source_path)
overrides <- yaml::read_yaml(overrides_path)

default_ci <- list(
  mode = "external-template",
  enabled = FALSE,
  reason = "Not enabled in CI.",
  path = ".",
  render_target = "file"
)

entries <- unlist(lapply(source_data, function(group) {
  lapply(group$extensions, function(extension) {
    repo_name <- repo_name_from_url(extension$link)
    override <- overrides[[repo_name]] %||% list()
    ci_override <- override$ci %||% list()

    list(
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
      ci = modifyList(default_ci, ci_override)
    )
  })
}), recursive = FALSE, use.names = FALSE)

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
