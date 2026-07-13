# tuftelike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `tuftelike` Typst package per `docs/superpowers/specs/2026-07-10-tuftelike-design.md` — Tufte-style book/letter/handout classes plus wrap-cover builder, marginalia-powered margin notes, markdown-first authoring.

**Architecture:** Engine modules (`geometry`, `typography`, `notes`, `runners`, `markdown`) feed region modules (`frontmatter`, `mainmatter`, `backmatter`, `chapter`); classes (`book`, `letter`, `handout`) are assembly orders of regions; `cover` is a separate compile target. Paper presets are data. Print/screen resolved from `--input media=`.

**Tech Stack:** Typst 0.15.0 · `marginalia:0.3.1` · `cmarker:0.1.10` · `tiaoma:0.3.0` (cover only) · just · bash

**House rules (override any skill defaults):**
- **NO git worktrees.** Work directly in this repo on the current branch.
- **NO `git commit` by agents.** Each phase-end step stages files and writes/appends `commit.txt`; Clay runs `gtxt` himself.
- **Naming:** the private source book is only ever "the prototype book." Its repo path lives ONLY in the untracked `.envrc.local` as `PROTO_BOOK_DIR`. Never write that path, the book's title, or any person's name into committed files. Say "print-proven," never "shipped."
- **Testing model:** Typst has no unit-test runner. Unit-ish tests = `tests/assert/*.typ` files full of compile-time `#assert` calls (a failing assert fails the compile — that's the red/green signal). Layout tests = compile smoke + explicit eyeball checklists against the output PDF.
- Fonts may be absent early on; Typst falls back down the stacks (warnings OK during development, ETbb expected before final visual checks — Task 20 wires `fonts/`).

**Verification quickies:** `just test` (assert files + compile matrix) · `just demo book print` · open PDFs from `out/`.

---

## File structure (locked by this plan)

```
typst.toml  LICENSE  README.md  justfile  .gitignore  .envrc  (.envrc.local untracked)
src/
  lib.typ                # sole public import; re-exports everything below
  geometry.typ           # papers dict, media/paper resolution, page-size, marginalia-config
  labels.typ             # localizable strings + merge
  themes.typ             # theme defaults + merge chain
  utils.typ              # plain-text, misc pure helpers
  typography.typ         # font stacks, text/heading/quote rules, newthought, lead-smallcaps
  notes.typ              # sidenote/marginnote/notefigure/sidecite/wideblock (marginalia)
  markdown.typ           # md(), scope builder, html+regex note tiers, footnote transform
  frontmatter.typ        # title/copyright(+ISBN)/dedication/epigraph/TOC pages
  chapter.typ            # chapter openers, icon registry, part-divider page
  runners.typ            # running heads + folio skip logic
  mainmatter.typ         # chapters() manifest, appendix mode
  backmatter.typ         # about-author, colophon, bibliography wiring
  classes/book.typ  classes/letter.typ  classes/handout.typ
  cover.typ              # wrap cover + spine calc + barcode (tiaoma)
  extras/instructional.typ
template/main.typ  template/content/…        # typst init scaffold
examples/book/  examples/letter/  examples/handout/  examples/cover/
tests/assert/*.typ  tests/spike/  tests/compile-matrix.sh  tests/fixtures/proto/ (gitignored)
bin/table-to-typst
fonts/ (gitignored)  out/ (gitignored)
```

State plumbing: one `state("tuftelike", (:))` dictionary set by each class (media, paper, theme, labels, page-count-range, alt-runners). Modules read it via `context`.

---

# Phase 0 — Scaffold & Spike

### Task 1: Repo scaffold + local package install

**Files:** Create `typst.toml`, `LICENSE`, `.gitignore`, `.envrc`, `.envrc.local` (untracked), `justfile`, `src/lib.typ`, `tests/assert/smoke.typ`.

- [ ] **Step 1: Write `typst.toml`**

```toml
[package]
name = "tuftelike"
version = "0.1.0"
entrypoint = "src/lib.typ"
authors = ["Clay Loveless <clay@loveless.net>"]
license = "MIT"
description = "Tufte-style Typst templates: books, letters, handouts, and print-ready wrap covers with margin-note-first layout"
repository = "https://github.com/claylo/tuftelike"
keywords = ["tufte", "book", "letter", "template", "margin-notes", "print"]
categories = ["book", "layout"]
compiler = "0.15.0"

[template]
path = "template"
entrypoint = "main.typ"
```

- [ ] **Step 2: Write `.gitignore`**

```gitignore
out/
fonts/
tests/fixtures/proto/
.envrc.local
*.pdf
.DS_Store
```

- [ ] **Step 3: Write `.envrc` and `.envrc.local`**

`.envrc` (committed):
```bash
export TYPST_ROOT="$PWD"
PATH_add bin
source_env_if_exists .envrc.local
```

`.envrc.local` (untracked — verify `git check-ignore .envrc.local` prints the path after creating). Set `PROTO_BOOK_DIR` to the prototype book's repo directory — Clay knows the path; it must never appear in a committed file:
```bash
export PROTO_BOOK_DIR="<absolute path to the private prototype book repo>"
```
Then run `direnv allow`.

- [ ] **Step 4: Write `LICENSE`** — standard MIT text, copyright "2026 Clay Loveless".

- [ ] **Step 5: Write minimal `src/lib.typ`**

```typ
// tuftelike — public API. Users import ONLY this file.
#let tuftelike-version = version(0, 1, 0)
```

- [ ] **Step 6: Write `justfile`**

```just
# env -u shields against a mis-escaped global TYPST_PACKAGE_PATH; no-op otherwise
typst := "env -u TYPST_PACKAGE_PATH typst"
pkgdir := env_var('HOME') / "Library/Application Support/typst/packages/local/tuftelike"

# symlink this repo as @local/tuftelike:0.1.0
install:
    mkdir -p "{{pkgdir}}"
    ln -sfn "$(pwd)" "{{pkgdir}}/0.1.0"

# compile-time assertion tests + compile matrix
test: install
    mkdir -p out
    for f in tests/assert/*.typ; do echo "== $f"; {{typst}} compile --root . --font-path fonts "$f" out/assert.pdf || exit 1; done
    if [ -x tests/compile-matrix.sh ]; then tests/compile-matrix.sh; fi

# build an example: just demo book print
demo target media="screen": install
    mkdir -p out
    {{typst}} compile --root . --font-path fonts --input media={{media}} examples/{{target}}/main.typ out/{{target}}-{{media}}.pdf
```

- [ ] **Step 7: Write failing smoke test `tests/assert/smoke.typ`**

```typ
#import "@local/tuftelike:0.1.0": tuftelike-version
#assert(tuftelike-version == version(0, 1, 0))
```

- [ ] **Step 8: Run it — fail first, then pass**

Run: `typst compile --root . tests/assert/smoke.typ out/assert.pdf`
Expected BEFORE `just install`: error `package not found: @local/tuftelike`.
Run: `just install && just test`
Expected: `== tests/assert/smoke.typ` then success (matrix script absent yet — tolerated by `|| true` guard).

- [ ] **Step 9: Stage + start `commit.txt`**

```bash
git add typst.toml LICENSE .gitignore .envrc justfile src/lib.typ tests/assert/smoke.typ
```
Write `commit.txt`:
```
chore(scaffold): package skeleton, local install, assert-test harness
```

### Task 2: Spike — marginalia × cmarker × footnotes (DECIDES three things)

**Files:** Create `tests/spike/spike.typ`, `tests/spike/spike-content.md`, `tests/spike/FINDINGS.md`.

Spike answers, recorded in `FINDINGS.md` (committed; keep it name-free):
(a) exact marginalia param names (`counter`/numbering off-switch, setup keys), (b) does bare `read` pass as a closure or does the user need `(p, ..a) => read(p, ..a.named())`, (c) footnote→sidenote viability, (d) bleed folding into `far` values, (e) `marginalia.header()` vs `page(foreground:)` for runners.

- [ ] **Step 1: Write `tests/spike/spike-content.md`**

```markdown
# Spike Heading

Body text with a plain markdown footnote.[^one]

A tag note <note>via html mapping</note> and a legacy regex note #note[via regex].

An image: ![alt](img.svg)

[^one]: I should render as a numbered margin note.
```

- [ ] **Step 2: Write `tests/spike/spike.typ`** (exercises every integration on ~2 pages, both medias via `--input media=`)

```typ
#import "@preview/marginalia:0.3.1" as marginalia
#import "@preview/cmarker:0.1.10" as cmarker

#let media = sys.inputs.at("media", default: "screen")
#let bleed = if media == "print" { 3.18mm } else { 0mm }

#show: marginalia.setup.with(
  inner: (far: bleed + 12.7mm + 13mm, width: 0mm, sep: 0mm),
  outer: (far: bleed + 12.7mm, width: 37mm, sep: 4mm),
  top: bleed + 12.7mm + 15mm, bottom: bleed + 12.7mm + 3.17mm,
  book: media == "print",
)
#set page(width: 189mm + 2 * bleed, height: 246mm + 2 * bleed,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })

#let sidenote(body) = marginalia.note(text(size: 9pt, font: ("Gill Sans MT", "Helvetica Neue"), body))
// (e) runner probe — try marginalia.header here; fall back to page foreground if it fights the note column

Native note.#sidenote[I am a native marginalia note.]

// (b) reader-closure probe
#let reader = (p, ..a) => read(p, ..a.named())

// (c) footnote transform + (a) html mapping + regex tier
#let note-match = regex("#note\\[((?s).*?)\\]")
#show note-match: it => sidenote(it.text.matches(note-match).first().captures.at(0))
#show footnote: it => sidenote(it.body)

#cmarker.render(
  reader("spike-content.md"),
  html: (note: (attrs, body) => sidenote(body)),
  scope: (image: (path, alt: none) => image(bytes(reader(path, encoding: none)), alt: alt)),
)

Unnumbered probe: #marginalia.note(counter: none)[no marker on me] // (a) fix param per docs if this errors
#marginalia.wideblock[#rect(width: 100%, height: 2em)] // wide probe
#pagebreak()
Second page — verify notes land in the OUTER margin here in print media (verso).
```

Also create `tests/spike/img.svg`: `<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40"><circle cx="20" cy="20" r="18" fill="none" stroke="black"/></svg>`

- [ ] **Step 3: Compile both medias**

Run: `typst compile --root . tests/spike/spike.typ out/spike-screen.pdf && typst compile --root . --input media=print tests/spike/spike.typ out/spike-print.pdf`
Expected: both compile. If `marginalia.note(counter: none)` or setup keys error, open the package docs at `~/Library/Caches/typst/packages/preview/marginalia/0.3.1/` (README + example PDFs land there after first compile) and correct names.

- [ ] **Step 4: Eyeball checklist (both PDFs)** — footnote appears as numbered margin note with superscript anchor; html `<note>` and regex `#note[…]` both in margin; image renders (bytes path works); page 2 of print PDF has notes on the LEFT (outer/verso); no overlapping notes.

- [ ] **Step 5: Write `tests/spike/FINDINGS.md`** — one bullet per question (a)–(e) with the verified answer, e.g. exact unnumbered-note parameter, whether `reader: read` shorthand also works (try swapping once), chosen runner mechanism. Later tasks consult this file.

- [ ] **Step 6: Stage + append `commit.txt`**

```bash
git add tests/spike/
```
Append to `commit.txt` (leading blank line):
```
test(spike): validate marginalia+cmarker anchoring, footnote transform, reader pattern
```
**CHECKPOINT: ask Clay to review FINDINGS.md and run `gtxt`.** Spike outcome applied: footnote→sidenote is viable but ordering-sensitive — the transform lives in `notes.typ` as `footnote-transform` and classes install it early, gated by a class-level `footnotes-as-sidenotes: true` param (Tasks 13–15).

---

# Phase 1 — Engine

### Task 3: geometry.typ

**Files:** Create `src/geometry.typ`, `tests/assert/geometry.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Write failing asserts `tests/assert/geometry.typ`**

```typ
#import "@local/tuftelike:0.1.0": papers, resolve-paper, resolve-media, page-size, marginalia-config

#let cq = resolve-paper("crown-quarto")
#assert(cq.trim.w == 189mm and cq.trim.h == 246mm)
#assert(resolve-paper((trim: (w: 1mm, h: 2mm))).trim.h == 2mm) // custom dicts pass through

#let ps = page-size(cq, "print")
#assert(ps.width == 189mm + 2 * 3.18mm and ps.height == 246mm + 2 * 3.18mm)
#assert(page-size(cq, "screen").width == 189mm)

#let mc = marginalia-config(cq, "print", page-count-range: "151-400")
#assert(mc.book == true)
#assert(mc.inner.far == 3.18mm + 12.7mm + 13mm)   // bleed + safety + gutter
#assert(mc.outer.far == 3.18mm + 12.7mm)
#assert(mc.outer.width == 37mm and mc.outer.sep == 4mm)
#let ms = marginalia-config(cq, "screen", page-count-range: "151-400")
#assert(ms.book == false and ms.inner.far == 12.7mm + 13mm) // no bleed on screen

#let t69 = resolve-paper("us-trade-6x9")
#assert(t69.trim.w == 152.4mm and t69.note-col == 26mm)
#assert(t69.bleed == 3.175mm and t69.safety == 12.7mm and t69.top-extra == 10mm and t69.bottom-extra == 3mm) // pin tuning baseline
#assert(marginalia-config(cq, "print", page-count-range: "61-150").inner.far == 3.18mm + 12.7mm + 3mm) // gutter param threads through
#let usl = resolve-paper("us-letter")
#assert(usl.letter-margin == (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in))
#assert(usl.handout-margin == (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in))
#assert(resolve-media(media: "print") == "print") // explicit arg wins over sys.inputs
#assert(resolve-media() == "screen") // no --input media set during tests
```

- [ ] **Step 2: Run to verify fail** — `just test` → error: unknown import `papers`.

- [ ] **Step 3: Write `src/geometry.typ`**

```typ
// All paper geometry is DATA. Print-proven crown-quarto values come from the
// prototype book, verbatim. 6x9 note-col/top/bottom are initial values — tune
// against printed proofs before calling the preset stable.
// A paper preset dict requires: trim(w,h), bleed, safety, note-col, note-gap,
// top-extra, bottom-extra, gutter-table. Custom dicts passed to resolve-paper
// need that same shape for marginalia-config/page-size to work.
#let lulu-gutter-table = (
  "0-60": 0mm, "61-150": 3mm, "151-400": 13mm, "401-600": 16mm, "over-600": 19mm,
)

