#!/usr/bin/env bash
# Render test: with every font alias pointed at an embedded font, NO glyph
# may be set in a default-stack family. Any hit = a helper/region ignoring
# the theme (hardcoded font, unpublished ambient state, missing show rule).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
command -v pdffonts >/dev/null || { echo "font-swap: pdffonts (poppler) required" >&2; exit 2; }
defaults='ETbb|ETBembo|Palatino|Georgia|GillSans|Gill Sans|FiraSans|Fira Sans|Helvetica|Arial|Consolas|Menlo|Monaco'
fail=0
for target in book letter handout cover; do
  pdf="out/font-swap-$target.pdf"
  typst compile --root . "tests/font-swap/$target.typ" "$pdf" || { fail=1; continue; }
  leaks=$(pdffonts "$pdf" | awk 'NR>2{print $1}' | sed 's/^[A-Z]*+//' | grep -E "$defaults" || true)
  if [[ -n "$leaks" ]]; then
    echo "font-swap: $target leaks default-stack fonts:" >&2
    echo "$leaks" | sed 's/^/  /' >&2
    fail=1
  else
    echo "font-swap: $target clean"
  fi
done
exit "$fail"
