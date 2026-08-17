#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
fail=0

for target in book letter handout; do
  for media in screen print; do
    echo "== $target/$media"
    typst compile --root . --font-path fonts --input media="$media" \
      "examples/$target/main.typ" "out/matrix-$target-$media.pdf" || fail=1
  done
done

echo "== book/print themed (--input theme=trade)"
typst compile --root . --font-path fonts --input media=print --input theme=trade \
  "examples/book/main.typ" "out/matrix-book-print-trade.pdf" || fail=1

echo "== cover"
typst compile --root . --font-path fonts \
  examples/cover/main.typ out/matrix-cover.pdf || fail=1

echo "== template"
typst compile --root . --font-path fonts --input media=screen \
  template/main.typ out/matrix-template.pdf || fail=1

exit "$fail"
