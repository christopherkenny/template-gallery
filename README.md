> [!IMPORTANT]  
> This is a proof of concept.

# Template Gallery

This repo automates building my Quarto templates so that they can be displayed as a gallery.

The current CI pass is manifest-driven:

- `templates.yml` is the readable inventory snapshot aligned with the canonical list.
- `data/template-overrides.yml` holds CI-only metadata like Quarto install targets, render targets, and extra example assets.
- `data/template-manifest.yml` is the generated working manifest used by CI.
- `scripts/build-manifest.R` merges the inventory and overrides before validation.
- `scripts/validate-manifest.R` validates the generated manifest and drives the matrix.
- `.github/workflows/publish.yml` installs enabled templates and filters through the Quarto CLI, renders the repo-provided examples or projects, writes a run summary, assembles PDFs into `assets/pdfs/*.pdf`, generates a PDF-first `index.qmd`, and publishes the site on pushes to `main` even when some entries fail.

The manifest intentionally includes the full known template list, even when a given entry is not yet enabled in CI.
