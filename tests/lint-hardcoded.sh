#!/usr/bin/env bash
# Guard: every typographic knob lives in src/themes.typ (src/geometry.typ is
# exempt: it is page/printer geometry by definition). Any literal size,
# spacing, tracking, weight, color, font stack, or justify:true elsewhere in
# src/ fails. A line may opt out with `// lint-ok: <reason>` for values that
# are geometry, not typography (zero insets, structural 1em boxes).
set -euo pipefail
cd "$(dirname "$0")/.."
pattern='(size|tracking|above|below|inset|leading|spacing|gutter): [0-9.]+(pt|em|mm)|weight: "|luma\(|rgb\(|font: \("|justify: true|#v\([0-9.]+em\)|v\([0-9.]+em[,)]'
hits=$(grep -rnE "$pattern" src --include='*.typ' | grep -vE '^src/(themes|geometry).typ' | grep -v 'lint-ok' || true)
if [[ -n "$hits" ]]; then
  echo "hardcoded typography outside src/themes.typ:" >&2
  echo "$hits" >&2
  exit 1
fi
echo "lint-hardcoded: clean"