#let papers = (
  "crown-quarto": (
    trim: (w: 189mm, h: 246mm), bleed: 3.18mm, safety: 12.7mm,
    note-col: 37mm, note-gap: 4mm, top-extra: 15mm, bottom-extra: 3.17mm,
    gutter-table: lulu-gutter-table,
  ),
  "us-trade-6x9": (
    trim: (w: 152.4mm, h: 228.6mm), bleed: 3.175mm, safety: 12.7mm,
    note-col: 26mm, note-gap: 4mm, top-extra: 10mm, bottom-extra: 3mm,
    gutter-table: lulu-gutter-table,
  ),
  // letter/handout classes read letter-margin/handout-margin directly and
  // bypass marginalia-config — hence the minimal one-entry gutter-table.
  "us-letter": (
    trim: (w: 215.9mm, h: 279.4mm), bleed: 0mm, safety: 12.7mm,
    note-col: 2in, note-gap: 0.5in, top-extra: 25.4mm, bottom-extra: 19mm,
    gutter-table: ("0-60": 0mm),
    letter-margin: (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in),
    handout-margin: (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in),
  ),
)

#let resolve-media(media: auto) = {
  if media != auto { media } else { sys.inputs.at("media", default: "screen") }
}

#let resolve-paper(paper) = {
  if type(paper) == str { papers.at(paper) } else { paper }
}

#let page-size(paper, media) = {
  let b = if media == "print" { paper.bleed } else { 0mm }
  (width: paper.trim.w + 2 * b, height: paper.trim.h + 2 * b)
}

// Maps a paper preset onto marginalia's margin model. Inner column carries the
// binding gutter; outer column carries the note column. Screen = no bleed, one-sided.
#let marginalia-config(paper, media, page-count-range: "151-400") = {
  let b = if media == "print" { paper.bleed } else { 0mm }
  // no default: a typo'd page-count-range must FAIL LOUDLY, not silently
  // produce a 0mm binding gutter (0mm is a legitimate value for short books,
  // so a silent fallback would be indistinguishable from a real one)
  let gutter = paper.gutter-table.at(page-count-range)
  (
    inner: (far: b + paper.safety + gutter, width: 0mm, sep: 0mm),
    outer: (far: b + paper.safety, width: paper.note-col, sep: paper.note-gap),
    top: b + paper.safety + paper.top-extra,
    bottom: b + paper.safety + paper.bottom-extra,
    book: media == "print",
  )
}
```

- [ ] **Step 4: Re-export in `src/lib.typ`** — append:

```typ
#import "geometry.typ": papers, resolve-media, resolve-paper, page-size, marginalia-config
```

- [ ] **Step 5: Run `just test`** — Expected: PASS (both assert files).

- [ ] **Step 6: Stage** — `git add src/geometry.typ src/lib.typ tests/assert/geometry.typ`

### Task 4: labels.typ + themes.typ

**Files:** Create `src/labels.typ`, `src/themes.typ`, `tests/assert/theme.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Failing asserts `tests/assert/theme.typ`**

