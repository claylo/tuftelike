#!/usr/bin/env bash
# Geometry parity between two build dirs. For every PDF present in BOTH,
# dumps line bboxes + font/size spans via mutool and diffs them — the same
# method used to prove the theme-roles refactor byte-identical.
#   tests/parity.sh <baseline-dir> [current-dir=out]
# Exit 1 if any PDF differs. Diffs land in <current-dir>/parity/*.diff.
set -euo pipefail
cd "$(dirname "$0")/.."
base=${1:?usage: parity.sh <baseline-dir> [current-dir]}; cur=${2:-out}
command -v mutool >/dev/null || { echo "parity: mutool required" >&2; exit 2; }
dump() { mutool draw -F stext -o - "$1" 2>/dev/null \
  | grep -oE '<line bbox="[^"]*"[^>]*text="[^"]*"|font name="[^"]*" size="[^"]*"'; }
mkdir -p "$cur/parity"; fail=0; n=0
for pdf in "$base"/*.pdf; do
  name=$(basename "$pdf"); [[ -f "$cur/$name" ]] || continue
  n=$((n+1))
  if diff <(dump "$pdf") <(dump "$cur/$name") > "$cur/parity/${name%.pdf}.diff"; then
    rm -f "$cur/parity/${name%.pdf}.diff"; echo "parity: $name identical"
  else
    echo "parity: $name DIFFERS ($(wc -l < "$cur/parity/${name%.pdf}.diff" | tr -d ' ') lines) -> $cur/parity/${name%.pdf}.diff"; fail=1
  fi
done
[[ $n -gt 0 ]] || { echo "parity: no PDFs in common between $base and $cur" >&2; exit 2; }
exit "$fail"
