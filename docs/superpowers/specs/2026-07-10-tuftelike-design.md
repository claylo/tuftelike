# tuftelike — Design

**Date:** 2026-07-10
**Status:** Approved pending user review
**Repo:** `claylo/tuftelike` (clean slate)

One Tufte-style Typst template repo that unifies four prototypes:

| Source | What it contributes |
|---|---|
| `claylo/tufte-style` | The **architecture**: region modules (frontmatter/mainmatter/backmatter/chapter), document-class dispatch, theme fallback chains, `show_*`-style toggles, localizable labels, polymorphic front-matter inputs |
| `claylo/tufte-style-book` | The **print engineering** (print-proven via the prototype book): Lulu Crown Quarto bleed/safety geometry, page-count→gutter table, print/screen bifurcation, running heads with `alt_runners`, `lead_smallcaps` |
| prototype book *(private)* | The **production hacks to pull up**: chapter openers with Chapter/Appendix detection, H3 icon registry, Tufte-minimal tables/figures extending into the margin, data-driven part dividers, markdown extension show-rules, full wrap cover with spine calc, `bin/table-to-typst` |
| `claylo/tufte-letter` | File-based sidenote content, numbered-body/unnumbered-appendix mode, the *demand* for a real letter class (it never had letter structure) |

## Goals

1. **Easy to use.** Markdown-first authoring works out of the box; plain Typst works equally well. Standard markdown needs zero custom syntax for the common cases.
2. **Flexible.** Books, letters, handouts today; more classes later without forking. Paper sizes (including 6×9) and printers are data presets, not code paths.
3. **One repo to maintain.** Shared engine, thin classes. No per-book `main.typ` piles of show rules.
4. **Production-minded.** Print (bleed, gutters, recto starts, spine-calculated wrap covers) and screen (cream background, single-margin) from the same source via `--input media=`.

**Driving use case:** a forthcoming author-owned 6×9 title, print + ebook (the ebook edition being the screen-media PDF), with real ISBNs. The 6×9 preset and ISBN plumbing are not speculative.

## Non-goals (v1)

- Publishing to Typst Universe (structure stays universe-ready; actual publish is a later decision).
- Back-index generation (backmatter leaves a hook; `in-dexter` integration later).
- Byte-identical rebuild of the prototype book (parity is validated, drift is acceptable).
- EPUB or HTML output.

## Decisions log

| Decision | Choice | Why |
|---|---|---|
| Margin-note engine | `marginalia:0.3.1` | Actively maintained; auto collision avoidance kills manual `dy` fudging; native two-sided `book` mode replaces the 12.7mm even-page `page-offset-x` hack; numbered notes, `notefigure`, `wideblock` built in |
| Markdown engine | `cmarker:0.1.10` | `html:` tag mapping (robust extension syntax), `blockquote:` hook, GitHub heading labels, native footnotes we can transform into sidenotes |
| Prototype book relationship | Private parity fixture | `tests/fixtures/proto/` is gitignored; real chapters compile against the new template to prove expressiveness without publishing the book's content |
| v1 classes | book + letter + handout + cover | Letter and handout share nearly everything with book; cover is a separate compile target as in the prototype |
| ISBN support | Copyright-page ISBN lines + EAN-13 cover barcode via `tiaoma:0.3.0` | Driving use case: a forthcoming author-owned 6×9 print + ebook title |
| Architecture basis | tufte-style's region model | Its bones were the best of the four; it just never got finished |
| Compiler | Typst 0.15+ | Required by cmarker 0.1.10; matches installed toolchain |

## Dependencies

```typ
#import "@preview/marginalia:0.3.1"
#import "@preview/cmarker:0.1.10"
#import "@preview/tiaoma:0.3.0"    // cover.typ only — EAN-13/ISBN barcode
```

No other external packages. `drafting` is retired.

## Repo layout

