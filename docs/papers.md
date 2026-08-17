# Papers, printers, tiers, and build targets

Every page size tuftelike knows about is a **paper preset** — a dict of geometry named
`<printer>-<trim>` — generated from a table of trims × a table of printers in
`src/geometry.typ`. Type sizes are *not* in there: per-trim type lives in the theme as
presets (`tier2`, `tier3`, …) that a paper can recommend. Geometry is geometry.

This page: why there are tiers, the full table with measured columns, what each printer
demands, bindings, build targets (one source → several outputs), and how an `initial`
paper becomes `proven`. The theme side of the story is in [`theming.md`](theming.md).

## 1. Tiers: what a Tufte page needs

The Tufte layout is one ratio: a text column of ~55–65 characters, a margin column
wide enough for real prose (~17–30 characters at note size), and honest outer margins.
At 11pt ETbb that's ~105–115 mm body + 37 mm notes + gap + margins ≈ 190 mm of trim.
Below that you either shrink the type or give up the column. So:

- **Tier 1 — full Tufte.** 11pt body, 9pt notes, ≥ 37 mm note column. Crown quarto
  (the print-proven prototype), KDP 7.5×9.25 / 7.44×9.69, 7×10, 8×10, US Letter, A4,
  and the two landscapes (which get very wide margins, quarto-style).
- **Tier 2 — Tufte at 10pt.** 152–170 mm trims: US Trade 6×9, Royal 6.14×9.21,
  6.69×9.61, Comic. Note column 26–30 mm. These papers recommend the `tier2` type
  preset (body 10pt, notes/captions/tables/index 8.5pt).
- **Tier 3 — no margin column.** ≤ 148 mm: Digest, A5, Novella, 5×8, Pocketbook.
  `note-col: 0mm`; the outer margin gets a little extra; `sidenote` and `marginnote`
  degrade to real footnotes and `footnotes-as-sidenotes` resolves to `false`, so the
  same source prints at 5×8 without edits. Recommends `tier3` (10pt) — Pocketbook
  recommends `tier3-small` (9pt).

`status` is `proven` only where a physical proof was measured. Everything else is
`initial`: derived from the proven crown-quarto measure and checked with `just measure`,
not yet held in a hand.

## 2. The table

Measured with `just measure-all` (`tests/measure/page.typ`: a chapter of `lorem` +
one long sidenote, print media). `lorem` runs ~8% denser than English prose — the
proven crown-quarto reads 64 cpl here and ~59 in the real book. Body/note widths are
the text's actual extent from the PDF.

**Tier 1**

| paper | printer | trim (mm) | tier | status | body mm | cpl | note mm | note cpl | lines/page |
|---|---|---|---|---|---|---|---|---|---|
| `lulu-crown-quarto` | lulu | 189 × 246 | 1 | proven | 110.5 | 64 | 39.5 | 23 | 30 |
| `kdp-7.44x9.69` | kdp | 189 × 246.1 | 1 | initial | 110.5 | 64 | 39.5 | 23 | 30 |
| `kdp-7.5x9.25` | kdp | 190.5 × 235 | 1 | initial | 110.5 | 64 | 39.5 | 23 | 28 |
| `lulu-executive` | lulu | 178 × 254 | 1 | initial | 99.4 | 57 | 39.5 | 23 | 30 |
| `kdp-7x10` | kdp | 177.8 × 254 | 1 | initial | 99.4 | 57 | 39.5 | 23 | 30 |
| `kdp-8x10` | kdp | 203.2 × 254 | 1 | initial | 112.3 | 65 | 50.4 | 30 | 31 |
| `lulu-us-letter` | lulu | 215.9 × 279.4 | 1 | initial | 114.9 | 66 | 53.6 | 30 | 31 |
| `kdp-8.5x11` | kdp | 215.9 × 279.4 | 1 | initial | 114.9 | 66 | 53.6 | 30 | 31 |
| `lulu-a4` | lulu | 210 × 297 | 1 | initial | 112.3 | 65 | 50.4 | 30 | 34 |
| `kdp-a4` | kdp | 210 × 297 | 1 | initial | 112.3 | 65 | 50.4 | 30 | 34 |
| `lulu-small-landscape` | lulu | 228.6 × 177.8 | 1 | initial | 116.4 | 66 | 68.5 | 42 | 18 |
| `kdp-8.25x6` | kdp | 209.6 × 152.4 | 1 | initial | 114.1 | 64 | 54.0 | 30 | 14 |

**Tier 2** (recommends `tier2`)

