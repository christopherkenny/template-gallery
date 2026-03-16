args <- commandArgs(trailingOnly = TRUE)
local_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
remote_url <- if (length(args) >= 2) {
  args[[2]]
} else {
  "https://raw.githubusercontent.com/christopherkenny/christopherkenny.github.io/main/webscripts/templates.yml"
}
exclusions_path <- if (length(args) >= 3) args[[3]] else "data/template-sync-exclusions.yml"

suppressPackageStartupMessages(library(yaml))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

normalize_object <- function(x) {
  if (is.list(x)) {
    if (!is.null(names(x))) {
      out <- lapply(x, normalize_object)
      return(out[names(x)])
    }
    return(lapply(x, normalize_object))
  }

  if (inherits(x, "Date")) {
    return(as.character(x))
  }

  x
}

local_templates <- yaml::read_yaml(local_path)

tmp <- tempfile(fileext = ".yml")
on.exit(unlink(tmp), add = TRUE)
utils::download.file(remote_url, destfile = tmp, quiet = TRUE, mode = "wb")
remote_templates <- yaml::read_yaml(tmp)

excluded_repos <- character()
if (file.exists(exclusions_path)) {
  exclusions <- yaml::read_yaml(exclusions_path)
  excluded_repos <- exclusions$repos %||% character()
}

filter_templates <- function(template_groups, excluded_repos) {
  filtered <- lapply(template_groups, function(group) {
    kept_extensions <- Filter(function(extension) {
      !(extension$link %in% excluded_repos)
    }, group$extensions)

    group$extensions <- kept_extensions
    group
  })

  Filter(function(group) length(group$extensions) > 0, filtered)
}

remote_templates <- filter_templates(remote_templates, excluded_repos)

local_normalized <- normalize_object(local_templates)
remote_normalized <- normalize_object(remote_templates)

if (!identical(local_normalized, remote_normalized)) {
  stop(
    paste(
      "Local templates.yml is out of sync with the canonical template list.",
      sprintf("Update %s to match %s after applying exclusions from %s.", local_path, remote_url, exclusions_path)
    ),
    call. = FALSE
  )
}

cat(sprintf("Verified %s matches %s after exclusions from %s.\n", local_path, remote_url, exclusions_path))
