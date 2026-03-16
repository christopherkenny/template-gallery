args <- commandArgs(trailingOnly = TRUE)
artifacts_root <- if (length(args) >= 1) args[[1]] else "artifacts"
output_path <- if (length(args) >= 2) args[[2]] else "data/build-results.yml"
pdf_root <- if (length(args) >= 3) args[[3]] else "assets/pdfs"

suppressPackageStartupMessages(library(yaml))

dir.create(pdf_root, recursive = TRUE, showWarnings = FALSE)

results <- list()
success <- 0L
failure <- 0L
missing <- 0L

if (dir.exists(artifacts_root)) {
  artifact_dirs <- list.dirs(artifacts_root, recursive = FALSE, full.names = TRUE)

  for (artifact_dir in artifact_dirs) {
    result_path <- file.path(artifact_dir, "result.yml")
    if (!file.exists(result_path)) {
      next
    }

    result <- yaml::read_yaml(result_path)
    pdf_source <- file.path(artifact_dir, sprintf("%s.pdf", result$slug))
    if (file.exists(pdf_source)) {
      pdf_target <- file.path(pdf_root, sprintf("%s.pdf", result$slug))
      file.copy(pdf_source, pdf_target, overwrite = TRUE)
      result$pdf <- sprintf("assets/pdfs/%s.pdf", result$slug)
    }

    if (identical(result$status, "success")) {
      success <- success + 1L
    } else if (identical(result$status, "failure")) {
      failure <- failure + 1L
    } else {
      missing <- missing + 1L
    }

    results[[result$slug]] <- result
  }
}

payload <- list(
  generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
  summary = list(success = success, failure = failure, missing = missing),
  results = results
)

yaml::write_yaml(payload, output_path)
cat(sprintf("Merged %d build results into %s.\n", length(results), output_path))
