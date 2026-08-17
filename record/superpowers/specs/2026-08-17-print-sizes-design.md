# Print sizes: printers, trims, tiers, bindings, covers — design

Date: 2026-08-17. Status: approved (Clay, same day) — §1–§9 decided.

## Goal

Bake every mainstream Lulu and KDP trim into tuftelike as a paper preset with honest
Tufte-tier geometry, a matching type preset where the tier needs one, printer-correct
bleed/gutter/spine math, perfect *and* coil binding, and cover variants that follow —
all as data, all labeled `proven` or `initial`, all covered by tests and a measuring
tool so proofs can promote them.

Driving case: *Failing to Die* ships on **KDP 7.5×9.25, 151–300 pages**.

## Decisions already made (don't re-litigate)

- Geometry lives in `geometry.typ`; per-trim *type* lives in `theme-presets`. Geometry
  is geometry.
- Paper names are `<printer>-<trim>` when the gutter/bleed rules are printer-specific
  (all of them, it turns out); the three existing names stay as aliases.
- Nothing is `proven` without a printed proof. Everything new lands `initial`.
- Tiers 1, 2, 3 all in scope now. One landscape per printer, `initial`. Lulu coil in
  scope. Covers follow every paper.

## Facts (sources at the end)

| | Lulu | KDP |
|---|---|---|
| Bleed | 0.125 in / 3.175 mm, **all four sides** (interior page = trim + 2b both axes) | 0.125 in / 3.2 mm; **interior page = trim + 2b tall, trim + 1b wide** (outside edge only) |
| Safety (text-to-trim) | 0.5 in / 12.7 mm recommended | 0.25 in min (0.375 in with bleed) — we keep 12.7 mm |
| Gutter | additive over safety by page count: <60: 0 · 61–150: 3 · 151–400: 13 · 401–600: 16 · >600: 19 mm | total inside minimum by page count: 24–150: 9.6 · 151–300: 12.7 · 301–500: 15.9 · 501–700: 19.1 · 701–828: 22.3 mm |
| Coil | 2–470 pp, no gutter table, coil bites ~9 mm → 12.7 mm inside margin; still 0.125 in bleed; cover has no spine calc | n/a |
| Paperback spine | guide formula: pages/444 + 0.06 in (= pages/17.48 + 1.524 mm). Proven template constant: 0.0572 mm/pg (13.03 mm @ ~228 pp) | white 0.002252 in/pg (0.0572 mm) · cream 0.0025 in/pg (0.0635 mm) · premium color 0.002347 in/pg |
| Spine text | none if ≤ 80 pp | none if ≤ 79 pp |
| Cover safety | 0.5 in inside trim; bleed 0.125 in all sides | 0.125 in inside trim min; bleed 0.125 in top/bottom/outside; spine text 0.0625 in from spine edges |
| Barcode | 2 × 1.2 in zone (what we draw) — Lulu/KDP place their own if absent | same |
| Min pages | paperback 32 | 24 |

## Design

### 1. Printers as data (`geometry.typ`)

```typ
#let printers = (
  lulu: (
    bleed: 3.175mm, bleed-model: "all-sides", safety: 12.7mm,
    gutter-table: ("0-60": 0mm, "61-150": 3mm, "151-400": 13mm, "401-600": 16mm, "over-600": 19mm),
    coil: (inside: 12.7mm, min-pages: 2, max-pages: 470),
    spine: (
      "standard-bw": (per-page: 0.0572mm, plus: 0mm),          // PROVEN: back-derived from a real Lulu template
      "guide-formula": (per-page: 1mm / 17.48, plus: 1.524mm), // Lulu Book Creation Guide, paperback
    ),
    spine-text-min-pages: 81, min-pages: 32,
    cover-safety: 12.7mm,
  ),
  kdp: (
    bleed: 3.175mm, bleed-model: "outer-only", safety: 12.7mm,
    // KDP publishes TOTAL inside minimums; stored here as additive-over-safety
    // extras that reproduce the proven crown-quarto feel and clear every minimum
    gutter-table: ("24-150": 3mm, "151-300": 13mm, "301-500": 14mm, "501-700": 16mm, "701-828": 19mm),
    coil: none,
    spine: (
      "white": (per-page: 0.0572mm, plus: 0mm),
      "cream": (per-page: 0.0635mm, plus: 0mm),
      "premium-color": (per-page: 0.0596mm, plus: 0mm),
    ),
    spine-text-min-pages: 80, min-pages: 24,
    cover-safety: 3.2mm,   // KDP minimum; we still keep text at 12.7mm like Lulu
  ),
)
```

