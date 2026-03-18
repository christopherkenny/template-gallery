args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

manifest <- yaml::read_yaml(manifest_path)

if (!identical(manifest$schema_version, 1L) && !identical(manifest$schema_version, 1)) {
  stop(sprintf("Unsupported schema_version: %s", manifest$schema_version), call. = FALSE)
}

entries <- manifest$entries
if (length(entries) == 0) {
  stop("Manifest must contain at least one entry.", call. = FALSE)
}

required_fields <- c("slug", "name", "category", "description", "repo", "type", "kind")
slugs <- character()
categories <- list()
enabled_builds <- 0L

for (entry in entries) {
  missing_fields <- required_fields[vapply(required_fields, function(field) {
    is.null(entry[[field]]) || !nzchar(entry[[field]])
  }, logical(1))]

  if (length(missing_fields) > 0) {
    stop(sprintf("Entry is missing required fields: %s", paste(missing_fields, collapse = ", ")), call. = FALSE)
  }

  if (entry$slug %in% slugs) {
    stop(sprintf("Duplicate slug found: %s", entry$slug), call. = FALSE)
  }
  slugs <- c(slugs, entry$slug)

  if (is.null(entry$badges) || length(entry$badges) == 0) {
    stop(sprintf('Entry "%s" must have a non-empty badges array.', entry$slug), call. = FALSE)
  }

  if (is.null(entry$ci) || !is.list(entry$ci)) {
    stop(sprintf('Entry "%s" must define a ci block.', entry$slug), call. = FALSE)
  }

  categories[[entry$category]] <- (categories[[entry$category]] %||% 0L) + 1L

  if (isTRUE(entry$ci$enabled)) {
    if (!identical(entry$ci$mode, "external-template")) {
      stop(sprintf('Enabled entry "%s" must use ci.mode = "external-template".', entry$slug), call. = FALSE)
    }

    required_ci_fields <- c("install_target", "path", "render_target", "output_pdf")
    missing_ci <- required_ci_fields[vapply(required_ci_fields, function(field) {
      is.null(entry$ci[[field]]) || !nzchar(entry$ci[[field]])
    }, logical(1))]

    if (length(missing_ci) > 0) {
      stop(sprintf('Enabled entry "%s" must define ci.%s.',
        entry$slug,
        paste(missing_ci, collapse = ", ci.")
      ), call. = FALSE)
    }

    if (identical(entry$ci$render_target, "file") &&
        (is.null(entry$ci$input) || !nzchar(entry$ci$input))) {
      stop(sprintf('File-render entry "%s" must define ci.input.', entry$slug), call. = FALSE)
    }

    enabled_builds <- enabled_builds + 1L
  }
}

cat(sprintf("Validated %d manifest entries from %s.\n", length(entries), manifest_path))
for (category in names(categories)) {
  cat(sprintf("- %s: %d\n", category, categories[[category]]))
}
cat(sprintf("Enabled CI render targets: %d\n", enabled_builds))
