# Handoff — 2026-08-17 (theme roles session)

## What landed this session

Two commits on `main`, tree clean:

- `bc38e4c feat(themes): role-based theme schema, ambient theme, dependency recipes`
- `6a419c2 chore: drop the TYPST_PACKAGE_PATH workaround scaffolding`

Spec: `record/superpowers/specs/2026-08-17-theme-roles-design.md`.
Plan (all 10 tasks done): `record/superpowers/plans/2026-08-17-theme-roles.md`.

### Theme layer (breaking, clean break — no compat shim)

- `src/themes.typ` `default-theme` = `fonts` (serif/sans/mono stacks) + **roles**.
  Every text site is a role with six keys `font/size/weight/style/tracking/fill`
  (`auto` = inherit) plus `above/below`/named gaps where the role owns rhythm and
  `case: "upper"|"smallcaps"` where it transforms case. `role.font` is an alias
  (`"serif"|"sans"|"mono"`) or an explicit stack. That file is the complete knob list.
- `resolve-theme` deep-merges (dicts at every depth; arrays replace). Preset chain
  unchanged: `theme:` > preset overlay > defaults; `--input theme=<name>`.
- Primitives (exported): `deep-merge`, `role(theme, "a.b")`, `role-args(theme, path)`
  (text() args, auto keys dropped), `styled(theme, path, body)`, `cased`,
  `current-theme()`, `current-labels()`.
- **Ambient theme/labels:** helpers read `state("tuftelike")` — `sidenote`, `marginnote`,
  `sidecite`, `newthought`, `tufte-quote`, `md`, `part-divider`, `about-author`,
  `colophon`, `book-index`, `instructional-extensions`. All body-first with
  `theme: auto, labels: auto`. This killed the silent Gill Sans/ETbb fallback that hit
  every caller who didn't thread `theme:` (both real books had it).
- `raw` honors `fonts.mono`; `justify` is a knob (default `false`); heading
  `above/below` are knobs via **conditional set rules** (`set … if cond`).
- `tests/lint-hardcoded.sh` runs in `just test`; fails on any typographic literal
  outside `src/themes.typ`. `// lint-ok: <reason>` opts a line out (geometry only).
- Parity: every default render verified byte-identical (line bboxes + font/size via
  `mutool draw -F stext`) vs pre-change baselines — book print/screen, TOC fixture,
  letter, handout, cover.

### Tooling

- `bin/typst-deps outdated|update [pkg…]` + `just outdated` / `just update` — scans
  `@preview/name:ver` pins across src/template/examples/tests, compares with
  `packages.typst.org/preview/index.json`. All four pins (marginalia 0.3.1, cmarker
  0.1.10, tiaoma 0.3.0, in-dexter 0.7.2) were already latest. in-dexter is ALSO pinned
  in colophon's config — the script warns.
