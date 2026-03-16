args <- commandArgs(trailingOnly = TRUE)
local_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
remote_url <- if (length(args) >= 2) {
  args[[2]]
} else {
  "https://raw.githubusercontent.com/christopherkenny/christopherkenny.github.io/main/webscripts/templates.yml"
}

suppressPackageStartupMessages(library(yaml))

normalize_scalar <- function(x) {
  if (is.null(x)) {
    return("")
  }
  if (inherits(x, "Date")) {
    return(as.character(x))
  }
  as.character(x)
}

normalize_badges <- function(badges) {
  paste(sort(as.character(unlist(badges %||% character()))), collapse = "|")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

is_quarto_extension <- function(extension) {
  identical(normalize_scalar(extension$type), "Quarto")
}

flatten_templates <- function(template_groups) {
  rows <- list()

  for (group in template_groups) {
    for (extension in group$extensions) {
      if (!is_quarto_extension(extension)) {
        next
      }

      rows[[length(rows) + 1L]] <- data.frame(
        category = normalize_scalar(group$category),
        name = normalize_scalar(extension$name),
        link = normalize_scalar(extension$link),
        image = normalize_scalar(extension$image),
        type = normalize_scalar(extension$type),
        description = normalize_scalar(extension$description),
        badges = normalize_badges(extension$badges),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0) {
    return(data.frame(
      category = character(),
      name = character(),
      link = character(),
      image = character(),
      type = character(),
      description = character(),
      badges = character(),
      stringsAsFactors = FALSE
    ))
  }

  out <- do.call(rbind, rows)
  out[order(out$link, out$name), , drop = FALSE]
}

local_templates <- yaml::read_yaml(local_path)

tmp <- tempfile(fileext = ".yml")
on.exit(unlink(tmp), add = TRUE)
utils::download.file(remote_url, destfile = tmp, quiet = TRUE, mode = "wb")
remote_templates <- yaml::read_yaml(tmp)

local_flat <- flatten_templates(local_templates)
remote_flat <- flatten_templates(remote_templates)

if (!identical(local_flat, remote_flat)) {
  stop(
    paste(
      "Local templates.yml is out of sync with the canonical Quarto template list.",
      sprintf("Update %s to match the Quarto entries in %s.", local_path, remote_url)
    ),
    call. = FALSE
  )
}

cat(sprintf("Verified %s matches the Quarto entries in %s.\n", local_path, remote_url))
