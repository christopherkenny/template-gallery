> [!IMPORTANT]  
> This is a proof of concept.

# Template Gallery

This repo automates building Quarto templates and filters into a public gallery of CI-built sample PDFs.

The workflow is manifest-driven:

- `templates.yml` is the readable inventory snapshot aligned with the canonical list.
- `data/template-overrides.yml` holds CI-only settings for entries that should be built.
- `data/template-manifest.yml` is the generated manifest used by CI.
- `scripts/build-manifest.R` merges the inventory and overrides.
- `scripts/validate-manifest.R` checks that enabled entries have the fields the workflow expects.
- `scripts/write-render-matrix.R` turns enabled entries into the GitHub Actions matrix.
- `.github/workflows/publish.yml` installs each enabled entry with `quarto use template`, renders it, captures logs and PDFs as artifacts, generates `index.qmd`, and publishes the site on pushes to `main`.

The manifest intentionally includes the full known template list, even when an entry is not yet enabled in CI.

## Override fields

Most entries only need these fields in `data/template-overrides.yml`:

- `engine`: `typst` or `latex`. This controls extra setup like fonts or TinyTeX.
- `ci.enabled`: whether that entry should be part of the CI build matrix.
- `ci.install_target`: the value passed to `quarto use template`.
- `ci.input`: the preferred `.qmd` filename to render.
- `ci.output_pdf`: the expected PDF output path relative to `ci.path`.
- `ci.needs_r`: install R and the minimal CRAN packages needed by examples that execute R code.
- `ci.extra_files`: extra assets to copy in when `quarto use template` does not materialize everything needed for the example render.

These CI defaults are filled in automatically and usually do not need to be written per entry:

- `ci.mode: external-template`
- `ci.path: "."`
- `ci.render_target: file`

For unusual templates, there are a few optional advanced fields:

- `ci.extra_system_packages`: extra Ubuntu packages to install before rendering
- `ci.extra_r_packages`: extra CRAN packages needed only for a specific template
- `ci.extra_tex_packages`: extra TinyTeX packages to install
- `ci.render_args`: extra arguments passed to `quarto render`

## Add an entry

To enable a new template or filter in CI:

1. Make sure it exists in `templates.yml`.
2. Add a matching block in `data/template-overrides.yml`.
3. Set `engine`, `ci.install_target`, `ci.input`, and `ci.output_pdf`.
4. Skip `ci.mode`, `ci.path`, and `ci.render_target` unless an entry truly needs something unusual.
5. Add `ci.needs_r: true` only if the example actually executes R code.
6. Add `ci.extra_files` only for assets that `quarto use template` does not materialize.

A typical template entry looks like:

```yml
my-template:
  slug: my-template
  kind: template
  engine: typst
  ci:
    enabled: true
    install_target: christopherkenny/my-template
    input: template.qmd
    output_pdf: template.pdf
```

A typical filter entry looks like:

```yml
my-filter:
  slug: my-filter
  kind: filter
  ci:
    enabled: true
    install_target: christopherkenny/my-filter
    input: example.qmd
    output_pdf: example.pdf
```

## Render behavior

The workflow assumes a Quarto CLI install-and-render path for all enabled entries:

1. `quarto use template <install_target> --no-prompt`
2. Render the example file from the materialized directory
3. Copy the expected PDF into `assets/pdfs`
4. Merge all `result.yml` files into `data/build-results.yml`
5. Generate `index.qmd` from the manifest plus build results

For file renders, the workflow tries `ci.input` first. If that file is not present after materialization and there is exactly one top-level `.qmd`, it renders that file instead and expects the matching `.pdf`. This is what lets entries like `apsr.qmd` or `cv.qmd` work without maintaining one-off filename logic per repo.

## Artifacts

Each matrix build uploads a `template-<slug>` artifact. The three files to check first are:

- `result.yml`: final status plus resolved render target, resolved PDF name, and failure classification
- `render-tail.log`: the last 200 lines of render output
- `files.txt`: full recursive file listing after render

The artifact also includes `render.log`, `materialize.log`, `tree.txt`, `render-context.txt`, and `site-files.txt` for deeper debugging.

The most useful `result.yml` fields are:

- `status`: `success`, `failure`, `missing`, or `missing-artifact`
- `resolved_input`: the actual file rendered after any fallback from `ci.input`
- `resolved_output_pdf`: the PDF name the workflow expected after render
- `failure_class`: a short bucket like `materialize`, `missing-r-package`, `missing-system-library`, `latex`, or `missing-pdf`
- `failure_detail`: the first useful matching error line from the render log

## Debug a failure

When an entry fails, start with the `template-<slug>` artifact:

1. Check `result.yml` for `failure_class`, `resolved_input`, and `resolved_output_pdf`.
2. Check `render-tail.log` for the actual error.
3. Use `files.txt` to confirm what Quarto materialized and what was produced after render.
4. Use `tree.txt` when the failure happened before render, usually during `quarto use template`.

The gallery site also includes a status table so the current CI state is visible without opening the Actions run.
