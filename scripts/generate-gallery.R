args <- commandArgs(trailingOnly = TRUE)
manifest_path <- if (length(args) >= 1) args[[1]] else "data/template-manifest.yml"
results_path <- if (length(args) >= 2) args[[2]] else "data/build-results.yml"
output_path <- if (length(args) >= 3) args[[3]] else "index.qmd"

suppressPackageStartupMessages(library(yaml))

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

manifest <- yaml::read_yaml(manifest_path)
build_results <- if (file.exists(results_path)) {
  yaml::read_yaml(results_path)
} else {
  list(summary = list(success = 0L, failure = 0L, missing = 0L), results = list())
}

entries <- manifest$entries
categories <- unique(vapply(entries, function(entry) entry$category, character(1)))

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

entry_result <- function(entry) {
  build_results$results[[entry$slug]] %||% list()
}

status_class <- function(entry) {
  result <- entry_result(entry)

  if (identical(result$status, "success")) {
    return("success")
  }

  if (identical(result$status, "failure")) {
    return("failure")
  }

  "pending"
}

status_text <- function(entry) {
  result <- entry_result(entry)

  if (identical(result$status, "success")) {
    return("Passing")
  }

  if (identical(result$status, "failure")) {
    return("Failing")
  }

  if (!isTRUE(entry$ci$enabled %||% FALSE)) {
    return("Not enabled")
  }

  normalize_text(entry$ci$reason, "Pending")
}

mode_text <- function(entry) {
  mode <- normalize_text(entry$ci$mode, "unknown")

  if (identical(mode, "external-template")) {
    return("Quarto CLI")
  }

  if (identical(mode, "external")) {
    return("Repo render")
  }

  if (identical(mode, "local")) {
    return("Local render")
  }

  "Pending"
}

badge_values <- function(entry) {
  badges <- unlist(entry$badges %||% list(), use.names = FALSE)
  badges <- as.character(badges)
  badges <- badges[nzchar(badges)]
  unique(badges)
}

pdf_link <- function(entry) {
  pdf <- normalize_text(entry_result(entry)$pdf)
  if (!nzchar(pdf)) {
    return(NULL)
  }
  pdf
}

result_link <- function(entry, field) {
  value <- normalize_text(entry_result(entry)[[field]])
  if (!nzchar(value)) {
    return(NULL)
  }
  value
}

repo_label <- function(url) {
  sub("^https://github.com/", "", url)
}

escape_html <- function(text) {
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text <- gsub("\"", "&quot;", text, fixed = TRUE)
  text
}

make_stat_block <- function(label, value) {
  sprintf(
    "<div class=\"gallery-stat\"><span class=\"gallery-stat-label\">%s</span><span class=\"gallery-stat-value\">%s</span></div>",
    escape_html(label),
    escape_html(as.character(value))
  )
}

make_card <- function(entry) {
  pdf <- pdf_link(entry)
  status <- status_text(entry)
  state_class <- status_class(entry)
  badges <- badge_values(entry)

  meta_parts <- c(sprintf("<span class=\"gallery-meta-item\">%s</span>", escape_html(entry$type)))

  if (length(badges) > 0) {
    meta_parts <- c(
      meta_parts,
      vapply(
        badges,
        function(badge) sprintf("<span class=\"gallery-meta-item\">%s</span>", escape_html(badge)),
        character(1)
      )
    )
  }

  body_parts <- c(
    sprintf("<div class=\"gallery-card %s\">", state_class),
    "<div class=\"gallery-card-header\">",
    "<div>",
    sprintf("<h3>%s</h3>", escape_html(entry$name)),
    sprintf("<p>%s</p>", escape_html(entry$description)),
    "</div>",
    sprintf("<span class=\"gallery-status %s\">%s</span>", state_class, escape_html(status)),
    "</div>",
    sprintf("<div class=\"gallery-meta\">%s</div>", paste(meta_parts, collapse = "")),
    sprintf(
      "<div class=\"gallery-links\"><a class=\"gallery-repo\" href=\"%s\">%s</a></div>",
      entry$repo,
      escape_html(repo_label(entry$repo))
    )
  )

  if (identical(state_class, "failure")) {
    run_url <- result_link(entry, "run_url")
    artifact_name <- escape_html(normalize_text(entry_result(entry)$artifact_name))
    if (!is.null(run_url)) {
      body_parts <- c(
        body_parts,
        sprintf(
          "<p class=\"gallery-note\">See <a href=\"%s\">run details</a>%s.</p>",
          run_url,
          if (nzchar(artifact_name)) sprintf(" and artifact <code>%s</code>", artifact_name) else ""
        )
      )
    }
  }

  if (!is.null(pdf)) {
    body_parts <- c(
      body_parts,
      "<div class=\"gallery-pdf-wrap\">",
      sprintf(
        "<object class=\"gallery-pdf\" data=\"%s#toolbar=0&navpanes=0&scrollbar=0&view=FitH\" type=\"application/pdf\"><p>PDF preview unavailable in this browser. <a href=\"%s\">Open the sample PDF</a>.</p></object>",
        pdf,
        pdf
      ),
      "<div class=\"gallery-pdf-overlay\" aria-hidden=\"true\"></div>",
      "</div>",
      sprintf(
        "<div class=\"gallery-links\"><a href=\"%s\">Open sample PDF</a></div>",
        pdf
      )
    )
  } else {
    body_parts <- c(
      body_parts,
      "<p class=\"gallery-note\">No current sample PDF is available for this entry.</p>"
    )
  }

  c(body_parts, "</div>")
}

