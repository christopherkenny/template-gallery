> [!IMPORTANT]  
> This is a proof of concept.

# Template Gallery

This repo automates building my Quarto templates so that they can be displayed as a gallery.

The current CI pass is manifest-driven:

- `data/template-manifest.yml` is the working inventory for templates and filters.
- `scripts/validate-manifest.R` validates the inventory and drives the matrix.
- `.github/workflows/publish.yml` builds the local template examples, assembles PDFs into `assets/pdfs/*.pdf`, generates `index.qmd`, and publishes the site on pushes to `main`.

The manifest intentionally includes the full known template list, even when a given entry is not yet built in CI. Local examples are enabled first; external repositories and filter harnesses are the next expansion steps.
