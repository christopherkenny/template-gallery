args <- commandArgs(trailingOnly = TRUE)
artifacts_root <- if (length(args) >= 1) args[[1]] else "artifacts"
output_path <- if (length(args) >= 2) args[[2]] else "data/build-results.yml"
pdf_root <- if (length(args) >= 3) args[[3]] else "assets/pdfs"

suppressPackageStartupMessages(library(yaml))

dir.create(pdf_root, recursive = TRUE, showWarnings = FALSE)

status_bucket <- function(status) {
  if (identical(status, "success")) {
    return("success")
  }
  if (identical(status, "failure")) {
    return("failure")
  }
  "missing"
}

if (dir.exists(artifacts_root)) {
  artifact_dirs <- list.dirs(artifacts_root, recursive = FALSE, full.names = TRUE)
  artifact_results <- Filter(Negate(is.null), lapply(artifact_dirs, function(artifact_dir) {
    result_path <- file.path(artifact_dir, "result.yml")
    if (!file.exists(result_path)) {
      return(NULL)
    }

    result <- yaml::read_yaml(result_path)
    pdf_source <- file.path(artifact_dir, sprintf("%s.pdf", result$slug))
    if (file.exists(pdf_source)) {
      pdf_target <- file.path(pdf_root, sprintf("%s.pdf", result$slug))
      file.copy(pdf_source, pdf_target, overwrite = TRUE)
      result$pdf <- sprintf("assets/pdfs/%s.pdf", result$slug)
    }

    result
  }))
} else {
  artifact_results <- list()
}

results <- setNames(artifact_results, vapply(artifact_results, function(result) result$slug, character(1)))
status_buckets <- vapply(artifact_results, function(result) status_bucket(result$status), character(1))
success <- sum(status_buckets == "success")
failure <- sum(status_buckets == "failure")
missing <- sum(status_buckets == "missing")

payload <- list(
  summary = list(success = success, failure = failure, missing = missing),
  results = results
)

yaml::write_yaml(payload, output_path)
cat(sprintf("Merged %d build results into %s.\n", length(results), output_path))