```
tuftelike/
  typst.toml               # package: tuftelike 0.1.0, entrypoint src/lib.typ, [template] → template/
  LICENSE                  # MIT
  README.md                # quickstart, API tables, cookbook
  justfile
  .envrc                   # TYPST_ROOT, PATH_add bin
  src/
    lib.typ                # public API surface; the only user-facing import
    themes.typ             # theme presets + fallback-chain resolution
    labels.typ             # localizable strings (Chapter, Appendix, Contents, Draft, …)
    geometry.typ           # paper presets AS DATA; media resolution; marginalia margin mapping
    typography.typ         # font stacks, text defaults, headings, newthought, lead-smallcaps,
                           # Tufte blockquote/epigraph-quote, callout label styles
    notes.typ              # sidenote / marginnote / notefigure / sidecite / wideblock
    runners.typ            # running heads, folios, page-number skip logic, alt-runners
    markdown.typ           # cmarker pipeline: md(), scope builder, extension registry,
                           # footnote→sidenote transform, image rebasing
    frontmatter.typ        # title, copyright, dedication, epigraph, TOC pages (polymorphic)
    mainmatter.typ         # chapters() manifest, part dividers, heading-numbering modes
    backmatter.typ         # about-author, colophon, bibliography, index hook
    chapter.typ            # chapter/part opener rendering (incl. icon registry)
    cover.typ              # wrap cover: front/spine/back, spine width calc, barcode zone
    classes/
      book.typ             # assembles: front → main → back
      letter.typ           # letterhead, date, recipient, salutation, body, closing, signature
      handout.typ          # tufte-memo lineage: abstract, doc number, distribution, footer pair
    extras/
      instructional.typ    # optional extension set: <prompt>, <response>, H3 icon keywords
  template/                # `typst init` scaffold: minimal book with content/*.md
  examples/
    book/  letter/  handout/  cover/
  tests/
    compile-matrix.sh      # class × paper × media smoke compiles
    fixtures/proto/        # GITIGNORED symlink/copy of prototype chapters for parity builds
  bin/
    table-to-typst         # carried over from the prototype book
  fonts/                   # GITIGNORED; loaded via --font-path (see Fonts)
```

Region modules (`frontmatter`, `mainmatter`, `backmatter`, `chapter`) consume engine modules (`geometry`, `typography`, `notes`, `runners`, `markdown`). Classes are assembly orders of regions. This is tufte-style's model, finished.

## Geometry: presets as data

Every paper preset is a dict; users may pass their own dict anywhere a preset name is accepted.

```typ
#let papers = (
  "crown-quarto": (              // prototype book's print-proven values, verbatim
    trim: (w: 189mm, h: 246mm),
    bleed: 3.18mm,
    safety: 12.7mm,
    note-col: 37mm,              // margin-note / extension width
    note-gap: 4mm,
    top-extra: 15mm,             // beyond bleed+safety
    bottom-extra: 3.17mm,
    gutter-table: ("0-60": 0mm, "61-150": 3mm, "151-400": 13mm,
                   "401-600": 16mm, "over-600": 19mm),
    screen-margin: (left: 25.7mm, right: 55mm, top: 25.4mm, bottom: 19.05mm),
  ),
  "us-trade-6x9": (
    trim: (w: 152.4mm, h: 228.6mm),
    bleed: 3.175mm,
    safety: 12.7mm,
    note-col: 26mm,              // INITIAL — tune against proofs
    note-gap: 4mm,
    top-extra: 10mm,
    bottom-extra: 3mm,
    gutter-table: (same Lulu table),   // KDP variant documented in cookbook
    screen-margin: (left: 22mm, right: 44mm, top: 22mm, bottom: 18mm),
  ),
  "us-letter": (                 // letter/handout default; tufte-letter's proven margins
    trim: (w: 215.9mm, h: 279.4mm), bleed: 0mm,
    note-col: 2in, note-gap: 0.5in,
    letter-margin: (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in),
    handout-margin: (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in),
  ),
)
```

Preset schemas vary by intended class (book papers carry gutter tables and screen margins; letter papers carry per-class margin recipes) — classes read the keys they need. A4/A5 presets are deferred to Future.

