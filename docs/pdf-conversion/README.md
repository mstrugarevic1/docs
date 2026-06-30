# PDF Conversion Tooling

Use `convert-to-pdf.sh` from the repository root to render the Markdown documents in this repository to PDF files.

```bash
./docs/pdf-conversion/convert-to-pdf.sh
```

The script writes PDFs to `pdf/` by default. To use a different output directory, pass it as the first argument:

```bash
./docs/pdf-conversion/convert-to-pdf.sh output-dir
```

The conversion uses `npx md-to-pdf`, which renders through Chromium. The script applies repository-specific CSS for readable browser-style PDFs, including Arial/Helvetica body text, Menlo code blocks, and visible table borders.
