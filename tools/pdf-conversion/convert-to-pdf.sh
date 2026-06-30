#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
cd "$repo_root"

out_dir="${1:-pdf}"
mkdir -p "$out_dir"

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required" >&2
  exit 1
fi

css_file="$(mktemp)"
trap 'rm -f "$css_file"' EXIT

# Use md-to-pdf/Chromium instead of pandoc so the PDFs keep a browser-like look.
# The CSS below makes the output use an Arial-style font and visible markdown
# tables with borders/padding, matching what we wanted from the rendered docs.
# Required fonts: Arial/Helvetica for body text and Menlo for code/pre blocks
# with Monaco, Consolas and Courier New as fallbacks.
# Tested on macOS with npx/md-to-pdf.
cat >"$css_file" <<'CSS'
body {
  background: #fff;
  color: #24292f;
  font-family: Arial, Helvetica, sans-serif;
  font-size: 14px;
  line-height: 1.5;
}

.markdown-body {
  box-sizing: border-box;
  max-width: 980px;
  margin: 0 auto;
  padding: 32px 42px;
}

.markdown-body img {
  max-width: 100%;
  height: auto;
}

.markdown-body table {
  border-collapse: collapse;
  display: table;
  margin: 16px 0;
  width: 100%;
}

.markdown-body th,
.markdown-body td {
  border: 1px solid #d0d7de;
  padding: 6px 10px;
  vertical-align: top;
}

.markdown-body th {
  background: #f6f8fa;
  font-weight: 600;
}

.markdown-body tr:nth-child(even) {
  background: #fbfbfc;
}

.markdown-body code,
.markdown-body pre {
  font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
}

@page {
  size: A4;
  margin: 16mm 14mm;
}

@media print {
  body {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  .markdown-body {
    max-width: none;
    padding: 0;
  }

  .markdown-body pre,
  .markdown-body blockquote,
  .markdown-body table,
  .markdown-body img {
    break-inside: avoid;
  }
}
CSS

shopt -s nullglob

for file in *.md; do
  [[ "$file" == "lessons_learned.md" ]] && continue
  base="${file%.md}"
  title="$(sed -n 's/^# //p' "$file" | head -n 1)"
  [[ -n "$title" ]] || title="$base"
  echo "rendering $file -> $out_dir/$base.pdf"
  # Current md-to-pdf writes next to the source file, so move it into pdf/.
  npx --yes md-to-pdf "$file" \
    --document-title "$title" \
    --stylesheet "$css_file" \
    --body-class markdown-body \
    --basedir . \
    --pdf-options '{"format":"A4","printBackground":true,"margin":{"top":"16mm","right":"14mm","bottom":"16mm","left":"14mm"}}'
  mv "$base.pdf" "$out_dir/$base.pdf"
done
