# tuftelike

A Typst package for Tufte-style books, letters, and handouts — plus
print-ready wrap covers — built margin-note-first. Markdown is the default
authoring format: footnotes, inline tags, and a legacy bracket syntax all
become live margin notes automatically. Every class is equally usable from
pure Typst if you'd rather write natively. One `book()` / `letter()` /
`handout()` call handles frontmatter, running heads, chapter numbering, and
appendix mode; `cover()` computes spine width from page count and stock and
renders an EAN-13 barcode from a validated ISBN.

## Install

Requires [Typst](https://typst.app) 0.15.0+ and
[`just`](https://github.com/casey/just).

```
git clone https://github.com/claylo/tuftelike.git && cd tuftelike
just install
```

`just install` symlinks the repo into Typst's local package directory as
`@local/tuftelike:0.1.0`, so `#import "@local/tuftelike:0.1.0": *` resolves
from any project on your machine. Verify the install and run the compile
matrix:

```
just test
```

Start a new project from the bundled template:

```
typst init @local/tuftelike:0.1.0 my-book
cd my-book && env -u TYPST_PACKAGE_PATH typst compile main.typ
```

The `env -u TYPST_PACKAGE_PATH` shield guards against a broken global
`TYPST_PACKAGE_PATH` some shells carry (see [Environment](#environment) —
without it, `@local/…` imports can fail with `package not found`). Harmless
when your shell is clean; drop it once you've confirmed compiles work bare.

### Fonts

Nothing is vendored — `fonts/` is gitignored. Compile with
`--font-path fonts` so Typst picks up whatever you drop there, layered on
top of your system fonts:

- **ETbb** (serif body face, a Bembo-style family) — free, from CTAN:
  <https://ctan.org/pkg/etbb> (MIT / LPPL). Extract the OpenType files into
  `fonts/`.
- **Gill Sans MT** and **Consolas** (sans / mono) — proprietary, bundled
  with Microsoft Office. If they're already installed as system fonts,
  Typst finds them with no extra setup; otherwise the stacks fall back
  gracefully to Fira Sans / Helvetica Neue / Arial (sans) and Menlo / Monaco
  (mono). Font-fallback warnings during compile are expected and harmless.

```
just fonts-check   # confirms the three families are visible somewhere
                    # Typst can see them — system install or fonts/
```

## Environment

Every `just` recipe runs Typst through `env -u TYPST_PACKAGE_PATH` — a
shield against a mis-escaped global `TYPST_PACKAGE_PATH` some shells carry,
which otherwise makes `@local/…` imports fail with `package not found`.
That shield only applies inside `just` recipes. `.envrc` carries the same
fix (`unset TYPST_PACKAGE_PATH`) plus `TYPST_ROOT` and `bin/` on `PATH` (for
`table-to-typst`), but only takes effect in a shell where `direnv allow` has
run. If you invoke `typst` directly outside `just`, in a shell that hasn't
allowed direnv (CI, a fresh clone), either unset the variable yourself or
run through direnv explicitly:

```
direnv exec . typst compile --root . --font-path fonts examples/book/main.typ out/book.pdf
```

`.envrc` also loads a `.envrc.local` if one is present. That file is
untracked and never committed — it's where a local `PROTO_BOOK_DIR` can
point at a private manuscript for the parity fixture (`just proto-check`);
nothing under `tests/fixtures/proto/` is ever committed either.

## Quickstart

Every markdown-reading snippet starts with the same line:

```typ
#let reader = (p, ..a) => read(p, ..a.named())
```

This closure is **required, not style** — Typst resolves `read()` paths
relative to the file where the call is *written*. Defined in your file and
passed as `reader:`, paths resolve against your project; pass a bare `read`
and they'd resolve inside the tuftelike package, which fails.

### Book

```typ
#import "@local/tuftelike:0.1.0": *
#let reader = (p, ..a) => read(p, ..a.named())

#show: book.with(
  paper: "us-trade-6x9",
  title: "Margins of Error",
  authors: ("A. Demo Author",),
)

#show: begin-chapters.with(resolve-media())
#chapters(("content/chapter-one.md",), reader: reader,
  media: resolve-media(), content-root: "content")
```

Compile: `typst compile --root . --font-path fonts --input media=screen main.typ out.pdf`
(swap `media=print` for the bleed / mirrored-margin version). Full working
example: `examples/book/`.

### Letter

```typ
#import "@local/tuftelike:0.1.0": *
#let reader = (p, ..a) => read(p, ..a.named())

#show: letter.with(
  to: [A. Demo Author],
  salutation: [Dear A.,],
  closing: "Sincerely,",
  signature: "J. Query",
)

#md(reader("body.md"), reader: reader)
```

Full working example: `examples/letter/`.

### Handout

```typ
#import "@local/tuftelike:0.1.0": *

#show: handout.with(
  title: "Field Notes on Margin Width",
  authors: ((name: "A. Demo Author", role: "Editor"),),
)

Body content starts here — sidenotes, sidecites, and the same margin
machinery as book() are all available.
```

Full working example: `examples/handout/`.

## Note tiers

Markdown content gets three ways to put something in the margin, plus a
footnote shortcut:

**Numbering follows anchoring**, matching Tufte's own books: unnumbered
margin notes are the workhorse; numbered sidenotes appear only where a
precise in-text anchor matters.

- **Footnotes**, automatically: a standard `[^1]` / `[^1]: note text` pair
  becomes a **numbered** sidenote — the reference marker you typed IS the
  anchor. Opt out per class with `footnotes-as-sidenotes: false`.
- **HTML tags** (recommended): `<note>inline note</note>` renders
  **unnumbered** (floating commentary); add the attribute — `<note numbered>`
  — for a numbered sidenote. Pull the body from another file with
  `<note src="other.md"></note>`. Related tags: `<margin>…</margin>`
  (always unnumbered) and `<wide>…</wide>` (spans into the margin).
- **Legacy bracket syntax** (continuity tier, for content carried over from
  older sources): `#note[inline note]` — always unnumbered, exactly as the
  print-proven source rendered it.

> **`<note src="…">` must be closed explicitly.** `<note src="side.md"></note>`
> works; `<note src="side.md"/>` does not. cmarker registers `note` as a
> normal (non-void) HTML tag, so a self-closed form silently swallows
> everything from that point to the end of the file as the tag's "body."
> Verified directly: a file with a self-closed tag, followed by two more
> paragraphs and a heading, rendered only the text that came *before* the
> tag — everything after it vanished with no error or warning.

> **The legacy tier breaks on nested brackets.** `#note[a [citation] inside]`
> matches only up to the *first* `]` — the note text becomes `a [citation`
> and `` inside]`` leaks back into the body as literal text. There's no
> escaping mechanism for this. If your note content needs brackets, use the
> HTML tier instead.

## Paper presets

| Preset | Trim | Note column | Bleed | Typical use |
|---|---|---|---|---|
| `crown-quarto` | 189 × 246 mm | 37mm | 3.18mm | print-proven book default |
| `us-trade-6x9` | 152.4 × 228.6 mm (6×9in) | 26mm | 3.175mm | book — see tuning note below |
| `us-letter` | 215.9 × 279.4 mm (8.5×11in) | 2in, inside a 3in (letter) / 3.5in (handout) margin | none — one-sided | letter, handout |

> The `us-trade-6x9` note column (and its top/bottom extras) are **initial
> values** — tune them against printed proofs before treating the preset as
> stable. `crown-quarto`'s numbers are print-proven and shouldn't need
> adjustment.

Pass a custom dict with the same shape (`trim`, `bleed`, `safety`,
`note-col`, `note-gap`, `top-extra`, `bottom-extra`, `gutter-table`) to any
`paper:` param instead of a preset name.

## Media

Every class resolves screen vs. print from `--input media=`:

```
typst compile --input media=print  …   # bleed, mirrored margins, two-sided folios
typst compile --input media=screen …   # the ebook PDF — cream background, no bleed, notes always on the right
```

Screen is the default if `--input media=` is omitted.

## Cover

`cover()` is a separate compile target (not part of `book()`) that renders a
single wrap-around PDF: back panel, spine, front panel.

```typ
#import "@local/tuftelike:0.1.0": *

#cover(
  paper: "us-trade-6x9",
  page-count: 228,
  stock: "lulu-standard-bw",
  background: rect(width: 100%, height: 100%, fill: rgb("1a3a5c")),
  front: (author: "A. Demo Author", title: "Margins of Error",
    subtitle: "A Field Guide to Thinking in the Margins"),
  spine: (title: "Margins of Error", author: "A. Demo Author"),
  back: (blurb: [Back-cover copy goes here.]),
  barcode: (isbn: "978-1-0000-0000-9"),
)
```

Build it: `just cover` → `out/cover.pdf`. Full example: `examples/cover/`.

**Spine width** is `page-count × stock` (mm/page):

| Stock | mm / page |
|---|---|
| `lulu-standard-bw` | 0.0572mm |
| `kdp-white` | 0.0572mm (0.002252in/page) |
| `kdp-cream` | 0.0635mm (0.0025in/page) |

The spine panel is hidden automatically under 80 pages (printer minimum).
These mm/page constants are back-derived approximations — **proof the
spine** against a real printed copy before trusting it at a new page count
or stock.

**Barcode zone** (`barcode:` param), bottom-right of the back panel:

| Value | Renders |
|---|---|
| `(isbn: "978-…")` | EAN-13 via tiaoma — **the check digit must be valid**; tiaoma rejects a bad one at compile time |
| `(review-copy: true)` | "REVIEW COPY / NOT FOR RESALE" stamp, no barcode |
| any other content, e.g. `image("barcode.png")` | used as-is — a pre-made barcode image |
| `none` | no barcode zone at all |

## Theme & labels

Every class takes `theme:` and `labels:` dicts that merge over
`default-theme` / `default-labels` (explicit arg > dict > default, right
side wins on key collisions):

```typ
#show: handout.with(
  // …
  distribution: "Design Review, Production",
  labels: (distribution: "Circulation"),   // renames the "Distribution:" prefix
  theme: (body-size: 10pt, serif: ("Georgia",)),
)
```

> **Arrays replace wholesale, not merge.** `theme: (serif: ("Georgia",))`
> drops the entire fallback chain — you get Georgia only, no Palatino, no
> ETbb. Pass the full stack you want whenever you override a font array.

The book contents page follows the print-proven layout: part and appendix
group headers at the outline margin, chapter numbers right-aligned in their
own column, italic chapter titles with upright section entries one level
deeper, and page numbers tucked behind each title (Tufte's ragged style).
`theme: (toc-pagenums: "flush")` pushes page numbers to the right edge of
the line instead. `about-author()` and `colophon()` register themselves in
the contents and the PDF bookmarks automatically; the first unnumbered
section after the chapters and appendices opens the backmatter group with
a separator gap. Rename their entries (and the `APPENDICES` header) via
`labels: (about-author: …, colophon: …, appendices: …)`.

## Extensions

`extensions:` (on `md()`, and forwarded through `chapters()` /
`appendices()`) merges custom HTML tag handlers over the built-ins (`note`,
`margin`, `wide`):

```typ
#let my-extensions = (
  warning: (attrs, body) => block(fill: yellow.lighten(80%), inset: 0.6em)[
    Warning: #body],
)
#chapters(paths, reader: reader, extensions: my-extensions)
```

```markdown
<warning>Don't skip the proof stage.</warning>
```

The bundled `instructional` extension adds a prompt/response dialogue tag
pair (mono bold prompt, serif response) plus an icon keyword map, for
workshop- or course-style books:

```typ
#import "@local/tuftelike:0.1.0": instructional-extensions, instructional-icons

#chapters(paths, reader: reader,
  extensions: instructional-extensions(default-theme))
```

```markdown
<prompt>Split the hedges out of this sentence…</prompt>
<response>Main sentence: …</response>
```

## Cookbook: 6×9 print checklist

1. **Set `page-count-range`** on `book()` to match your actual final page
   count (`"0-60"`, `"61-150"`, `"151-400"`, `"401-600"`, `"over-600"`) — it
   selects the binding gutter from the paper preset's `gutter-table`. A
   mismatch under-guts or over-guts the inner margin.
2. **Pick the right `stock`** on `cover()` (`lulu-standard-bw`, `kdp-white`,
   `kdp-cream`) to match your printer — spine width depends on it.
3. **Place the ISBN twice**: `copyright.isbn` on `book()` prints it on the
   copyright page; `barcode: (isbn: …)` on `cover()` prints the scannable
   EAN-13. Same number, both places, valid check digit.
4. **Proof the spine.** The stock mm/page constants are approximations —
   order a printed proof and compare the physical spine width against
   `spine-width(page-count, stock)` before finalizing cover art.

## Credits

Built on [marginalia](https://typst.app/universe/package/marginalia)
(0.3.1) for margin-note layout and collision avoidance,
[cmarker](https://typst.app/universe/package/cmarker) (0.1.10) for the
CommonMark pipeline, and [tiaoma](https://typst.app/universe/package/tiaoma)
(0.3.0) for barcode rendering.

MIT licensed — see `LICENSE`.
