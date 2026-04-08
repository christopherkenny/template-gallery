normalize_text <- function(x, default = "") {
  if (is.null(x) || length(x) == 0) {
    return(default)
  }

  value <- as.character(x[[1]])
  if (!nzchar(value) || identical(value, "NA")) {
    return(default)
  }

  value
}

ci_config <- function(entry) {
  if (is.null(entry$ci) || !is.list(entry$ci)) {
    return(list())
  }
  entry$ci
}

is_ci_enabled <- function(entry) {
  nzchar(normalize_text(ci_config(entry)$install_target))
}
