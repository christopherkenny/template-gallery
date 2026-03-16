args <- commandArgs(trailingOnly = TRUE)
local_path <- if (length(args) >= 1) args[[1]] else "templates.yml"
remote_url <- if (length(args) >= 2) {
  args[[2]]
} else {
  "https://raw.githubusercontent.com/christopherkenny/christopherkenny.github.io/main/webscripts/templates.yml"
}

suppressPackageStartupMessages(library(yaml))

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

local_normalized <- normalize_object(local_templates)
remote_normalized <- normalize_object(remote_templates)

if (!identical(local_normalized, remote_normalized)) {
  stop(
    paste(
      "Local templates.yml is out of sync with the canonical template list.",
      sprintf("Update %s to match %s.", local_path, remote_url)
    ),
    call. = FALSE
  )
}

cat(sprintf("Verified %s matches %s.\n", local_path, remote_url))
