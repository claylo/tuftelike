#!/usr/bin/env bash
# Every role in default-theme must be consumed somewhere in src/ (outside
# themes.typ) — by dotted path in role()/role-args()/styled(), or by direct
# access (theme.body.leading, tc.indent, L.after-date, …). A role nobody
# reads is a dead knob: it lies to the person setting it.
set -euo pipefail
cd "$(dirname "$0")/.."
src=$(cat src/*.typ src/classes/*.typ src/extras/*.typ | grep -v '^\s*//')
# collapse same-line parenthesised args (r(...) bodies, inset dicts) three
# passes deep so only the group's own keys survive on each line
themes=$(sed -n '/^#let default-theme = (/,/^)/p' src/themes.typ | grep -v '^\s*//' \
  | sed -E 's/\([^()]*\)/()/g; s/\([^()]*\)/()/g; s/\([^()]*\)/()/g')

# emit dotted paths of every role/leaf under default-theme (2 levels deep)
paths=$(awk '
  /^  [a-z0-9-]+: \(\)?$/           { grp=$1; sub(":","",grp); ingrp=1; next }
  ingrp && /^  \),?$/                { ingrp=0; next }
  ingrp && /^    [a-z0-9-]+: /       { for(i=1;i<=NF;i++){ if($i ~ /^[a-z0-9-]+:$/){ k=$i; sub(":","",k); print grp"."k } } ; next }
  /^  [a-z0-9-]+: /                  { k=$1; sub(":","",k); print k }
' <<<"$themes" | grep -vE '^(fonts|justify|screen-bg|toc-pagenums|draft)$' | grep -vE '^fonts\.' | sort -u)

fail=0
while read -r path; do
  grp=${path%%.*}; leaf=${path#*.}
  if [[ "$path" == *.* ]]; then
    # dotted string OR  .leaf access on a var bound to the group OR theme.grp.leaf
    if ! grep -qE "\"$path\"|\.$leaf\b" <<<"$src"; then echo "unused role: $path" >&2; fail=1; fi
  else
    if ! grep -qE "\"$path(\.|\")|theme\.$path\b|role\(th, \"$path\"|\"$path\"" <<<"$src"; then echo "unused role: $path" >&2; fail=1; fi
  fi
done <<<"$paths"
[[ $fail -eq 0 ]] && echo "role-coverage: all $(wc -l <<<"$paths" | tr -d ' ') theme keys consumed"
exit "$fail"