`page-size(paper, media)` and `marginalia-config` read `bleed-model`: `all-sides` →
width `trim + 2b`, inner far includes `b`; `outer-only` → width `trim + b`, inner far
has no bleed term. Screen media: no bleed either way (unchanged).

`cover.typ` `stocks` is replaced by `printers.<p>.spine.<stock>`; `spine-width(page-count,
printer, stock)` = `per-page × pages + plus`. `cover-size` adds bleed per the printer's
cover rule (both printers: bleed on all four cover edges). Existing `stocks` names map:
`lulu-standard-bw` → `(lulu, standard-bw)`, `kdp-white`/`kdp-cream` → `(kdp, white/cream)`;
old string form stays accepted for one release via a small lookup.

### 2. Trims and papers

`papers` is built by composing a `trims` table with a printer:

```typ
// name -> (printer, w, h, tier, note-col, note-gap, top-extra, bottom-extra, status, bindings, note)
```

Rendered as the final `papers` dict (same shape as today plus `printer`, `tier`,
`status`, `bindings`, `bleed-model`, `gutter-table` copied from the printer so
`resolve-paper` consumers keep working unchanged). Full list:

**Tier 1 — full Tufte, 11pt body, 9pt notes (default theme):**

| paper | trim mm | note-col / gap | top / bottom extra | status |
|---|---|---|---|---|
| `lulu-crown-quarto` (alias `crown-quarto`) | 189 × 246 | 37 / 4 | 15 / 3.17 | **proven** |
| `kdp-7.5x9.25` | 190.5 × 235 | 37 / 4 | 15 / 3.17 | initial (ports CQ verbatim; 11 mm shorter) |
| `kdp-7.44x9.69` | 189 × 246.1 | 37 / 4 | 15 / 3.17 | initial (KDP's crown quarto) |
| `lulu-executive` / `kdp-7x10` | 178 × 254 | 37 / 4 | 15 / 3.17 | initial (body ≈ 99 mm ≈ 53 cpl) |
| `kdp-8x10` | 203 × 254 | 42 / 5 | 15 / 3.17 | initial |
| `lulu-us-letter` (alias `us-letter`) / `kdp-8.5x11` | 216 × 279 | 50.8 / 6 | 25.4 / 19 | initial (tufte-latex canvas: 2 in notes) |
| `lulu-a4` / `kdp-a4` | 210 × 297 | 48 / 6 | 25.4 / 19 | initial |
| `lulu-small-landscape` | 229 × 178 | 50.8 / 6 | 12 / 3.17 | initial, **landscape** |
| `kdp-8.25x6` | 209.6 × 152.4 | 42 / 5 | 10 / 3 | initial, **landscape** |

**Tier 2 — Tufte at 10pt (theme preset per paper: `body 10pt`, `note 8.5pt`,
`caption 8.5pt`, `table-body 8.5pt`, `index 8.5pt`):**

| paper | trim mm | note-col / gap | top / bottom | status |
|---|---|---|---|---|
| `lulu-us-trade` / `kdp-6x9` (alias `us-trade-6x9` → lulu) | 152.4 × 228.6 | 26 / 4 | 10 / 3 | initial (needs Clay's proof) |
| `lulu-royal` / `kdp-6.14x9.21` | 156 × 234 | 27 / 4 | 10 / 3 | initial |
| `kdp-6.69x9.61` | 170 × 244 | 30 / 4 | 12 / 3 | initial |
| `lulu-comic` | 168 × 260 | 30 / 4 | 12 / 3 | initial |

**Tier 3 — no margin column ("conventional"): `note-col: 0mm`, `note-gap: 0mm`,
`outer-extra: 6mm`; theme preset `body 10pt`, footnotes are real footnotes:**

| paper | trim mm | status |
|---|---|---|
| `lulu-digest` / `kdp-5.5x8.5` | 139.7 × 215.9 | initial |
| `lulu-a5` | 148 × 210 | initial |
| `lulu-novella` / `kdp-5x8` | 127 × 203.2 | initial |
| `kdp-5.25x8` | 133.4 × 203.2 | initial |
| `kdp-5.06x7.81` | 128.5 × 198.4 | initial |
| `lulu-pocketbook` | 108 × 175 | initial (body ≈ 65 mm; expect 9.5pt) |

Squares (Lulu 7.5², 8.5²; KDP 8.25², 8.5²) are *not* baked — no Tufte case; a custom
dict works if anyone wants one.

Type presets in `theme-presets`: `"tier2"` and `"tier3"` hold the values; each tier-2/3
paper name is also registered as an alias to its tier preset (`"kdp-6x9"` → tier2) so
`--input theme=kdp-6x9` and `--input theme=tier2` both work. Papers carry
`theme-preset: "<name>"` and the classes' `theme-preset: auto` resolves: explicit arg >
`--input theme=` > **paper's own preset** > none. (New: papers can recommend a preset.)

### 3. Bindings

`book(binding: "perfect" | "coil")`, `cover(binding:)`. Default `"perfect"`.

- `perfect`: as today.
- `coil` (Lulu only; assert the printer supports it and the paper lists it in
  `bindings`): `marginalia-config` uses `inner far = b + printers.lulu.coil.inside` and
  ignores `page-count-range`; page count asserted within coil limits; `cover-size` spine
  = 0 and `cover()` draws no spine panel; folio/runners unchanged.
- Papers declare `bindings: ("perfect", "coil")`. Which Lulu trims allow coil isn't in
  the guide — mark every Lulu paper `coil` **initial** and let orders verify; A4 and
  US Letter are documented (coil edge can move only on those).

### 4. Tier 3 conventional mode

When `paper.note-col == 0mm`:

- `footnotes-as-sidenotes` default (now `auto`) resolves to `false` → real footnotes.
- `sidenote` renders as a numbered footnote; `marginnote` as an unnumbered footnote
  (both read `current-paper()` from state — same ambient pattern as theme).
- `notefigure`/`wideblock` assert with a clear message (no margin to put them in).
- `marginalia.setup` gets `outer: (width: 0mm, sep: 0mm)`; verify marginalia tolerates
  it — if not, bypass marginalia entirely for tier 3 (plain `set page(margin:)`), which
  is honestly simpler.

### 5. Measuring tool

`just measure <paper> [media]` → renders `tests/measure/page.typ` (a full page of lorem
+ a note) at that paper and prints: page size, body column width, note column width,
lines per page, and **characters per line** (from `mutool` stext line lengths). This is
what turns `initial` into `proven` alongside a physical proof, and what the tier tables
above are checked against.

### 6. Covers

Every paper works with `cover()` via `paper:` + `printer` from the paper dict; `stock:`
names are per printer. Coil → no spine. KDP cover bleed on all four edges (same as Lulu).
`spine-text-min-pages` suppresses spine text below the printer's threshold (today's
`page-count >= 80` hardcode becomes the printer value). Barcode zone unchanged.

### 7. Tests

- `tests/assert/geometry.typ`: every paper has the full key shape; `page-size` for both
  bleed models; gutter lookup per printer; coil config; alias names resolve; spine
  widths for known page counts (13.03 mm @ 228 pp lulu standard-bw; KDP white 250 pp =
  14.3 mm).
- `tests/paper-matrix.sh` (in `just test`): compile the template at **every** paper in
  print media + one coil build + one tier-3 build; `cover` at one paper per printer and
  one coil.
- Font-swap and parity unchanged; parity snapshot before/after confirms crown-quarto,
  6×9, letter render identically under the new names.

### 8. Docs

`docs/papers.md`: the tier idea, the full table with cpl from `just measure`, printer
facts + sources, binding notes, `proven`/`initial` meaning, how to promote. README
"Paper presets" section shortened to point at it. wiring-guides: note that 8×10.5 isn't
a printable trim at either printer — candidates are `kdp-8x10` or `lulu-us-letter`.

### 9. Build targets (replaces `--input media=` as the switch)

One source, several outputs, each a tuple — not a paper. `targets:` on every class is a
dict of caller-named build targets, flipped at compile time (same pattern as
`presets:`):

```typ
#show: book.with(
  paper: "kdp-8x10",                       // default paper (used by the built-in "print" target)
  targets: (
    kdp:    (media: "print", paper: "kdp-8x10",       binding: "perfect"),
    custom: (media: "print", paper: "lulu-us-letter", binding: "coil", theme-preset: "field"),
  ),
)
```

```sh
typst compile --input target=custom main.typ    # VIN build → Lulu coil
typst compile --input target=kdp main.typ
typst compile main.typ                           # built-in "screen"
```

- Built-in targets: `screen` (media screen) and `print` (media print at the class's
  `paper:`/`binding:` args). Callers' targets merge over the built-ins.
- Resolution: `target:` arg > `--input target=<name>` > legacy `--input media=<m>`
  (kept working: maps to the built-in of that name) > `screen`.
- A target may set any of `media`, `paper`, `binding`, `theme-preset`,
  `page-count-range`; unset keys fall back to the class args. Everything that reads
  `media` today (bleed, mirroring, recto breaks, page fill, verso caption flips) reads
  the resolved target's media.
- `resolve-media()` / `resolve-paper()` gain ambient forms: with no argument inside a
  class they read `state("tuftelike")` (media, paper, binding, target name), so
  `begin-chapters.with(resolve-media())` in existing books keeps working and picks up
  the target. `current-target()` exported.
- `cover(target:, targets:)` — same resolution; the target's paper + binding + printer
  drive the spread (coil → no spine).
- Book-specific inputs (VIN, section toggles) remain the book's own `sys.inputs`;
  tuftelike owns only `target`, `theme`, and (compat) `media`.

### 10. Lulu spine — RESOLVED by evidence (same day)

Four real Lulu cover templates from the prototype's setup (140/180/295/300 pp →
9.53/11.82/18.40/18.69 mm) fit `pages/444 + 0.06 in` exactly. The "proven" 0.0572 mm/pg
constant was KDP's white-paper number and is removed; Lulu's only stock is `paperback`
(the formula); legacy `standard-bw`/`guide-formula`/`lulu-standard-bw` names map to it.
Templates also gave the barcode zone (92 × 32 mm, 12.7 mm from bleed) → per-printer
`barcode-zone`.

## Out of scope

Hardcover (KDP/Lulu casewrap spine tables), saddle stitch, squares, Japan KDP trims,
shelf-matrix style presets.

## Sources

- KDP trim/bleed/margins: <https://kdp.amazon.com/en_US/help/topic/GVBQ3CMEQW3W2VL6>
- KDP cover/spine: <https://kdp.amazon.com/en_US/help/topic/G201953020>
- Lulu Book Creation Guide (trims, bleed, gutter, spine): <https://assets.lulu.com/media/guides/en/lulu-book-creation-guide.pdf>
- Lulu coil: <https://help.lulu.com/en/support/solutions/articles/64000255583-tips-for-formatting-documents>, <https://help.lulu.com/en/support/solutions/articles/64000306954-creating-your-coil-bound-cover>