**Media resolution:** `media` param on every class; when `auto`, read `sys.inputs.media` (default `"screen"`). Print → page size = trim + 2×bleed, mirrored margins via marginalia `book: true`, recto chapter starts, unbreakable tables, no background fill. Screen → page size = trim, notes always outer-right (`book: false`), background `rgb("FFFFF8")`, weak pagebreaks.

**Marginalia mapping** (the load-bearing glue):

```
outer = (far: bleed(print) + safety, width: note-col, sep: note-gap)
inner = (far: bleed(print) + safety + gutter-table[page-count-range], width: 0mm, sep: 0mm)
top / bottom from preset extras
book: media == "print"
```

Body column width emerges from marginalia's setup rather than being computed twice (the duplicated-constants bug class in tufte-style-book dies here).

## Notes (marginalia wrappers, established API names)

```typ
#sidenote[content]                      // numbered, auto-positioned, collision-avoiding
#sidenote(dy: -2em)[content]            // dy remains an ESCAPE HATCH, never required
#marginnote[content]                    // unnumbered
#notefigure(image("x.png"), caption: […])
#sidecite(<key>, supplement: […])       // rebuilt; renders full citation form in margin;
                                        // requires class-level `bib:` (may be hidden)
#wideblock[content]                     // side: outer default; "both" available
```

- Notes render 9pt sans (theme-controlled), `leading: 0.5em`.
- Known upstream caveat: marginalia wideblocks misbehave across pagebreaks in `book: true` mode. Documented; print tables are unbreakable anyway (matches prototype behavior).

## Markdown pipeline

`md(path-or-content, root: auto)` wraps `cmarker.render` with the template scope pre-wired. Three invocation tiers for margin notes:

1. **Zero-syntax (headline feature):** standard `[^1]` markdown footnotes become numbered sidenotes via a footnote→sidenote transform. Toggle: `footnotes-as-sidenotes: true` on the CLASS (not `md()`): the transform is ordering-sensitive and must be installed before any margin-note call fires (spike finding).