- `TYPST_PACKAGE_PATH` shell bug fixed at the source (Clay's misc.zsh); all `env -u`
  scaffolding removed from justfile/compile-matrix/README. `.envrc` cleaned by Clay too. Done.

### Downstream migrations (uncommitted in their repos, Clay's call)

- `~/source/wiring-guides`: `setup.typ` → `fonts:` + `heading.h2/h3/h4` roles;
  `guide-ext.typ` dropped theme plumbing; `how-to-use.typ` `newthought[…]`. Zero
  ETbb/GillSans. Page count 112→106 (heading spacing moved from inline `v()` to block
  `above/below`) — **Clay may want to tune h2/h3 above/below by eye.**
- `~/source/claylo/failing-to-die/book.typ`: `fonts:` stack, `part-divider(…)` ×3,
  `book-index()`; `Justfile` gained `--root .` (typst 0.15.1 fails on a bare no-dir
  input path — pre-existing, unrelated). Charter + Fira Sans only now.
- No shared `my-themes.typ` exists yet (intent only). Pattern when he wants it:
  `examples/book/themes.typ` — nested keys, symlink into each book, `presets:`.

## Next session: bake in more print sizes

Where it lives: `src/geometry.typ` `papers` dict. Shape every preset needs:
`trim(w,h), bleed, safety, note-col, note-gap, top-extra, bottom-extra, gutter-table`
(letter/handout additionally read `letter-margin`/`handout-margin` and bypass
`marginalia-config`). `resolve-paper` accepts a name or a custom dict of the same
shape (wiring-guides uses a custom 8×10.5 "chilton" dict — a good candidate to
promote).

Current presets: `crown-quarto` (print-proven from the prototype), `us-trade-6x9`
(initial values, NOT proof-tuned), `us-letter`.

Known inputs for the 6×9 re-bake (from prior memory): measured 84mm/45cpl body +
26mm/17cpl notes at 11pt is cramped; recommended 10pt body + 8.5pt notes for sidenote
6×9, or `note-col: 0mm` + 0.5em leading for conventional trade. Waits on Clay's
printed proofs per the geometry.typ contract ("tune against printed proofs before
calling the preset stable").

Suggested candidates (verify trim/bleed against Lulu + KDP spec sheets before
baking): 5×8, 5.5×8.5 (digest), 6×9 (re-bake), 7×10, 8×10, 8×10.5 (chilton, from
wiring-guides), 8.5×11, A5, A4, royal octavo (156×234). **DECIDED (Clay, 2026-08-17):
per-trim type sizes are THEME presets, not paper-dict fields — geometry stays
geometry.** Each paper preset ships a matching named overlay in `theme-presets`
(e.g. `"trade-6x9"`) so `--input theme=` picks the proven type sizes for that
trim. Don't re-litigate.

Also open: `tests/assert/geometry.typ` should assert every preset has the full
key shape (same completeness pattern as the theme test); `frontmatter-page` still
uses fixed 25.4mm margins regardless of paper — revisit if a small trim needs
different front-matter margins; prototype front matter mirrors margins (verso
content sits 21.8pt left of recto), tuftelike's is symmetric by design — Clay's
call whether to mirror.

## Verify-fast

`just test` (lint + 8 asserts + 9-target matrix) · `just demo book print [trade]` ·
`just cover` · `just outdated` · `direnv exec . just proto-check` (needs
`PROTO_BOOK_DIR` in untracked `.envrc.local`; fixture builds, 56pp).

Parity method when touching defaults: build baseline PDF first, dump
`mutool draw -F stext -o - X.pdf | grep -oE '<line bbox="[^"]*"[^>]*text="[^"]*"|font name="[^"]*" size="[^"]*"'`,
diff after. Bboxes must match; folio-number-only diffs mean body pagination moved.

## Gotchas learned this session (add to the pile)

- `show heading: set block(above: auto)` is NOT a no-op — it replaces Typst's own
  heading spacing with the generic block default. Use `set … if cond` conditional
  set rules so `auto` means "don't touch".
- `text(fill: auto)` is a type error — `role-args` must drop auto keys.
- `git stash`/`stash pop` restores the working tree but not the index; re-`git add`
  after a stash round-trip or the commit misses files.
- typst 0.15.1: `typst compile book.typ` (no dir component, no `--root`) can fail
  with "source file must be contained in project root"; pass `--root .`.
- When the root cause is a one-line fix in Clay's environment, say so FIRST. Never
  build repo-side workarounds around it (the TYPST_PACKAGE_PATH lesson).
- Naming hygiene per prototype-book-naming memory still applies to everything.

---

# Addendum — print sizes session (2026-08-17, later same day; branch `print-sizes`)

Spec: `record/superpowers/specs/2026-08-17-print-sizes-design.md` (approved; §9 targets,
§10 spine). Plan: `record/superpowers/plans/2026-08-17-print-sizes.md` (all tasks done).
Reference doc: `docs/papers.md`.

**Landed:** `printers` table (lulu/kdp — bleed model, gutter bands, coil, spine
formulas, spine-text threshold); 26 `<printer>-<trim>` papers from `trims` × printers,
tiers 1/2/3, `status` proven/initial (only lulu-crown-quarto proven); tier2/tier3/
tier3-small type presets papers RECOMMEND (`theme-preset: auto` falls through);
`page-count-range: auto` = printer default band; build targets (`targets:` +
`--input target=`, built-ins screen/print, `--input media=` alias); ambient
`#show: begin-chapters`, `chapters()`/`appendices()` lost `media:`, `chapter-break`
in `src/breaks.typ` and in md's raw-typst scope; `binding: "coil"`; tier-3 papers
degrade sidenote/marginnote to footnotes, `footnotes-as-sidenotes: auto`; `cover()`
per-printer spine/stock/coil/target; `bin/measure` + `just measure[-all]`;
`tests/paper-matrix.sh` in `just test` (26 papers + book kdp/coil targets + 2 covers).

**Decisions:** KDP gutter = additive extras reproducing the proven CQ feel (not KDP
minimum+ε). Tier 3 degrades gracefully. Lulu spine: proven constant default,
guide formula alongside; Clay to re-check where 13.03mm@228pp came from. Wiring
guide: 8×10.5 is NOT a printable trim → KDP 8×10 (all-configs) + Lulu US Letter coil
(VIN builds); both migrated + building. Failing to Die → `kdp-7.5x9.25`, 151–300,
`--input target=kdp`; building (screen 7.5×9.25, print 7.625×9.5).

**Parity:** all defaults identical vs `snapshots/before` except the two 6×9 users
(examples/book, template) which now get the recommended tier2 10pt — verified
identical when the default theme is forced.

**Next:** printed proofs → promote papers (docs/papers.md §8); Clay's spine
constant check; the shelf matrix (record/tufte-style-matrix.md) — "grim, but we
should"; Universe when the proof gate passes.

**Gotchas:** `str(auto)` is a type error (use `repr`); `grep -m1` in a `pipefail`
pipeline SIGPIPEs mutool (dump to a file first); `typst query` deprecated → `typst
eval 'query(<p>)…' --in file --format json`; KDP page-with-bleed is trim+b wide,
trim+2b tall.