| paper | printer | trim (mm) | tier | status | body mm | cpl | note mm | note cpl | lines/page |
|---|---|---|---|---|---|---|---|---|---|
| `lulu-us-trade` | lulu | 152.4 × 228.6 | 2 | initial | 84.0 | 51 | 28.2 | 16 | 31 |
| `kdp-6x9` | kdp | 152.4 × 228.6 | 2 | initial | 84.0 | 51 | 28.2 | 16 | 31 |
| `lulu-royal` | lulu | 156 × 234 | 2 | initial | 87.3 | 56 | 29.7 | 17 | 32 |
| `kdp-6.14x9.21` | kdp | 156 × 234 | 2 | initial | 87.3 | 56 | 29.7 | 17 | 32 |
| `kdp-6.69x9.61` | kdp | 170 × 244 | 2 | initial | 98.3 | 62 | 31.9 | 18 | 32 |
| `lulu-comic` | lulu | 168 × 260 | 2 | initial | 96.4 | 62 | 31.9 | 18 | 35 |

**Tier 3** (recommends `tier3`; pocketbook `tier3-small`)

| paper | printer | trim (mm) | tier | status | body mm | cpl | note mm | note cpl | lines/page |
|---|---|---|---|---|---|---|---|---|---|
| `lulu-digest` | lulu | 139.7 × 215.9 | 3 | initial | 96.1 | 63 | - | - | 29 |
| `kdp-5.5x8.5` | kdp | 139.7 × 215.9 | 3 | initial | 96.1 | 63 | - | - | 29 |
| `lulu-a5` | lulu | 148 × 210 | 3 | initial | 98.3 | 63 | - | - | 28 |
| `lulu-novella` | lulu | 127 × 203.2 | 3 | initial | 82.3 | 53 | - | - | 27 |
| `kdp-5x8` | kdp | 127 × 203.2 | 3 | initial | 82.3 | 53 | - | - | 27 |
| `kdp-5.25x8` | kdp | 133.4 × 203.2 | 3 | initial | 89.4 | 58 | - | - | 26 |
| `kdp-5.06x7.81` | kdp | 128.5 × 198.4 | 3 | initial | 84.0 | 54 | - | - | 26 |
| `lulu-pocketbook` | lulu | 108 × 175 | 3 | initial | 64.3 | 45 | - | - | 24 |

Legacy names still resolve: `crown-quarto` → `lulu-crown-quarto`, `us-trade-6x9` →
`lulu-us-trade`, `us-letter` → `lulu-us-letter`.

Not baked: squares (Lulu 7.5², 8.5²; KDP 8.25², 8.5²), hardcover, KDP Japan trims. A
custom paper dict works for anything else — see §7.

## 3. Printers