**Numbering follows anchoring** (parity finding, matching both the prototype book and Tufte's own predominant practice): footnotes are numbered because the typed reference is an anchor; `<note>` and the legacy tier render unnumbered floating commentary; `<note numbered>` opts a tag note into numbering.
2. **Robust tags** via cmarker `html:` mapping: `<note>…</note>`, `<note src="sidenotes/eliza.md"/>`, `<margin>…</margin>` (unnumbered), `<wide>…</wide>`, plus registered extensions.
3. **Continuity forms** (so prototype-era content ports unedited): regex show-rules for `#note[…]` (inline and `.md`-file reference), fenced ```` ```note ```` blocks, `^ref^` / `^_ref_^` cross-references.

Also wired: `blockquote:` hook → Tufte quote style (attributed epigraph variant available); image path rebasing against a configurable content root; `heading-labels: "github"` + `label-prefix` (retires the prototype's `link_id` special-case table — verified against the ampersand headings in the parity fixture); `smart-punctuation` on.

**Extension registry.** `extensions: (name: handler, …)` merged over the default set. The instructional set — `<prompt>`, `<response>`, H3 icon keywords → SVG map — ships as an optional module (`src/extras/instructional.typ`) users import and pass in. Books register their own without touching the template.

## Typography & themes

- Stacks (theme-overridable): serif `ETbb → ETBembo → Palatino → Georgia`; sans `Gill Sans MT → Fira Sans → Helvetica Neue → Arial`; mono `Consolas → Menlo → Monaco`.
- Body 11pt serif, fill `luma(30)`. Headings italic serif (20/18/16/14/12pt), H1 as chapter opener (below), H2 with gray sans number, H3 with optional icon.
- `newthought[…]` and automatic `lead-smallcaps` (small-caps to first comma or third space) on chapter-opening paragraphs.
- **Theme resolution:** user arg > theme preset > default (tufte-style's chain). Theme dict covers fonts, sizes, colors (text fill, screen background, accent), note styling, and `draft: bool` (adds DRAFT mark from `labels`).
- `labels.typ`: localizable strings dict (`chapter`, `appendix`, `contents`, `draft`, `figure`, `table`, `code`, letter labels like `enclosures`), merged the same way.

## Regions

**frontmatter.typ** — sequence and pages from the prototype book: half-title/title page, copyright (bottom-pinned, smallcaps publisher block, ISBN lines — one per provided format, e.g. `ISBN 978-… (paperback)` / `ISBN 978-… (ebook)`), TOC, dedication, epigraph(s), introduction/preface/acknowledgments slots (each accepts content or `md(…)`). Polymorphic inputs kept: dedication/epigraph accept string, array, tuple, or dict. Visibility: providing an argument shows the page; explicit `toc: false`-style overrides exist for the always-on defaults. Front-matter pages use narrow margins (no note column), page numbers suppressed via the `<chapters-begin-here>` marker mechanism.

**mainmatter.typ** — `chapters(("ch1.md", "ch2.md", …), split: "odd" | "soft")` manifest helper replaces the prototype's manual `read()+chapter-split.md` concatenation; internally still ONE `cmarker.render` so labels and footnotes resolve across files. `parts:` config (array of `(title: …, first-chapter: n)` or explicit `#part[…]` calls) drives BOTH the TOC dividers and the part-divider pages — the hardcoded chapter-number matching in the prototype's TOC dies. Appendix mode: heading counter reset + `"A.1"` numbering + Appendix label detection (prototype behavior, now a function).

**chapter.typ** — opener rendering: small sans CHAPTER/APPENDIX label + number, italic serif title, `v(2.5em)`, full width into note column. Icon registry consulted for H3s.

**backmatter.typ** — about-the-author, colophon, bibliography rendering, index hook (no-op v1).

**runners.typ** — running heads as in the prototype: verso `pagenum␣␣␣CHAPTER`, recto `SECTION␣␣␣pagenum`, 8pt serif tracked; `alt-runners` dict for shortening; skip logic for chapter openers, blanks before recto starts, divider pages, front matter. Implementation may use `marginalia.header()` if the spike shows it plays better with the note column than `page(foreground:)`; decided in spike 1.

## Classes

```typ
// book
#show: book.with(
  paper: "crown-quarto",            // preset name or dict
  media: auto,                      // auto → sys.inputs.media → "screen"
  page-count-range: "151-400",
  title: […], subtitle: […], authors: (…), publisher: (…), release: […],
  copyright: (year: …, holders: …, disclaimer: …, extra: …, release-line: …,
              isbn: (paperback: "978-…", ebook: "978-…")),   // any subset of formats
  dedication: …, epigraphs: …,
  front: (introduction: md("…"), preface: …),
  parts: (…), alt-runners: (…),
  theme: (…), labels: (…), extensions: (…),
  bib: …,
)
#chapters(("content/ch1.md", …))

// letter — real correspondence structure (new; tufte-letter never had it)
#show: letter.with(
  paper: "us-letter", media: auto,
  from: (name: …, title: …, org: …, address: …, email: …),   // letterhead slot or dict
  to: (…), date: auto,              // auto → datetime.today()
  re: […], salutation: […],
  closing: […], signature: image("sig.png") | name,
  enclosures: (…), cc: (…),
  numbered-sections: false,          // hb8 mode: numbered body + unnumbered appendices
  theme: (…), extensions: (…),
)
Body as content or `#md("letter.md")`. Full note system live — same engine as book.

// handout — tufte-memo lineage via tufte-style
#show: handout.with(
  paper: "us-letter", media: auto,
  title: […], subtitle: […], authors: ((name:, role:, affiliation:, email:), …),
  abstract: […], document-number: […], distribution: […],
  footer-content: (first, rest), toc: false, bib: …,
)
```

Argument style: kebab-case throughout (Typst convention); tufte-style's snake_case/kebab mismatches die.

## Cover (separate compile target)

```typ
#cover(
  paper: "crown-quarto",
  page-count: 232,
  stock: "lulu-standard-bw",        // → spine mm/page constant; "kdp-white", "kdp-cream" included
  background: image("cover.jpg"),   // or color
  front: (author: …, title: …, subtitle: …, release: …, publisher: …),  // or content slot
  spine: (title: …, author: …),     // auto-hidden below printer minimum page count
  back: (blurb: …, overlay: rgb(0,0,0,60%)),
  barcode: (isbn: "978-…"),         // EAN-13 rendered in the white safe-zone via tiaoma
                                    // other forms: (review-copy: true) | image(…) | none
)
```

`barcode` forms: `(isbn: "978-…")` renders a real EAN-13 (an ISBN-13 encodes directly as EAN-13) with the human-readable ISBN above it; `(review-copy: true)` keeps the white box + REVIEW COPY stamp used for proof runs; `image(…)` drops in a printer-supplied barcode; `none` leaves the zone empty for printers that overlay their own (e.g. KDP).

Dimensions: `width = 2×trim.w + spine + 2×bleed`, `height = trim.h + 2×bleed`. Spine = `page-count × stock constant` (Lulu standard b&w ≈ 0.0572 mm/page — back-derived from the prototype cover's 13.03mm spine; constants re-verified against printer docs during implementation, sources linked in code). The prototype cover's numbers are the regression check.

## Build tooling

- `justfile`: `just install` (symlink into `@local/tuftelike/0.1.0`), `just demo book|letter|handout [print|screen]`, `just cover`, `just test` (compile matrix), `just proto-check` (parity fixture, skipped if absent), `just fonts-check`.
- All output toggles via `--input` (`media`, optionally `paper`) — **no source edits to change build targets** (fixes the prototype's edit-config.typ-to-build and tufte-letter's ignored `--input src=`).
- The parity fixture's source location is never committed: `just proto-check` resolves it from a `PROTO_BOOK_DIR` environment variable (set in an untracked `.envrc.local`), and `tests/fixtures/proto/` is gitignored.
- `bin/table-to-typst` carried over as-is.

## Fonts & licensing

Nothing committed. `fonts/` is gitignored, loaded via `--font-path fonts/`; README documents sourcing (ETbb via CTAN — license verified before any future vendoring; Gill Sans MT and Consolas are proprietary, taken from the user's system). Stacks degrade gracefully to Palatino/Fira/Menlo.

## Testing

1. **Compile matrix:** every class × paper preset × media must compile warning-free (`tests/compile-matrix.sh`, run by `just test`).
2. **Examples as goldens:** examples double as visual regression material; PDFs eyeballed, not pixel-diffed, in v1.
3. **Prototype parity fixture (gitignored):** real chapters + the continuity syntax forms compile under the new template; checks chapter openers, icons, tables-into-margin, part dividers, TOC, `link_id`-free labels, and cover numbers.

## Risks & spikes (ordered; spike 1 is the first implementation task)

1. **marginalia × cmarker anchoring** — notes fired from rendered markdown (all three tiers, especially footnote→sidenote) must anchor at the correct baseline and paginate sanely. Spike: one page exercising all tiers, both media modes. If footnote→sidenote proves unreliable, tier 1 ships behind a default-off flag and tiers 2–3 carry v1.
2. **Bleed vs marginalia's margin model** — page = bleed dims with bleed folded into `far` values; verify note/wideblock alignment against trim marks in both parities.
3. **Running heads implementation** — `marginalia.header()` vs `page(foreground:)`; pick whichever coexists with the note column and skip logic.
4. **6×9 numbers** — derived starting values; tune with printed proofs before calling the preset stable.
5. **Handout API drift** — normalize tufte-memo's argument names; breakage is contained to examples.

## What dies

Manual `dy` as a requirement · per-.md raw-typst margin boilerplate · regex-as-only-syntax · duplicated `frontmatter_page` and margin constants · per-book `main.typ` show-rule piles · hardcoded TOC part dividers · `link_id` special-case table · even-page `page-offset-x` hack · `drafting` dependency · ignored `--input` wiring · snake/kebab argument mismatches.

## Future (explicitly deferred)

Typst Universe publication · index generation (`in-dexter`) · additional classes ("and so on": report, article) · EPUB/HTML · pixel-based visual regression.
