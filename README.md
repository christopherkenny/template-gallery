> [!IMPORTANT]  
> This is a proof of concept.

# Template Gallery

This repo builds Quarto templates and filters into a public gallery of CI-built sample PDFs.

The workflow is manifest-driven:

- `templates.yml` is the readable inventory snapshot aligned with the canonical list.
- `data/template-overrides.yml` holds the entries that CI should actually build.
- `data/template-manifest.yml` is the generated manifest used by CI.
- `scripts/build-manifest.R` merges the inventory and overrides.
- `scripts/write-render-matrix.R` turns enabled entries into the GitHub Actions matrix.
- `.github/workflows/publish.yml` installs each enabled entry with `quarto use template`, renders it, collects PDFs, generates `index.qmd`, and publishes the site on pushes to `main`.

## Override fields

Most entries only need these fields in `data/template-overrides.yml`:

- `engine`: `typst` or `latex`. This controls extra setup like fonts or TinyTeX.
- `ci.install_target`: the value passed to `quarto use template`.
- `ci.input`: the file to render.
- `ci.output_pdf`: the PDF expected after render.
- `ci.needs_r`: install R for examples that execute R.
- `ci.extra_files`: extra assets to copy in when Quarto does not materialize them.

These CI defaults are filled in automatically and usually do not need to be written per entry:

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
4. Add `ci.needs_r: true` only if the example actually executes R code.
5. Add `ci.extra_files` only for assets that `quarto use template` does not materialize.

A typical template entry looks like:

```yml
my-template:
  slug: my-template
  kind: template
  engine: typst
  ci:
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

Each matrix build uploads a `template-<slug>` artifact. The files that matter are:

- `result.yml`: final status and failure details
- `render-tail.log`: the last 200 lines of render output
- `files.txt`: recursive file listing after render
- `materialize.log`: output from `quarto use template`

The most useful `result.yml` fields are `status`, `failure_class`, and `failure_detail`.

## Debug a failure

When an entry fails, start with the `template-<slug>` artifact:

1. Check `result.yml` for `failure_class` and `failure_detail`.
2. Check `render-tail.log` for the actual error.
3. Use `files.txt` to confirm what Quarto materialized and what was produced after render.

The gallery site also includes a status table so the current CI state is visible without opening the Actions run.