| | Lulu | KDP |
|---|---|---|
| Interior bleed | 3.175 mm on **all four sides** → page = trim + 2b × trim + 2b | 3.175 mm on top/bottom/**outside only** → page = (trim + b) × (trim + 2b) |
| Safety (text to trim) | 12.7 mm recommended (we use it) | 6.4 mm min, 9.6 with bleed (we still use 12.7) |
| Gutter | additive over safety by page band: `0-60`: 0 · `61-150`: 3 · `151-400`: 13 · `401-600`: 16 · `over-600`: 19 mm | KDP publishes total inside minimums (9.6/12.7/15.9/19.1/22.3 mm); tuftelike stores additive extras `24-150`: 3 · `151-300`: 13 · `301-500`: 14 · `501-700`: 16 · `701-828`: 19 mm that reproduce the proven crown-quarto feel and clear every minimum |
| Default page band (`page-count-range: auto`) | `151-400` | `151-300` |
| Coil binding | yes — 2–470 pp, no gutter table, coil bites ~9 mm → 12.7 mm inside margin, still bleeds | no |
| Paperback spine | `paperback`: pages/444 + 0.06 in (= pages/17.48 + 1.524 mm) — **proven** against four real Lulu cover templates (140/180/295/300 pp → 9.53/11.82/18.40/18.69 mm, exact) | `white`: 0.002252 in/pg · `cream`: 0.0025 in/pg · `premium-color`: 0.002347 in/pg |
| Spine text | none at ≤ 80 pp | none at ≤ 79 pp |
| Cover bleed | 3.175 mm all four edges | same |
| Barcode zone | 92 × 32 mm, 12.7 mm from bleed edge (Lulu places its own if you don't) | 2 × 1.2 in, 0.25 in from trim (KDP places its own if you don't) |
| Min pages | 32 | 24 |

Barcode zones follow each printer's reserved area: Lulu 92 × 32 mm at 12.7 mm from the
bleed edge; KDP 2 × 1.2 in at 0.25 in from trim. `cover()` sizes and places the white
zone accordingly (the EAN itself is the same size on both).

Sources: KDP [trim/bleed/margins](https://kdp.amazon.com/en_US/help/topic/GVBQ3CMEQW3W2VL6),
[cover/spine](https://kdp.amazon.com/en_US/help/topic/G201953020); Lulu
[Book Creation Guide](https://assets.lulu.com/media/guides/en/lulu-book-creation-guide.pdf),
[coil formatting](https://help.lulu.com/en/support/solutions/articles/64000255583-tips-for-formatting-documents).

## 4. Bindings

`binding: "perfect"` (default) or `"coil"` on `book()` and `cover()`. Coil is Lulu-only;
each paper lists what it supports (`bindings`), and the class asserts. Coil replaces
the gutter table with Lulu's 12.7 mm inside margin and removes the spine from the
cover (`cover-size` and `spine-width` return no spine; the jacket is back + front).
Which Lulu trims accept coil isn't published in the guide — every Lulu paper is
marked coil-capable and `initial`; the order form is the arbiter.

## 5. Build targets: one source, several outputs

`--input media=print` was one switch; a real book has several outputs and each is a
tuple. `targets:` on every class (and `cover()`) is a dict of caller-named build
targets, flipped at compile time — same pattern as theme `presets:`:

```typ
#show: book.with(
  paper: "kdp-8x10",                       // default paper (the built-in "print" target uses it)
  targets: (
    kdp:    (media: "print", paper: "kdp-8x10"),
    custom: (media: "print", paper: "lulu-us-letter", binding: "coil", theme-preset: "field"),
  ),
)
```

```sh
typst compile main.typ                           # built-in "screen" (default)
typst compile --input target=kdp main.typ         # KDP edition
typst compile --input target=custom main.typ      # Lulu coil build
typst compile --input media=print main.typ        # still works: alias for the built-in "print"
```

A target may set any of `media`, `paper`, `binding`, `theme-preset`, `page-count-range`;
unset keys fall back to the class arguments. Resolution: `target:` arg > `--input target=`
> `--input media=` > `screen`. Type preset: `theme-preset:` arg > `--input theme=` >
the target's > the paper's recommendation > none.

Inside a class, media is ambient: `#show: begin-chapters` (no argument), `chapters()`
and `appendices()` no longer take `media:`, and `chapter-break("odd")` reads the target.
`current-target()`, `current-media()`, `current-paper()` are exported for your own
`context` blocks. `resolve-media()` remains for fixtures that build pages by hand.

Book-specific inputs (a VIN, section toggles) stay the book's own `sys.inputs`;
tuftelike only owns `target`, `theme`, and (compat) `media`.

## 6. Covers

`cover(paper:, page-count:, stock: auto, binding:, printer: auto, target:, targets:)`.
The printer comes from the paper; `stock: auto` is that printer's default
(`paperback` / `white`); legacy `"lulu-standard-bw"` still resolves (to `paperback`). Spine width
= per-page × pages + plus from the printer table; coil → no spine; spine text is
suppressed below the printer's threshold. `examples/cover/kdp.typ` (7.5×9.25, 250 pp
cream) and `examples/cover/coil.typ` (Lulu letter, coil) are compiled by `just test`.

## 7. Custom paper dicts

`paper:` accepts a dict with the preset shape: `trim: (w, h), bleed, safety, note-col,
note-gap, top-extra, bottom-extra, gutter-table`, and — so covers, coil, and KDP bleed
work — `printer`, `bleed-model` (`"all-sides"` | `"outer-only"`), `bindings`. Optional:
`outer-extra`, `theme-preset`, `letter-margin` / `handout-margin` (letter/handout classes
need them). Start by copying a neighbouring preset out of `papers`.

## 8. Promoting `initial` → `proven`

1. `just measure <paper>` — body/note width, cpl, lines. Aim for 55–65 cpl body (lorem
   reads ~8% high), 17–30 note cpl.
2. `just snapshot before`; adjust the trim row in `geometry.typ` (`note-col`,
   `note-gap`, `top-extra`, `bottom-extra`, `outer-extra`); `just test`; `just parity
   before` shows exactly which pages moved.
3. Order a proof at that printer/binding. Measure it. Adjust once more if needed.
4. Flip the row's `status: "proven"`, note the proof date and printer in the row's
   comment. That's the whole ceremony.
