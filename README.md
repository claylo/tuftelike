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

Package pins (`marginalia`, `cmarker`, `tiaoma`, `in-dexter`) are plain
`@preview/name:version` import strings; `just outdated` compares them with
Typst Universe and `just update [name…]` rewrites every pin site to latest
and re-runs the tests (`bin/typst-deps` does the work; needs `curl` + `jq`).

Start a new project from the bundled template:

```
typst init @local/tuftelike:0.1.0 my-book
cd my-book && typst compile main.typ
```

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

`.envrc` (direnv) puts `bin/` on `PATH` (for `table-to-typst`) and loads an
untracked `.envrc.local` if present — that's where a local `PROTO_BOOK_DIR`
can point at a private manuscript for the parity fixture (`just proto-check`);
nothing under `tests/fixtures/proto/` is ever committed either. Nothing else
in the build depends on direnv.

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

#show: begin-chapters
#chapters(("content/chapter-one.md",), reader: reader, content-root: "content")
```

Compile: `typst compile --root . --font-path fonts main.typ out.pdf` (screen);
add `--input target=print` for the bleed / mirrored-margin version. Full working
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

Twenty-six presets named `<printer>-<trim>` — every mainstream Lulu and KDP paperback
trim — each tagged with a **tier** and a **status**:

- **Tier 1** (full Tufte, 11pt): `lulu-crown-quarto` (the print-proven default),
  `kdp-7.5x9.25`, `kdp-7.44x9.69`, `lulu-executive` / `kdp-7x10`, `kdp-8x10`,
  `lulu-us-letter` / `kdp-8.5x11`, `lulu-a4` / `kdp-a4`, plus two landscapes.
- **Tier 2** (Tufte at 10pt — recommends the `tier2` type preset): `lulu-us-trade` /
  `kdp-6x9`, `lulu-royal` / `kdp-6.14x9.21`, `kdp-6.69x9.61`, `lulu-comic`.
- **Tier 3** (no note column; notes become footnotes; `tier3`): `lulu-digest` /
  `kdp-5.5x8.5`, `lulu-a5`, `lulu-novella` / `kdp-5x8`, `kdp-5.25x8`, `kdp-5.06x7.81`,
  `lulu-pocketbook`.

Only `lulu-crown-quarto` is `proven`; the rest are `initial` — derived from it and
measured (`just measure <paper>`), not yet held in a hand. Legacy names `crown-quarto`,
`us-trade-6x9`, `us-letter` still resolve. Printer rules (KDP bleeds the outside edge
only; the two gutter tables; spine formulas; Lulu coil) are data in `src/geometry.typ`.
Full table, printer facts, bindings, and how to promote a paper:
[`docs/papers.md`](docs/papers.md).

## Build targets (screen / print / printer / binding)

One source, several outputs. Built-in targets are `screen` (default: cream page, no
bleed, notes always right) and `print` (bleed, mirrored margins, two-sided folios, at
the class's `paper:`). Add your own on any class and flip them at compile time:

```typ
#show: book.with(
  paper: "kdp-7.5x9.25",
  targets: (kdp: (media: "print", paper: "kdp-7.5x9.25"),
            coil: (media: "print", paper: "lulu-us-letter", binding: "coil")),
)
```

```
typst compile main.typ                        # screen
typst compile --input target=kdp  main.typ    # KDP edition
typst compile --input target=coil main.typ    # Lulu coil build
typst compile --input media=print main.typ    # still works (alias for the built-in print target)
```

Inside a class media is ambient: `#show: begin-chapters` takes no argument, and
`chapters()` / `appendices()` have no `media:` param.

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
`default-theme` / `default-labels`. The theme is **fonts + roles**: three
named font stacks, and one role per text site in the package (body, note,
folio, headings, chapter label, TOC rows, title page, cover, …). Every role
carries the same six keys — `font`, `size`, `weight`, `style`, `tracking`,
`fill` — plus spacing keys where the role owns vertical rhythm (`above`,
`below`, named gaps). `auto` on any key means "inherit".

```typ
#show: book.with(
  // …
  labels: (chapter: "Kapitel"),
  theme: (
    fonts: (serif: ("Times New Roman", "Times"), sans: ("Helvetica Neue", "Helvetica")),
    body: (size: 10pt),
    heading: (h2: (font: "sans", weight: "bold", style: "normal", above: 1.2em, below: 0.4em)),
    justify: false,   // the default — no class justifies unless you say so
  ),
)
```

Rules of the road:

- **Font aliases.** A role's `font` is `"serif"`, `"sans"`, or `"mono"`
  (resolved against `theme.fonts`) or an explicit stack. Swapping the serif
  is one line; any single role can still diverge.
- **Deep merge.** Dicts merge at every level, so `theme: (heading: (h2:
  (weight: "bold")))` touches exactly one key. Arrays — font stacks — replace
  wholesale: `fonts: (serif: ("Georgia",))` drops the whole fallback chain.
  Pass the full stack you want.
- **`default-theme` is the complete list of knobs.** Read
  `src/themes.typ` — every size, tracking, weight, colour, and gap the
  package renders is there and nowhere else (`tests/lint-hardcoded.sh`
  enforces it). Its values ARE the print-proven Tufte look.
- **Long-form reference:** [`docs/theming.md`](docs/theming.md) — every role, key
  by key, plus recipes and the extension primitives.
- **Helpers read the theme for you.** `sidenote`, `marginnote`,
  `newthought`, `tufte-quote`, `md`, `part-divider`, `about-author`,
  `colophon`, `book-index`, `instructional-extensions` all pick up the
  class's theme and labels automatically. Pass `theme:` / `labels:` only to
  override.

### Theme variants: flip at compile time

Every class also takes `presets:` — named theme overlays selected with
`--input theme=<name>` (same pattern as `target`), so one source file can
print a book more than one way without edits:

```typ
#show: book.with(
  // …
  theme: (fonts: (serif: my-fonts)),        // unconditional — applies to every variant
  presets: ("trade": (body: (size: 10pt), toc-pagenums: "flush")),
)
```

```sh
just demo book print          # Tufte defaults (= the beautiful-evidence preset)
just demo book print trade    # the de-Tufted variant, out/book-print-trade.pdf
```

Resolution: `theme:` dict > selected preset overlay > defaults. Selection:
`theme-preset:` argument > `--input theme=<name>` > none. Built-in preset
names live in `theme-presets` (`beautiful-evidence` selects the defaults);
style presets from the Tufte shelf land there as they're proven.

**Shared preset library.** `presets:` takes any dict, so keep your variants
in one file and symlink it into each book project instead of copy-pasting
(see `examples/book/themes.typ`):

```sh
ln -s ~/writing/my-themes.typ themes.typ
```

```typ
#import "themes.typ": book-presets
#show: book.with(presets: book-presets, /* … */)
```

Being a normal module, the library file can hold helper functions, shared
font stacks, and its own imports.

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
  extensions: instructional-extensions())
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