```typ
#import "@local/tuftelike:0.1.0": default-labels, resolve-labels, default-theme, resolve-theme
#assert(default-labels.chapter == "Chapter")
#assert(resolve-labels((chapter: "Kapitel")).chapter == "Kapitel")
#assert(resolve-labels((chapter: "Kapitel")).appendix == "Appendix") // merge keeps defaults
#assert(default-theme.body-size == 11pt)
#let t = resolve-theme((body-size: 10pt))
#assert(t.body-size == 10pt and t.note-size == 9pt)
#assert(t.serif.first() == "ETbb")
#assert(default-theme.draft == false)
#assert(default-theme.h1-size == 20pt)
#let t2 = resolve-theme((serif: ("Override",)))
#assert(t2.serif == ("Override",)) // arrays replace wholesale
#assert(t2.body-size == 11pt) // untouched keys preserved through array override
```

- [ ] **Step 2: Run `just test`** — fail: unknown `default-labels`.

- [ ] **Step 3: Write `src/labels.typ`**

```typ
#let default-labels = (
  chapter: "Chapter", appendix: "Appendix", part: "Part", contents: "Contents",
  figure: "Figure", table: "Table", code: "Code",
  draft: "DRAFT", version: "Version",
  enclosures: "Enclosures", cc: "cc", review-copy: "REVIEW COPY\nNOT FOR RESALE",
)
#let resolve-labels(user) = default-labels + user
```

- [ ] **Step 4: Write `src/themes.typ`**

```typ
// Resolution chain everywhere: explicit arg > theme dict > these defaults.
#let default-theme = (
  serif: ("ETbb", "ETBembo", "Palatino", "Georgia"),
  sans: ("Gill Sans MT", "Fira Sans", "Helvetica Neue", "Arial"),
  mono: ("Consolas", "Menlo", "Monaco"),
  body-size: 11pt, note-size: 9pt, folio-size: 8pt,
  h1-size: 20pt, h2-size: 18pt, h3-size: 16pt, h4-size: 14pt, h5-size: 12pt,
  text-fill: luma(30),
  screen-bg: rgb("FFFFF8"),
  note-leading: 0.5em,
  draft: false,
)
// Shallow merge, right side wins. Arrays REPLACE wholesale: overriding serif
// with ("MyFont",) drops the fallbacks — pass the full stack you want.
#let resolve-theme(user) = default-theme + user
```

- [ ] **Step 5: Re-export in `src/lib.typ`**, run `just test` — PASS. Stage all three files.

### Task 5: utils.typ + typography.typ

**Files:** Create `src/utils.typ`, `src/typography.typ`, `tests/assert/typography.typ`, `tests/visual/typography-page.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Failing asserts `tests/assert/typography.typ`**

```typ
#import "@local/tuftelike:0.1.0": plain-text, lead-split
#assert(plain-text([Hello *world*]) == "Hello world")
// lead-split: head = up to first comma OR third space, whichever first
#assert(lead-split("One two three four") == ("One two three", " four"))
#assert(lead-split("Once, upon a time") == ("Once", ", upon a time"))
#assert(lead-split("Hi") == ("Hi", ""))
// realistic heading constructs runners.typ will feed plain-text
#assert(plain-text(smallcaps[Chapter Title]) == "Chapter Title")
#assert(plain-text(link("https://example.com")[Click here]) == "Click here")
#assert(plain-text([]) == "")
// boundary inputs
#assert(lead-split("") == ("", ""))
#assert(lead-split(",abc") == ("", ",abc"))
// unicode regression locks (byte-vs-cluster corruption)
#assert(lead-split("Café one two three") == ("Café one two", " three"))
#assert(lead-split("日本語のテスト, comma after multibyte") == ("日本語のテスト", ", comma after multibyte"))
```

- [ ] **Step 2: `just test`** — fail. **Step 3: Write `src/utils.typ`**

```typ
// Recursively flatten content to a plain string (used by runners + lead-smallcaps).
#let plain-text(it) = {
  if type(it) == str { it }
  else if it == [ ] { " " }
  else if it.has("children") {
    // join() on an empty array returns none, not "" — guard the contract
    let kids = it.children.map(plain-text)
    if kids.len() == 0 { "" } else { kids.join("") }
  }
  else if it.has("text") { plain-text(it.text) }
  else if it.has("body") { plain-text(it.body) }
  else { "" }
}

// Split for Tufte lead-in small caps: up to first comma or third space.
// Tracks BYTE offsets while iterating clusters — position()/slice() are
// byte-based; mixing in cluster counts corrupts multibyte text ("Café …").
#let lead-split(s) = {
  let comma = s.position(",")
  let spaces = ()
  let pos = 0
  for ch in s.clusters() {
    if ch == " " { spaces.push(pos) }
    pos += ch.len()
  }
  let third = if spaces.len() >= 3 { spaces.at(2) } else { s.len() }
  let stop = calc.min(if comma == none { s.len() } else { comma }, third)
  (s.slice(0, stop), s.slice(stop))
}
```

- [ ] **Step 4: Write `src/typography.typ`**

```typ
#import "utils.typ": plain-text, lead-split

#let newthought(theme, body) = {
  v(1em, weak: true)
  text(font: theme.serif, tracking: 0.05em, smallcaps(plain-text(body)))
}

#let lead-smallcaps(body) = {
  let (head, tail) = lead-split(plain-text(body))
  [#smallcaps(head)#tail]
}

// Tufte blockquote: indented, no bar, roomy. Attributed variant for epigraphs.
#let tufte-quote(theme, body, attribution: none) = block(inset: (left: 1.5em, right: 1em))[
  #body
  #if attribution != none [ #v(0.3em) #align(right, text(style: "italic", [— #attribution])) ]
]

// Applies document-wide text + heading + list + figure-caption rules.
// `note-ext` = how far captions/openers extend into the note column.
#let base-style(theme, labels, note-ext, doc) = {
  set text(font: theme.serif, size: theme.body-size, fill: theme.text-fill)
  set par(justify: true, leading: 0.65em)
  set list(indent: 0.05em, spacing: 0.65em, body-indent: 0.7em)
  set enum(indent: 0.05em, spacing: 0.65em, body-indent: 0.7em)
  show heading: set text(font: theme.serif, weight: "regular", style: "italic")
  // level 1 needs an explicit size: the base show-heading override suppresses
  // Typst's built-in heading scaling (measured h1 at 9.92pt without this —
  // smaller than h3). chapter.typ replaces level-1 rendering for books.
  show heading.where(level: 1): set text(size: theme.h1-size)
  show heading.where(level: 2): set text(size: theme.h2-size)
  show heading.where(level: 3): set text(size: theme.h3-size)
  show heading.where(level: 4): set text(size: theme.h4-size)
  show heading.where(level: 5): set text(size: theme.h5-size)
  set heading(numbering: none) // mainmatter turns numbering on
  show figure.caption: it => block(width: 100% + note-ext)[
    #text(font: theme.sans, size: theme.note-size)[
      #it.supplement #context it.counter.display(it.numbering)#linebreak()#it.body]
  ]
  show quote.where(block: true): it => tufte-quote(theme, it.body,
    attribution: it.attribution)
  if theme.draft {
    set page(foreground: rotate(-55deg,
      text(size: 96pt, fill: luma(85), font: theme.sans, labels.draft)))
    doc
  } else { doc }
}
```

- [ ] **Step 5: Re-export (`plain-text`, `lead-split`, `newthought`, `lead-smallcaps`, `tufte-quote`, `base-style`) in `src/lib.typ`; `just test`** — PASS.

- [ ] **Step 6: Visual smoke `tests/visual/typography-page.typ`** — one page using `base-style` with defaults, headings 1–5, a block quote with attribution, `#lead-smallcaps("Call me Ishmael, or something")`. Compile: `typst compile --root . --font-path fonts tests/visual/typography-page.typ out/typography.pdf`. Eyeball: italic serif headings, off-black text, quote indented without a bar. Stage everything.

### Task 6: notes.typ

**Files:** Create `src/notes.typ`, `tests/visual/notes-page.typ`. Modify `src/lib.typ`.
**Consult `tests/spike/FINDINGS.md` (a) before Step 1 — adjust marginalia param names if the spike found different ones. Spike addendum: marginalia's default markers are a symbol cycle (●○◆…); Tufte convention is arabic superscripts, so `sidenote` must set arabic numbering explicitly (verify the exact `numbering:`/`anchor-numbering:` form against the cached marginalia source).**

- [ ] **Step 1: Write `src/notes.typ`**

