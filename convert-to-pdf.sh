#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

out_dir="${1:-pdf}"
mkdir -p "$out_dir"

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required" >&2
  exit 1
fi

css_file="$(mktemp)"
trap 'rm -f "$css_file"' EXIT

cat >"$css_file" <<'CSS'
body {
  background: #fff;
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
  display: table;
  width: 100%;
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
  base="${file%.md}"
  echo "rendering $file -> $out_dir/$base.pdf"
  npx --yes md-to-pdf "$file" \
    --stylesheet "$css_file" \
    --body-class markdown-body \
    --basedir . \
    --dest "$out_dir/$base.pdf" \
    --pdf-options '{"format":"A4","printBackground":true,"margin":{"top":"16mm","right":"14mm","bottom":"16mm","left":"14mm"}}'
done