make_inventory_row <- function(entry) {
  sprintf(
    "| %s | [%s](%s) | %s |",
    entry$name,
    repo_label(entry$repo),
    entry$repo,
    status_text(entry)
  )
}

built_entries <- Filter(function(entry) !is.null(pdf_link(entry)), entries)
failing_entries <- Filter(function(entry) identical(status_class(entry), "failure"), entries)

lines <- c(
  "---",
  "title: Quarto Template Gallery",
  "---",
  "",
  "::: {.gallery-lede}",
  "Sample PDFs from the latest CI run.",
  ":::",
  "",
  "::: {.gallery-summary}",
  make_stat_block("Passing", build_results$summary$success %||% 0L),
  make_stat_block("Failing", build_results$summary$failure %||% 0L),
  make_stat_block("No Result", build_results$summary$missing %||% 0L),
  make_stat_block("Visible", length(built_entries)),
  ":::",
  "",
  "## Built Samples",
  ""
)

if (length(built_entries) == 0) {
  lines <- c(
    lines,
    "No sample PDFs were produced in the latest run.",
    ""
  )
} else {
  for (category in categories) {
    category_entries <- Filter(function(entry) {
      identical(entry$category, category) && !is.null(pdf_link(entry))
    }, built_entries)

    if (length(category_entries) == 0) {
      next
    }

    lines <- c(lines, sprintf("### %s", category), "", "::: {.gallery-grid}")
    for (entry in category_entries) {
      lines <- c(lines, make_card(entry))
    }
    lines <- c(lines, ":::", "")
  }
}

lines <- c(lines, "## Failing Builds", "")

if (length(failing_entries) == 0) {
  lines <- c(lines, "No enabled entries are currently failing CI.", "")
} else {
  for (category in categories) {
    category_entries <- Filter(function(entry) {
      identical(entry$category, category) && identical(status_class(entry), "failure")
    }, failing_entries)

    if (length(category_entries) == 0) {
      next
    }

    lines <- c(lines, sprintf("### %s", category), "", "::: {.gallery-grid}")
    for (entry in category_entries) {
      lines <- c(lines, make_card(entry))
    }
    lines <- c(lines, ":::", "")
  }
}

for (category in categories) {
  category_entries <- Filter(
    function(entry) {
      identical(entry$category, category) &&
        is.null(pdf_link(entry)) &&
        !identical(status_class(entry), "failure")
    },
    entries
  )

  if (length(category_entries) == 0) {
    next
  }

  lines <- c(
    lines,
    sprintf("## %s Inventory", category),
    "",
    "| Entry | Repo | Status |",
    "| --- | --- | --- |"
  )

  for (entry in category_entries) {
    lines <- c(lines, make_inventory_row(entry))
  }

  lines <- c(lines, "")
}

writeLines(lines, con = output_path, useBytes = TRUE)
cat(sprintf("Wrote %s.\n", output_path))