```typ
#import "@preview/marginalia:0.3.1" as marginalia

// Tufte convention is arabic superscript numerals, not marginalia's default
// symbol cycle (note-markers-alternating: ● ○ ◆ ◇ …). `numbering:` on
// marginalia.note() drives BOTH the margin marker and the in-text anchor —
// anchor-numbering defaults to auto, which falls back to numbering
// (marginalia/lib.typ note(), ~L618-624). This is the package's own
// documented override for "superscript numbers" (lib.typ ~L611-612).
#let arabic-note-numbering = (..i) => super(numbering("1", ..i))

// Numbered Tufte sidenote. dy stays as an ESCAPE HATCH; marginalia positions
// and collision-avoids automatically.
#let sidenote(dy: 0pt, theme: (:), body) = marginalia.note(dy: dy,
  numbering: arabic-note-numbering,
  text(size: theme.at("note-size", default: 9pt),
       font: theme.at("sans", default: ("Gill Sans MT", "Fira Sans", "Helvetica Neue")),
       // block + set par, NOT par(..)[..]: wrapping in par() silently DROPS
       // block-level content (headings/lists in note bodies) and triggers
       // "parbreak ignored" warnings on markdown-rendered footnotes
       block({
         set par(leading: theme.at("note-leading", default: 0.5em))
         body
       })))

// Unnumbered floating margin commentary.
#let marginnote(dy: 0pt, theme: (:), body) = marginalia.note(counter: none, dy: dy,
  text(size: theme.at("note-size", default: 9pt),
       font: theme.at("sans", default: ("Gill Sans MT", "Fira Sans", "Helvetica Neue")), body))

// Margin figure with caption.
// Note: body wrapped in parens because Typst 0.15.0 rejects a bare trailing
// `=` at end-of-line with the expression starting on the next line — the
// plan's original one-liner-across-two-lines form is a parse error.
#let notefigure(content, caption: none, dy: 0pt) = (
  marginalia.notefigure(content, caption: caption, dy: dy)
)

// Full citation in the margin, numbered anchor in the text.
// Requires a bibliography somewhere in the document (classes accept `bib:`).
#let sidecite(key, supplement: none, theme: (:)) = sidenote(theme: theme,
  cite(key, form: "full", supplement: supplement))

#let wideblock = marginalia.wideblock

// Class-level footnote→sidenote transform. MUST be installed before any
// marginalia note call fires (spike finding c: `show footnote.entry: none`
// is ordering-sensitive) — classes apply it in their early style chain.
// Never install this locally inside md().
#let footnote-transform(theme, doc) = {
  show footnote: it => sidenote(theme: theme, it.body)
  show footnote.entry: none
  set footnote.entry(separator: none)   // entry show-rule alone leaves the separator line (spike round 2)
  doc
}
```

- [ ] **Step 2: Re-export all six (`sidenote`, `marginnote`, `notefigure`, `sidecite`, `wideblock`, `footnote-transform`) in `src/lib.typ`.**

- [ ] **Step 3: Visual smoke `tests/visual/notes-page.typ`** — marginalia setup from `marginalia-config(resolve-paper("crown-quarto"), media)`, three sidenotes in one paragraph (collision check), a `marginnote`, a `notefigure` with the spike's `img.svg`, a `wideblock`, compiled in BOTH medias:
`typst compile --root . tests/visual/notes-page.typ out/notes-screen.pdf` and with `--input media=print` → `out/notes-print.pdf`.
Eyeball: numbered anchors superscripted; three clustered notes stack without overlap; print verso page puts notes on the outer (left) margin. Stage.

### Task 7: markdown.typ

**Files:** Create `src/markdown.typ`, `tests/visual/markdown-page.typ`, `tests/visual/md/sample.md`, `tests/visual/md/side.md`. Modify `src/lib.typ`.
**Consult FINDINGS.md (b) reader pattern and (c) footnote verdict.**

- [ ] **Step 1: Write `tests/visual/md/sample.md`** — exercises every tier:

```markdown
# Sample Chapter

Lead paragraph with a footnote sidenote.[^fn] Second sentence.

Tag tier: <note>html note</note> and file tier: <note src="side.md"></note>.

Legacy tier: #note[regex note] and #note[side.md] both still work.

> A Tufte-styled quote block, indented and quiet.

![circle](../../spike/img.svg)

Wide: <wide>this block escapes into the margin</wide>

[^fn]: Standard markdown footnote, rendered in the margin.
```

`tests/visual/md/side.md`: `A note that lives in its **own file**.`

**WARNING (verified during implementation):** `<note src="…">` must be EXPLICITLY closed (`</note>`), never self-closed (`<note src="…"/>`). cmarker registers handlers as normal (non-void) tags, so a self-closed form silently swallows everything to end-of-file as its "body." Applies to all example/template content and the README (Task 20).

- [ ] **Step 2: Write `src/markdown.typ`**

```typ
#import "@preview/cmarker:0.1.10" as cmarker
#import "notes.typ": sidenote, marginnote, wideblock
#import "typography.typ": tufte-quote

// Renders CommonMark with the tuftelike scope pre-wired.
// `reader` MUST be created in the USER's file so paths resolve there:
//     #let reader = (p, ..a) => read(p, ..a.named())
// Images load as bytes through it; <note src="…"> reads through it too.
#let md(
  src,                        // markdown string (pass reader("file.md") to read a file)
  reader: none,
  content-root: "",           // prefix applied to relative image/src paths
  theme: (:),
  extensions: (:),            // extra html tag handlers, merged over defaults
  label-prefix: "",
) = {
  // NOTE: footnote→sidenote transform intentionally NOT here — it is
  // ordering-sensitive and lives at class level (notes.typ footnote-transform).
  let path-of(p) = if content-root == "" { p } else { content-root + "/" + p }
  let render-file(p) = md(reader(path-of(p)), reader: reader,
    content-root: content-root, theme: theme, extensions: extensions,
    label-prefix: label-prefix)

  let html-handlers = (
    note: (attrs, body) => if "src" in attrs { sidenote(theme: theme, render-file(attrs.src)) }
      else { sidenote(theme: theme, body) },
    margin: (attrs, body) => marginnote(theme: theme, body),
    wide: (attrs, body) => wideblock(body),
  ) + extensions

  let out = cmarker.render(
    src,
    html: html-handlers,
    heading-labels: "github",
    label-prefix: label-prefix,
    blockquote: body => tufte-quote(theme, body),
    scope: (
      image: (path, alt: none) => image(bytes(reader(path-of(path), encoding: none)), alt: alt),
      sidenote: body => sidenote(theme: theme, body),
      marginnote: body => marginnote(theme: theme, body),
    ),
  )

  // Continuity tier: legacy #note[...] regex + ```note fences, from the prototype era.
  let note-match = regex("#note\\[((?s).*?)\\]")
  show note-match: it => {
    let arg = it.text.matches(note-match).first().captures.at(0)
    if arg.ends-with(".md") { sidenote(theme: theme, render-file(arg)) }
    else { sidenote(theme: theme, cmarker.render(arg)) }
  }
  show raw.where(lang: "note"): it => sidenote(theme: theme, it.text.trim())

  out
}
```

- [ ] **Step 3: Re-export `md` in `src/lib.typ`.**

- [ ] **Step 4: Visual smoke `tests/visual/markdown-page.typ`** — marginalia setup as in Task 6, then:

```typ
#import "@local/tuftelike:0.1.0": md, marginalia-config, resolve-paper, resolve-media
#let reader = (p, ..a) => read(p, ..a.named())
#md(reader("md/sample.md"), reader: reader, content-root: "md")
```
Wait — `image` path in sample.md points outside `md/` (`../../spike/img.svg`); that's intentional: relative traversal must work. Compile both medias into `out/markdown-{screen,print}.pdf`.
Eyeball: ALL FIVE note tiers render in the margin; footnote number matches sidenote number sequence; quote styled; wide block extends. Stage.

- [ ] **Step 5: Phase 1 commit checkpoint**

```bash
git add src/ tests/
```
Append to `commit.txt`:
```

feat(engine): geometry presets, themes, typography, marginalia notes, markdown pipeline

