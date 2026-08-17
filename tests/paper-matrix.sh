#!/usr/bin/env bash
# Every paper preset must compile in print media (measure fixture), plus the
# target-driven builds: the book example's kdp + coil targets and the two
# cover variants. Any failure exits 1.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out; fail=0
names=$(printf '#import "@local/tuftelike:0.1.0": papers\n#metadata(papers.keys()) <p>\n' > out/paper-names.typ \
  && typst eval --root . 'query(<p>).first().value' --in out/paper-names.typ --format json 2>/dev/null | jq -r '.[]')
for p in $names; do
  typst compile --root . --font-path fonts --input "paper=$p" tests/measure/page.typ "out/paper-$p.pdf" \
    && echo "paper-matrix: $p ok" || { echo "paper-matrix: $p FAILED" >&2; fail=1; }
done
for t in kdp coil; do
  typst compile --root . --font-path fonts --input "target=$t" examples/book/main.typ "out/paper-matrix-book-$t.pdf" \
    && echo "paper-matrix: book target=$t ok" || { echo "paper-matrix: book target=$t FAILED" >&2; fail=1; }
done
for c in kdp coil; do
  typst compile --root . --font-path fonts "examples/cover/$c.typ" "out/paper-matrix-cover-$c.pdf" \
    && echo "paper-matrix: cover $c ok" || { echo "paper-matrix: cover $c FAILED" >&2; fail=1; }
done
exit "$fail"
