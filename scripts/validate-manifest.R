args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"

suppressPackageStartupMessages(library(yaml))

source(file.path("scripts", "utils.R"))

manifest <- yaml::read_yaml(manifest_path)

entries <- manifest$entries
if (length(entries) == 0) {
  stop("Manifest must contain at least one entry.", call. = FALSE)
}

required_fields <- c("slug", "name", "category", "description", "repo", "type", "kind")
slugs <- vapply(entries, function(entry) entry$slug, character(1))
categories <- table(vapply(entries, function(entry) entry$category, character(1)))
enabled_builds <- 0L

if (anyDuplicated(slugs)) {
  duplicate_slug <- slugs[duplicated(slugs)][[1]]
  stop(sprintf("Duplicate slug found: %s", duplicate_slug), call. = FALSE)
}

for (entry in entries) {
  missing_fields <- required_fields[vapply(required_fields, function(field) {
    is.null(entry[[field]]) || !nzchar(entry[[field]])
  }, logical(1))]

  if (length(missing_fields) > 0) {
    stop(sprintf("Entry is missing required fields: %s", paste(missing_fields, collapse = ", ")), call. = FALSE)
  }

  if (is.null(entry$badges) || length(entry$badges) == 0) {
    stop(sprintf('Entry "%s" must have a non-empty badges array.', entry$slug), call. = FALSE)
  }

  ci <- ci_config(entry)
  is_enabled <- is_ci_enabled(entry)

  if (is_enabled) {

    required_ci_fields <- c("install_target", "path", "render_target", "output_pdf")
    missing_ci <- required_ci_fields[vapply(required_ci_fields, function(field) {
      default <- if (field == "path") "." else if (field == "render_target") "file" else ""
      !nzchar(normalize_text(ci[[field]], default))
    }, logical(1))]

    if (length(missing_ci) > 0) {
      stop(sprintf('Enabled entry "%s" must define ci.%s.',
        entry$slug,
        paste(missing_ci, collapse = ", ci.")
      ), call. = FALSE)
    }

    if (identical(normalize_text(ci$render_target, "file"), "file") &&
        !nzchar(normalize_text(ci$input))) {
      stop(sprintf('File-render entry "%s" must define ci.input.', entry$slug), call. = FALSE)
    }

    list_fields <- c("extra_files", "extra_system_packages", "extra_r_packages", "extra_tex_packages", "render_args")
    invalid_list_fields <- list_fields[vapply(list_fields, function(field) {
      value <- ci[[field]]
      !is.null(value) && !(is.atomic(value) || is.list(value))
    }, logical(1))]

    if (length(invalid_list_fields) > 0) {
      stop(sprintf('Entry "%s" must define ci.%s as scalar or vector values.',
        entry$slug,
        paste(invalid_list_fields, collapse = ", ci.")
      ), call. = FALSE)
    }

    enabled_builds <- enabled_builds + 1L
  }
}

cat(sprintf("Validated %d manifest entries from %s.\n", length(entries), manifest_path))
for (category in names(categories)) {
  cat(sprintf("- %s: %d\n", category, categories[[category]]))
}
cat(sprintf("Enabled CI render targets: %d\n", enabled_builds))