Paper presets as data (crown-quarto, us-trade-6x9, us-letter) with
media-aware marginalia mapping; theme/label resolution chains;
Tufte typography incl. lead smallcaps and quiet quotes; five margin
note forms; cmarker pipeline with three note tiers and
footnote-to-sidenote transform.
```
**CHECKPOINT: Clay reviews `out/*.pdf`, runs `gtxt`.**

---

# Phase 2 — Regions

### Task 8: frontmatter.typ (incl. ISBN block)

**Files:** Create `src/frontmatter.typ`, `tests/assert/isbn.typ`, `tests/visual/frontmatter-pages.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Failing asserts `tests/assert/isbn.typ`**

```typ
#import "@local/tuftelike:0.1.0": isbn-lines
#assert(isbn-lines(none) == ())
#assert(isbn-lines("978-1-0000-0000-1") == ("ISBN 978-1-0000-0000-1",))
#assert(isbn-lines((paperback: "978-1-0000-0000-1", ebook: "978-1-0000-0000-2"))
  == ("ISBN 978-1-0000-0000-1 (paperback)", "ISBN 978-1-0000-0000-2 (ebook)"))
```

- [ ] **Step 2: `just test` → fail. Step 3: Write `src/frontmatter.typ`**

```typ
#import "typography.typ": tufte-quote
#import "utils.typ": plain-text

#let isbn-lines(isbn) = {
  if isbn == none { () }
  else if type(isbn) == str { ("ISBN " + isbn,) }
  else { isbn.pairs().map(((fmt, num)) => "ISBN " + num + " (" + fmt + ")") }
}

// A front-matter page: narrow symmetric margins, no note column, no folio.
#let frontmatter-page(paper, media, body) = {
  page(margin: (left: 25.4mm, right: 25.4mm, top: 25.4mm, bottom: 19.05mm),
       header: none, footer: none, body)
}

#let title-page(theme, title: none, subtitle: none, authors: (), release: none,
                publisher: none) = align(left)[
  #for a in authors [#upper(text(font: theme.sans, tracking: 0.2em, size: 16pt, a)) \ ]
  #v(8em)
  #upper(text(font: theme.sans, tracking: 0.16em, size: 20pt, title))
  #if subtitle != none [ \ #text(font: theme.serif, style: "italic", size: 15pt, subtitle) ]
  #if release != none [ #v(2em) #upper(text(font: theme.sans, tracking: 0.16em, size: 12pt, release)) ]
  #if publisher != none [ #align(bottom + left, upper(text(font: theme.sans, tracking: 0.16em, size: 14pt, publisher.at("name", default: publisher)))) ]
]

#let copyright-page(theme, copyright: (:), publisher: none) = align(bottom + left)[
  #set text(size: 9pt)
  #if "holders" in copyright [Copyright © #copyright.at("year", default: "") #copyright.holders \ ]
  #for line in isbn-lines(copyright.at("isbn", default: none)) [#line \ ]
  #if "release-line" in copyright [#copyright.release-line \ ]
  #if "disclaimer" in copyright [#v(0.5em) #copyright.disclaimer \ ]
  #if "extra" in copyright [#v(0.5em) #copyright.extra \ ]
  #if publisher != none [
    #v(1em)
    #smallcaps(publisher.at("name", default: "")) \
    #publisher.at("address", default: "") \
    #publisher.at("website_url", default: "")
  ]
]

// Polymorphic: string | array | dict(author -> dedication)
#let dedication-page(theme, dedication) = align(center + horizon)[
  #set text(style: "italic")
  #if type(dedication) == str [ #dedication ]
  else if type(dedication) == array [ #dedication.join([#v(1.5em)]) ]
  else [ #dedication.pairs().map(((who, what)) => [#what #v(0.2em) #text(style: "normal", smallcaps(who))]).join(v(2em)) ]
]

// Polymorphic: string | (quote, author) | array | dict(author -> quote)
#let epigraph-page(theme, epigraphs) = align(left + horizon)[
  #let one(q, a) = [#tufte-quote(theme, q, attribution: a) #v(2em)]
  #if type(epigraphs) == str { one(epigraphs, none) }
  else if type(epigraphs) == array and epigraphs.len() == 2 and type(epigraphs.first()) == str {
    one(epigraphs.first(), epigraphs.last())
  } else if type(epigraphs) == array { epigraphs.map(e => one(e, none)).join() }
  else { epigraphs.pairs().map(((a, q)) => one(q, a)).join() }
]

// TOC with data-driven part dividers. parts: ((title: "…", first-chapter: 1), …)
#let toc(theme, labels, parts: ()) = {
  show outline.entry.where(level: 1): it => {
    let divider = context {
      let num = counter(heading).at(it.element.location())
      let hit = parts.find(p => p.first-chapter == num.first())
      if hit != none {
        block(above: 1.3em, text(font: theme.sans, tracking: 0.16em,
          weight: "semibold", size: 10pt, upper(hit.title)))
      }
    }
    divider
    it
  }
  show outline.entry: set text(font: theme.serif, style: "italic")
  outline(title: labels.contents, depth: 2, fill: h(1em))
}
```

- [ ] **Step 4: Re-export (`isbn-lines`, `frontmatter-page`, `title-page`, `copyright-page`, `dedication-page`, `epigraph-page`, `toc`); `just test` → PASS.**

- [ ] **Step 5: Visual smoke `tests/visual/frontmatter-pages.typ`** — render title, copyright (with two-format ISBN dict), dedication (all three shapes), epigraph (dict shape) each on a `frontmatter-page`. Eyeball `out/frontmatter.pdf`: ISBN lines listed on copyright bottom block. Stage.

### Task 9: chapter.typ (openers, icons, part pages)

**Files:** Create `src/chapter.typ`, `tests/visual/chapter-pages.typ`, `examples/_assets/icon-flask.svg`, `examples/_assets/icon-info.svg`. Modify `src/lib.typ`.

- [ ] **Step 1: Create two neutral demo icons** (hand-drawn, NOT copied from any book repo):

`examples/_assets/icon-info.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><circle cx="12" cy="12" r="10" fill="none" stroke="#333" stroke-width="2"/><rect x="11" y="10" width="2" height="7" fill="#333"/><circle cx="12" cy="7" r="1.4" fill="#333"/></svg>
```
`examples/_assets/icon-flask.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path d="M10 3h4v6l5 9a2 2 0 0 1-2 3H7a2 2 0 0 1-2-3l5-9z" fill="none" stroke="#333" stroke-width="2"/></svg>
```

- [ ] **Step 2: Write `src/chapter.typ`**

```typ
// Chapter/Appendix opener + H2/H3 treatments + part divider page.
// icons: dict mapping keyword -> image content, e.g. ("Quick Try": image(...)).
// A level-3 heading whose text starts with (or contains) a key gets its icon.

#let chapter-heading-rules(theme, labels, note-ext, icons: (:), doc) = {
  show heading.where(level: 1): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      let num = counter(heading).display(it.numbering)
      let word = if num.match(regex("^[A-Z]")) != none { labels.appendix } else { labels.chapter }
      text(font: theme.sans, size: 10pt, style: "normal",
        [#smallcaps(word) #num.trim(".")])
      linebreak()
    }
    #text(size: theme.h1-size, style: "italic", it.body)
    #v(2.5em)
  ]
  show heading.where(level: 2): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      text(font: theme.sans, size: 8pt, fill: luma(120),
        counter(heading).display(it.numbering))
      linebreak()
    }
    #it.body
  ]
  show heading.where(level: 3): it => {
    import "utils.typ": plain-text
    let t = plain-text(it.body)
    let hit = icons.pairs().find(((k, _)) => t.starts-with(k) or t.contains(k))
    if hit != none {
      grid(columns: (1.5em, auto), gutter: 0.5em,
        box(height: 1em, hit.last()), it.body)
    } else { it.body }
  }
  doc
}

#let part-divider(theme, labels, number, title) = page(header: none, footer: none)[
  #metadata(none) <divider-page>
  #align(center)[
    #v(6.4em)
    #text(size: 16pt, font: theme.serif, [#labels.part #number])
    #v(0.3em)
    #text(size: 24pt, font: theme.serif, title)
  ]
]
```

- [ ] **Step 3: Re-export; visual smoke `tests/visual/chapter-pages.typ`** with numbered chapter (shows "Chapter 1"), an `#counter(heading).update(0); #set heading(numbering: "A.1")` appendix (shows "Appendix A"), an H3 titled "Quick Try: something" with `icons: ("Quick Try": image("../../examples/_assets/icon-flask.svg"))`, and a part divider. Eyeball `out/chapter.pdf`. Stage.

### Task 10: runners.typ

**Files:** Create `src/runners.typ`, `tests/visual/runners-pages.typ`. Modify `src/lib.typ`.
**Consult FINDINGS.md (e); the code below is the proven `page(foreground:)` port — only switch to `marginalia.header()` if the spike said the foreground box fights the note column.**

- [ ] **Step 1: Write `src/runners.typ`**

```typ
#import "utils.typ": plain-text

// Running heads: verso "N   CHAPTER", recto "SECTION   N". Skipped on pages
// carrying <divider-page> or <no-folio> metadata, before <chapters-begin-here>,
// and on chapter-opener pages (a level-1 heading on the page).
#let folio(theme, alt-runners: (:)) = context {
  let pg = here().page()
  if query(<chapters-begin-here>).len() == 0 { return }
  let begin = query(<chapters-begin-here>).first().location().page()
  if pg < begin { return }
  let markers = query(selector(<divider-page>).or(selector(<no-folio>)))
  if markers.any(m => m.location().page() == pg) { return }
  let h1-here = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
  if h1-here.len() > 0 { return }
  let shorten(t) = alt-runners.at(t, default: t)
  let numtxt = counter(page).display("1")
  let style(body) = text(font: theme.serif, size: theme.folio-size,
    tracking: 0.12em, style: "normal", weight: "regular", body)
  let before(lvl) = {
    let hs = query(heading.where(level: lvl).before(here()))
    if hs.len() == 0 { none } else { upper(shorten(plain-text(hs.last().body))) }
  }
  if calc.even(pg) {
    align(left, style([#numtxt#h(2em)#before(1)]))
  } else {
    let title = if before(2) != none { before(2) } else { before(1) }
    align(right, style([#title#h(2em)#numtxt]))
  }
}
```

- [ ] **Step 2: Re-export `folio`; visual smoke `tests/visual/runners-pages.typ`** — 6 pages: front-matter page (no folio), `#metadata(none) <chapters-begin-here>`, chapter opener (no folio), two body pages (verso shows page+CHAPTER left-aligned, recto shows SECTION+page right-aligned), a part divider page (no folio). Set `alt-runners: ("A Very Long Heading": "SHORT")` on one heading and verify the short form appears. Compile print media. Stage.

### Task 11: mainmatter.typ

**Files:** Create `src/mainmatter.typ`, `tests/visual/mainmatter-doc.typ` + `tests/visual/md/ch1.md`, `ch2.md`, `appx.md`. Modify `src/lib.typ`.

- [ ] **Step 1: Write `src/mainmatter.typ`**

```typ
#import "markdown.typ": md

// Marks the front/main boundary for folio logic; starts heading numbering.
#let begin-chapters(media) = {
  [#metadata(none) <chapters-begin-here>]
  counter(heading).update(0)
  set heading(numbering: "1.1.1")
  counter(page).update(1)
}

#let chapter-break(media, split) = {
  if media == "print" and split == "odd" { pagebreak(to: "odd", weak: true) }
  else { pagebreak(weak: true) }
}

// srcs: array of markdown STRINGS (pass reader("…") results) or, with reader:,
// an array of PATHS. Rendered as ONE cmarker pass so labels/footnotes resolve
// across chapter files; breaks are injected as raw-typst between files.
#let chapters(srcs, reader: none, media: "screen", split: "odd", ..md-args) = {
  let texts = srcs.map(s => if reader != none and s.ends-with(".md") { reader(s) } else { s })
  let break-md = if media == "print" and split == "odd" {
    "\n\n<!--raw-typst #pagebreak(to: \"odd\", weak: true) -->\n\n"
  } else { "\n\n<!--raw-typst #pagebreak(weak: true) -->\n\n" }
  md(texts.join(break-md), reader: reader, ..md-args.named())
}

// Appendix mode: letters, own counter, Appendix label auto-detected by chapter.typ.
#let appendices(srcs, reader: none, media: "screen", ..md-args) = {
  counter(heading).update(0)
  set heading(numbering: "A.1")
  chapters(srcs, reader: reader, media: media, split: "odd", ..md-args.named())
}
```

- [ ] **Step 2: Re-export; write the three tiny md files; visual smoke** compiling two chapters + one appendix with `split: "odd"` in print media. Eyeball `out/mainmatter.pdf`: chapters start recto (blank versos inserted), appendix opener says "Appendix A", heading numbers restart. Stage.

### Task 12: backmatter.typ

**Files:** Create `src/backmatter.typ`. Modify `src/lib.typ`, `tests/visual/mainmatter-doc.typ` (extend).

- [ ] **Step 1: Write `src/backmatter.typ`**

```typ
// About-the-author / colophon pages + bibliography wiring.
#let about-author(theme, body) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #text(font: theme.sans, size: 10pt, tracking: 0.16em, upper("About the Author"))
  #v(1.5em)
  #body
]

#let colophon(theme, body) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #set text(size: 9pt)
  #align(center + bottom, body)
]

// Renders the bibliography; hidden: true resolves citations (sidecite!) without
// printing a references section.
#let references(bib, hidden: false) = {
  if hidden { show bibliography: none; bib } else { bib }
}
```

- [ ] **Step 2: Re-export; extend the Task 11 visual doc** with `about-author` and a `sidecite` + `references(bibliography("refs.bib"), hidden: true)` (create `tests/visual/refs.bib` with one entry: `@book{demo1, title={Demo Title}, author={Anon}, year={2020}}`). Eyeball: full citation appears in margin, no references section printed. `just test` still green. Stage.

- [ ] **Step 3: Phase 2 commit checkpoint** — `git add src/ tests/ examples/_assets/`; append to `commit.txt`:
```

feat(regions): frontmatter with ISBN lines, chapter openers, runners, mainmatter, backmatter

Polymorphic dedication/epigraph pages; data-driven TOC part dividers;
Chapter/Appendix auto-labeling with icon registry; folio skip logic;
chapters() manifest over one cmarker pass; sidecite via hidden bibliography.
```
**CHECKPOINT: Clay reviews, `gtxt`.**

---

# Phase 3 — Classes, examples, cover

### Task 13: classes/book.typ + examples/book

**Files:** Create `src/classes/book.typ`, `examples/book/main.typ`, `examples/book/content/{part1-opening.md,finding-the-thread.md,margins-of-error.md,appendix-tooling.md}` (fresh demo prose — write 3–4 paragraphs each exercising notes/tables/figures; NEVER copy prototype content). Modify `src/lib.typ`.

- [ ] **Step 1: Write `src/classes/book.typ`**

```typ
#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-media, resolve-paper, page-size, marginalia-config
#import "../themes.typ": resolve-theme
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../chapter.typ": chapter-heading-rules, part-divider
#import "../frontmatter.typ": frontmatter-page, title-page, copyright-page, dedication-page, epigraph-page, toc
#import "../runners.typ": folio
#import "../backmatter.typ": references
#import "../notes.typ": footnote-transform

#let book(
  paper: "crown-quarto", media: auto, page-count-range: "151-400",
  title: none, subtitle: none, authors: (), publisher: none, release: none,
  copyright: (:), dedication: none, epigraphs: none,
  front: (:),                  // (introduction: content, preface: content, acknowledgments: content)
  parts: (), alt-runners: (:), icons: (:),
  theme: (:), labels: (:), bib: none, bib-visible: true,
  footnotes-as-sidenotes: true,
  doc,
) = {
  let media = resolve-media(media: media)
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme)
  let labels = resolve-labels(labels)
  let mc = marginalia-config(paper, media, page-count-range: page-count-range)
  let ps = page-size(paper, media)
  let note-ext = paper.note-col + paper.note-gap

  set document(title: if title == none { none } else { title }, author: authors.join(", "))
  show: marginalia.setup.with(..mc)
  set page(width: ps.width, height: ps.height,
    fill: if media == "screen" { theme.screen-bg } else { none },
    header: folio(theme, alt-runners: alt-runners), header-ascent: 30%)
  show: base-style.with(theme, labels, note-ext)
  show: chapter-heading-rules.with(theme, labels, note-ext, icons: icons)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if footnotes-as-sidenotes { footnote-transform(theme, d) } else { d }
  state("tuftelike").update((media: media, paper: paper, theme: theme,
    labels: labels, parts: parts))

  // front matter sequence (print-proven order)
  if epigraphs != none { frontmatter-page(paper, media, epigraph-page(theme, epigraphs)) }
  frontmatter-page(paper, media, title-page(theme, title: title, subtitle: subtitle,
    authors: authors, release: release, publisher: publisher))
  frontmatter-page(paper, media, copyright-page(theme, copyright: copyright, publisher: publisher))
  frontmatter-page(paper, media, toc(theme, labels, parts: parts))
  if dedication != none { frontmatter-page(paper, media, dedication-page(theme, dedication)) }
  for (name, body) in front.pairs() {
    frontmatter-page(paper, media, { heading(numbering: none, level: 1, upper(name.first()) + name.slice(1)); body })
  }

  doc

  if bib != none { references(bib, hidden: not bib-visible) }
}
```

- [ ] **Step 2: Write `examples/book/main.typ`**

```typ
#import "@local/tuftelike:0.1.0": *
#let reader = (p, ..a) => read(p, ..a.named())

#show: book.with(
  paper: "us-trade-6x9",
  title: "Margins of Error",
  subtitle: "A Field Guide to Thinking in the Margins",
  authors: ("A. Demo Author",),
  publisher: (name: "Example Press", website_url: "example.org"),
  release: "First Edition",
  copyright: (year: "2026", holders: "A. Demo Author",
    isbn: (paperback: "978-1-0000-0000-1", ebook: "978-1-0000-0000-2")),
  dedication: "For everyone who reads the footnotes first.",
  epigraphs: ("A Typographer": "The margin is not empty space."),
  parts: ((title: "Part I: Threads", first-chapter: 1),),
  icons: ("Quick Try": image("../_assets/icon-flask.svg")),
)

#begin-chapters(resolve-media())
#part-divider(default-theme, default-labels, "I", "Threads")
#chapters(
  ("content/part1-opening.md", "content/finding-the-thread.md", "content/margins-of-error.md"),
  reader: reader, media: resolve-media(), content-root: "content")
#appendices(("content/appendix-tooling.md",), reader: reader,
  media: resolve-media(), content-root: "content")
```
Paths are relative to the example dir (the `reader` closure was defined there, so `read` resolves there); `content-root` covers images and `<note src=…>` side-files inside the markdown.

- [ ] **Step 3: Compile both medias**

Run: `just demo book screen && just demo book print`
Expected: `out/book-screen.pdf` (cream bg, notes right) and `out/book-print.pdf` (bleed-sized pages, mirrored notes, recto chapters, ISBN lines on copyright page, part divider in TOC and as page).

- [ ] **Step 4: Fix-forward eyeball list** — TOC divider "PART I: THREADS" above chapter 1 entry; folios correct/skipped; footnote-tier sidenote numbered; 6×9 body ≈ 84mm wide. Adjust `us-trade-6x9` note-col in `geometry.typ` ONLY if notes are unreadable (<24mm). Stage.

### Task 14: classes/letter.typ + examples/letter

**Files:** Create `src/classes/letter.typ`, `examples/letter/main.typ`, `examples/letter/body.md`. Modify `src/lib.typ`.

- [ ] **Step 1: Write `src/classes/letter.typ`**

```typ
#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-media, resolve-paper
#import "../themes.typ": resolve-theme
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../notes.typ": footnote-transform

#let letter(
  paper: "us-letter", media: auto,
  from: (:),                 // (name:, title:, org:, address:, email:) or content
  to: none, date: auto, re: none, salutation: none,
  closing: "Sincerely,", signature: none,   // content|image|str
  enclosures: (), cc: (),
  numbered-sections: false,
  theme: (:), labels: (:),
  footnotes-as-sidenotes: true,
  doc,
) = {
  let media = resolve-media(media: media)
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme)
  let labels = resolve-labels(labels)
  let m = paper.letter-margin
  // note column occupies the wide right margin; letters are one-sided
  show: marginalia.setup.with(
    inner: (far: m.left, width: 0mm, sep: 0mm),
    outer: (far: m.right - paper.note-col - paper.note-gap, width: paper.note-col, sep: paper.note-gap),
    top: m.top, bottom: m.bottom, book: false)
  set page(width: paper.trim.w, height: paper.trim.h,
    fill: if media == "screen" { theme.screen-bg } else { none },
    header: context if counter(page).get().first() > 1 {
      text(font: theme.serif, size: theme.folio-size, tracking: 0.12em,
        [#smallcaps(if re != none { re } else { "" }) #h(1fr) #counter(page).display("1")])
    })
  show: base-style.with(theme, labels, paper.note-col + paper.note-gap)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if footnotes-as-sidenotes { footnote-transform(theme, d) } else { d }
  if numbered-sections { set heading(numbering: "1.1.A.") }

  // letterhead
  if type(from) == dictionary {
    text(font: theme.sans, size: 9pt)[
      #smallcaps(from.at("name", default: "")) \
      #from.at("title", default: none) #if "title" in from [\ ]
      #from.at("org", default: none) #if "org" in from [\ ]
      #from.at("address", default: none) #if "address" in from [\ ]
      #from.at("email", default: none)
    ]
  } else { from }
  v(2em)
  if date == auto { datetime.today().display("[month repr:long] [day], [year]") } else { date }
  v(1.5em)
  if to != none { to; v(1.5em) }
  if re != none { text(weight: "semibold", [Re: #re]); v(1em) }
  if salutation != none { salutation; v(0.8em) }

  doc

  v(2em)
  closing
  if signature != none { v(0.4em); signature } 
  if enclosures.len() > 0 { v(1.5em); text(size: 9pt, [#labels.enclosures: #enclosures.join(", ")]) }
  if cc.len() > 0 { v(0.3em); text(size: 9pt, [#labels.cc: #cc.join(", ")]) }
}
```

- [ ] **Step 2: `examples/letter/main.typ`** — from-dict letterhead, `date: auto`, a `body.md` with one `[^1]` footnote and one `<note>` (both must land in the right margin), closing + name signature, one enclosure. Compile both medias: `just demo letter screen`, `just demo letter print`. Eyeball: page 1 no header; add a `#pagebreak()` in body to check the page-2 running header. Stage.

### Task 15: classes/handout.typ + examples/handout

**Files:** Create `src/classes/handout.typ`, `examples/handout/main.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Write `src/classes/handout.typ`** — same skeleton as letter (setup from `handout-margin`), but: title block (title 2.3em serif, subtitle italic, authors grid with role/affiliation/email in sans 9pt), optional `abstract` in italic block, `document-number` + `distribution` line under authors, `footer-content: (first, rest)` rendered via `set page(footer: context …)` choosing by page number, optional `toc: false`, `bib:` rendered at end. Full code mirrors letter.typ patterns above — reuse `base-style`, marginalia setup verbatim except margins key.

- [ ] **Step 2: `examples/handout/main.typ`** — two authors, abstract, document-number "TN-001", distribution line, sidenote + notecite-style `sidecite` with tiny refs.bib. Compile both medias, eyeball, stage.

### Task 16: cover.typ + examples/cover

**Files:** Create `src/cover.typ`, `tests/assert/cover.typ`, `examples/cover/main.typ`. Modify `src/lib.typ`.

- [ ] **Step 1: Failing asserts `tests/assert/cover.typ`**

```typ
#import "@local/tuftelike:0.1.0": spine-width, cover-size, resolve-paper
#assert(spine-width(228, "lulu-standard-bw") == 228 * 0.0572mm)
#let cs = cover-size(resolve-paper("crown-quarto"), 228, "lulu-standard-bw")
#assert(cs.width == 2 * 189mm + 228 * 0.0572mm + 2 * 3.18mm)
#assert(cs.height == 246mm + 2 * 3.18mm)
```

- [ ] **Step 2: `just test` → fail. Step 3: Write `src/cover.typ`**

```typ
#import "@preview/tiaoma:0.3.0"
#import "geometry.typ": resolve-paper
#import "themes.typ": resolve-theme
#import "labels.typ": resolve-labels

// mm of spine per page. lulu-standard-bw back-derived from the prototype
// cover (13.03mm at ~228pp). Re-check printer docs when stakes are real:
// Lulu book-creation-guide + KDP paperback submission specs.
#let stocks = (
  "lulu-standard-bw": 0.0572mm,
  "kdp-white": 0.0572mm,     // 0.002252in/page
  "kdp-cream": 0.0635mm,     // 0.0025in/page
)
#let spine-width(page-count, stock) = page-count * stocks.at(stock)
#let cover-size(paper, page-count, stock) = (
  width: 2 * paper.trim.w + spine-width(page-count, stock) + 2 * paper.bleed,
  height: paper.trim.h + 2 * paper.bleed,
)

#let barcode-zone(theme, labels, barcode) = {
  let zone(body) = rect(width: 50.8mm, height: 30.5mm, fill: white, inset: 3mm,
    align(center + horizon, body))
  if barcode == none { none }
  else if type(barcode) == dictionary and barcode.at("review-copy", default: false) {
    zone(text(font: theme.sans, size: 9pt, weight: "semibold", labels.review-copy))
  } else if type(barcode) == dictionary and "isbn" in barcode {
    let digits = barcode.isbn.replace("-", "")
    zone[
      #text(font: theme.mono, size: 7pt, "ISBN " + barcode.isbn)
      #v(1mm)
      #tiaoma.ean(digits, options: (height: 18.0))  // if 0.3.0 names differ, see pkg manual in typst cache
    ]
  } else { zone(barcode) } // pre-made image
}

#let cover(
  paper: "crown-quarto", page-count: 200, stock: "lulu-standard-bw",
  background: none,
  front: (:), spine: (:), back: (:),
  barcode: none, theme: (:), labels: (:),
) = {
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme)
  let labels = resolve-labels(labels)
  let sw = spine-width(page-count, stock)
  let cs = cover-size(paper, page-count, stock)
  set page(width: cs.width, height: cs.height, margin: 0mm,
    background: if background != none { image-fill(background, cs) } else { none })
  set text(fill: white, font: theme.sans)
  grid(columns: (paper.trim.w + paper.bleed, sw, paper.trim.w + paper.bleed), rows: 100%,
    // BACK (left panel)
    block(width: 100%, height: 100%, inset: (x: paper.bleed + paper.safety + 6mm, y: paper.bleed + paper.safety + 6mm))[
      #if "overlay" in back { place(top + left, dx: -paper.safety - 6mm, dy: -paper.safety - 6mm,
        rect(width: 100% + 2 * (paper.safety + 6mm), height: 100% + 2 * (paper.safety + 6mm), fill: back.overlay)) }
      #back.at("blurb", default: none)
      #place(bottom + right, barcode-zone(theme, labels, barcode))
    ],
    // SPINE — auto-hidden under 80 pages (printer minimums)
    if page-count >= 80 {
      rotate(90deg, box(width: cs.height)[
        #align(horizon, text(size: 11pt, tracking: 0.14em,
          [#spine.at("author", default: none) #h(1fr) #upper(spine.at("title", default: ""))]))
      ])
    },
    // FRONT (right panel)
    block(width: 100%, height: 100%, inset: paper.bleed + paper.safety + 6mm)[
      #upper(text(size: 14pt, tracking: 0.2em, front.at("author", default: "")))
      #v(1fr)
      #upper(text(size: 26pt, tracking: 0.12em, front.at("title", default: "")))
      #if "subtitle" in front [ #v(0.5em) #text(size: 14pt, style: "italic", font: theme.serif, front.subtitle) ]
      #v(1fr)
      #if "release" in front [ #upper(text(size: 10pt, tracking: 0.16em, front.release)) ]
    ])
}

// stretch an image to fully bleed the cover canvas
#let image-fill(img, cs) = block(width: cs.width, height: cs.height, clip: true,
  align(center + horizon, box(width: cs.width, height: cs.height, img)))
```
Note: `image-fill` must be defined ABOVE `cover` in the file (Typst is order-sensitive) — place it accordingly.

- [ ] **Step 4: Re-export `spine-width`, `cover-size`, `cover`; `just test` → asserts PASS.**

- [ ] **Step 5: `examples/cover/main.typ`** — solid-color background (`rect` fill, no photo needed), front/spine/back text, `barcode: (isbn: "978-1-0000-0000-1")`, `page-count: 228`. Add justfile recipe:
```just
cover: install
    mkdir -p out
    {{typst}} compile --root . --font-path fonts examples/cover/main.typ out/cover.pdf
```
Run `just cover`. Eyeball: three panels, spine text reads bottom-to-top when tilted right, EAN-13 renders in white zone bottom-right of back panel. If `tiaoma.ean` errors, check `~/Library/Caches/typst/packages/preview/tiaoma/0.3.0/` manual for the EAN function name and fix. Stage.

- [ ] **Step 6: Phase 3 commit checkpoint** — `git add src/ examples/ tests/ justfile`; append to `commit.txt`:
```

feat(classes): book, letter, handout classes + wrap cover with spine calc and ISBN barcode

Book assembles print-proven front-matter sequence with data-driven
parts; letter gains real correspondence structure with live margin
notes; handout ports the memo lineage; cover computes spine width
from page count and stock, renders EAN-13 from ISBN via tiaoma.
```
**CHECKPOINT: Clay reviews all example PDFs, `gtxt`.**

---

# Phase 4 — Tooling, template, docs, parity

### Task 17: extras/instructional.typ

**Files:** Create `src/extras/instructional.typ`, extend `examples/book/content/margins-of-error.md` with `<prompt>`/`<response>` usage.

- [ ] **Step 1: Write `src/extras/instructional.typ`**

```typ
// Optional extension set for instructional books: prompt/response dialogue
// tags + an H3 icon keyword map. Import and pass into class/md() calls:
//   #import "@local/tuftelike:0.1.0/src/extras/instructional.typ": instructional-extensions, instructional-icons
#let instructional-extensions(theme) = (
  prompt: (attrs, body) => block(inset: (left: 1em))[
    #text(font: theme.at("mono", default: ("Consolas", "Menlo")), weight: "bold", size: 10pt, body)],
  response: (attrs, body) => block(inset: (left: 1em, right: 1em))[
    #text(font: theme.at("serif", default: ("ETbb", "Palatino")), body)],
)
// keyword -> icon path map; users supply their own SVGs
#let instructional-icons(assets: "") = (
  "Quick Try": image(assets + "/icon-flask.svg"),
  "Checkpoint": image(assets + "/icon-info.svg"),
)
```
(Import path caveat: cross-file package imports use the package-relative form `#import "@local/tuftelike:0.1.0": …` re-exports — add `instructional-extensions`/`instructional-icons` to `src/lib.typ` re-exports instead of deep-importing; images resolve in the USER's tree via the `assets` prefix, so no icons ship in the package.)

- [ ] **Step 2: Wire into the book example** (`extensions: instructional-extensions(default-theme)` forwarded through `chapters(…)`; add a `<prompt>`/`<response>` exchange to one chapter md). Recompile `just demo book screen`, eyeball, stage.

### Task 18: bin/table-to-typst + template/ scaffold

**Files:** Create `bin/table-to-typst` (copied), `template/main.typ`, `template/content/chapter-one.md`.

- [ ] **Step 1: Port the script** — `cp "$PROTO_BOOK_DIR/bin/table-to-typst" bin/ && chmod +x bin/table-to-typst`. If `PROTO_BOOK_DIR` is unset, STOP and ask Clay rather than reconstructing it. Open the copied file and verify it contains no book-specific strings (title/author/org names); scrub any comment lines that do.

- [ ] **Step 2: `template/main.typ`** — the `typst init` starting point: minimal `book.with` (title "My Book", one chapter, `paper: "us-trade-6x9"`) + `template/content/chapter-one.md` with one footnote and one `<note>`. Compile it manually: `typst compile --root . --font-path fonts --input media=screen template/main.typ out/template.pdf`. Stage both.

### Task 19: compile matrix + justfile completion

**Files:** Create `tests/compile-matrix.sh`. Modify `justfile`.

- [ ] **Step 1: Write `tests/compile-matrix.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out
fail=0
for target in book letter handout; do
  for media in screen print; do
    echo "== $target/$media"
    typst compile --root . --font-path fonts --input media="$media" \
      "examples/$target/main.typ" "out/matrix-$target-$media.pdf" || fail=1
  done
done
typst compile --root . --font-path fonts examples/cover/main.typ out/matrix-cover.pdf || fail=1
typst compile --root . --font-path fonts --input media=screen template/main.typ out/matrix-template.pdf || fail=1
exit "$fail"
```
`chmod +x tests/compile-matrix.sh`

- [ ] **Step 2: Finish `justfile`** — add:

```just
# parity build against the prototype book (local only; needs PROTO_BOOK_DIR)
proto-check: install
    [ -n "${PROTO_BOOK_DIR:-}" ] || { echo "PROTO_BOOK_DIR not set (see .envrc.local)" >&2; exit 1; }
    mkdir -p tests/fixtures/proto out
    ln -sfn "$PROTO_BOOK_DIR/content" tests/fixtures/proto/content
    typst compile --root . --font-path fonts --input media=print tests/fixtures/proto/main.typ out/proto-print.pdf

fonts-check:
    typst fonts --font-path fonts | grep -iE 'ETbb|Gill Sans|Consolas' || echo "expected fonts missing — see fonts/README notes in main README"
```

- [ ] **Step 3: Run `just test`** — Expected output ends with all matrix lines and exit 0. Stage.

### Task 20: README

**Files:** Create `README.md`.

- [ ] **Step 1: Write README** with: one-paragraph pitch; install (`just install`, `--font-path fonts`, where to get ETbb/Gill Sans/Consolas — name the fonts, never any book); an Environment note (the justfile shields typst invocations with `env -u TYPST_PACKAGE_PATH`; CI or direnv-less shells otherwise hit `package not found` if a global TYPST_PACKAGE_PATH is set — use `direnv exec .` or replicate `.envrc`); a WARNING in the note-tiers section that `<note src="…">` requires explicit close (`</note>`, never self-closing — silently swallows the rest of the file); 10-line quickstart for each class (copy the working example headers); the three markdown note tiers with one-line samples; paper preset table (dims + note-col + tuning note for 6×9); media flag (`--input media=print`); cover build incl. ISBN barcode forms; extension registry how-to; cookbook stubs (6×9 print checklist: page-count-range, spine stock, ISBN placement); credits to marginalia/cmarker/tiaoma. Verify every command in the README by running it.

- [ ] **Step 2: Stage.**

### Task 21: Prototype parity fixture (LOCAL ONLY — nothing sensitive committed)

**Files:** Create `tests/fixtures/proto/main.typ` locally (gitignored dir; verify with `git check-ignore tests/fixtures/proto/`).

- [ ] **Step 1: Write a parity `main.typ` inside the gitignored dir** — a `book.with(paper: "crown-quarto", …)` document that reads 3–4 real chapters through `chapters(reader: …)` from the symlinked `content/`, sets `parts:` and `icons:` equivalents, uses the continuity tier only (that's what the prototype content uses). Placeholder-free metadata is fine here (it's untracked) but keep names out anyway from habit.

- [ ] **Step 2: `just proto-check`** — Expected: compiles; eyeball against the prototype's PDF for: sidenote placement quality (should be BETTER — no manual dy), chapter openers, icon H3s, margin tables, TOC dividers, heading labels resolving WITHOUT `link_id` hacks (search the log for label errors — the ampersand-heading chapters are the test).

- [ ] **Step 3: Record outcomes in `tests/spike/FINDINGS.md`** (append a "Parity" section: what matched, what drifted acceptably, any template fixes made). Commit only FINDINGS.md changes + template fixes.

- [ ] **Step 4: Final commit checkpoint** — `git add -A` (gitignore guards the private bits — verify with `git status` that no `fixtures/proto` content or `fonts/` files appear); append to `commit.txt`:
```

feat(tooling): compile matrix, proto-check harness, typst-init template, README

docs: quickstart, note tiers, paper presets, cover cookbook
```
**CHECKPOINT: Clay reviews, `gtxt`. v0.1.0 complete.**

---

## Self-review (done during planning)

- **Spec coverage:** geometry presets ✔ (T3) · themes/labels ✔ (T4) · typography ✔ (T5) · notes ✔ (T6) · markdown tiers + footnote transform ✔ (T2/T7) · frontmatter + ISBN ✔ (T8) · chapter/icons/parts ✔ (T9) · runners ✔ (T10) · mainmatter/appendix ✔ (T11) · backmatter/sidecite ✔ (T12) · book/letter/handout ✔ (T13–15) · cover/spine/barcode ✔ (T16) · extras ✔ (T17) · bin + template ✔ (T18) · matrix/justfile/env ✔ (T1/T19) · README ✔ (T20) · parity ✔ (T21).
- **Spike-gated items** are marked with explicit FINDINGS.md consults (T6, T7, T10) and carry coded defaults.
- **Naming rule** enforced at T18 (scrub step) and T21 (gitignore verification step).
