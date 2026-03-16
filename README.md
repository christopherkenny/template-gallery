> [!IMPORTANT]  
> This is a proof of concept.

# Template Gallery

This repo automates building my Quarto templates so that they can be displayed as a gallery.

The current CI pass is manifest-driven:

- `templates.yml` is the readable inventory snapshot aligned with the canonical list.
- `data/template-overrides.yml` holds CI-only metadata like local render paths and future harness strategy.
- `data/template-manifest.yml` is the generated working manifest used by CI.
- `scripts/build-manifest.R` merges the inventory and overrides before validation.
- `scripts/validate-manifest.R` validates the generated manifest and drives the matrix.
- `.github/workflows/publish.yml` builds local examples plus explicitly enabled external repos, writes a run summary, assembles PDFs into `assets/pdfs/*.pdf`, generates `index.qmd`, and publishes the site on pushes to `main`.

The manifest intentionally includes the full known template list, even when a given entry is not yet built in CI. Local examples are enabled first; external repositories and filter harnesses are the next expansion steps.
