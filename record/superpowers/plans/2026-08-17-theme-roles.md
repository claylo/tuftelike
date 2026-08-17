# Theme Roles + Ambient Theme + Dependency Recipes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every typographic knob in tuftelike lives in `default-theme` as a named role; content helpers read the theme ambiently from `state("tuftelike")`; `just outdated` / `just update` manage Typst package pins.

**Architecture:** `themes.typ` gains a nested `fonts` + role schema with a deep merge and three primitives (`role-args`, `styled`, `current-theme`/`current-labels`). Every `src/` module is then converted mechanically: class-level `set`/`show` rules spread `role-args`, direct renders call `styled`, and every helper that used to take a positional `theme` takes `theme: auto` and reads state inside `context`. A lint script keeps hardcoded typography out of `src/` forever. A bash script + two just recipes handle package pins.

**Tech Stack:** Typst 0.15 (package under `@local/tuftelike:0.1.0`), bash, `mutool` (parity checks), `curl`+`jq` (Universe index).

**Spec:** `record/superpowers/specs/2026-08-17-theme-roles-design.md`

## Global Constraints

- Defaults must render the SAME Tufte look as before (compare `out/baseline-*.pdf` built in Task 0). Only `justify` changes intentionally (already `false` in the working tree).
- No numeric literal size/spacing, font stack, `weight:`, `tracking:`, `luma(`/`rgb(` in `src/` outside `src/themes.typ` after Task 9 (`tests/lint-hardcoded.sh` enforces).
- Clean break: no compat shim for old flat keys (`h1-size`, `serif`, …). Old positional-theme signatures are removed, not deprecated.
- Never name the prototype book/author in any artifact (memory: prototype-book-naming).
- Do NOT edit version numbers in `typst.toml`.
- Test command: `just test`. Compile a single fixture: `env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts <file> out/x.pdf`.
- Commits: Clay commits himself via `commit.txt` + `gtxt`. Each task ends by writing/overwriting `commit.txt` (conventional commit body) instead of running `git commit`. Do NOT run `git commit`.
- Typst gotchas that bite this work (from memory): `set`/`show` inside `if {}` don't escape the block; markup-mode multi-line `else` chains break silently — wrap in `#{ }`; imports are file-scoped; `text(fill: auto)` is INVALID — `role-args` must drop `auto` keys.

---

### Task 0: Baseline snapshots

**Files:**
- Create: `out/baseline-toc.pdf`, `out/baseline-book-print.pdf`, `out/baseline-book-screen.pdf`, `out/baseline-toc.txt` (git-ignored `out/`)

- [ ] **Step 1: Build baselines from the current tree**

```bash
just install
env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts tests/visual/toc-page.typ out/baseline-toc.pdf
env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts --input media=print examples/book/main.typ out/baseline-book-print.pdf
env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts --input media=screen examples/book/main.typ out/baseline-book-screen.pdf
mutool draw -F stext -o - out/baseline-toc.pdf 1 2>/dev/null | grep -oE '<line bbox="[^"]*"[^>]*text="[^"]*"' > out/baseline-toc.txt
wc -l out/baseline-toc.txt   # expect > 20 lines
```

- [ ] **Step 2: Record the font inventory of the baseline book**

```bash
pdffonts out/baseline-book-print.pdf | awk 'NR>2{print $1}' | sed 's/^[A-Z]*+//' | sort -u > out/baseline-book-fonts.txt
cat out/baseline-book-fonts.txt   # expect ETbb*, GillSansMT*, Consolas* only (plus maybe a math/fallback)
```

No commit for this task (all under `out/`).

---

### Task 1: Theme schema, deep merge, role primitives

**Files:**
- Modify: `src/themes.typ` (rewrite)
- Modify: `src/lib.typ:6` (export new symbols)
- Test: `tests/assert/theme.typ` (rewrite)

**Interfaces:**
- Produces: `default-theme` (nested), `theme-presets`, `deep-merge(a, b)`, `resolve-theme(user, presets:, preset:)`, `role(theme, path)`, `role-args(theme, path)`, `styled(theme, path, body)`, `current-theme()`, `current-labels()`, `text-keys` (the six role text keys).
- Role path strings use dots for nesting: `"heading.h1"`, `"toc.group"`, `"title-page.author"`.
- `role-args` returns ONLY keys whose value is not `auto` (so `set text(..role-args(...))` inherits for `auto`).

- [ ] **Step 1: Write the failing test** — replace `tests/assert/theme.typ` with:

```typ
#import "@local/tuftelike:0.1.0": default-labels, resolve-labels, default-theme, resolve-theme, deep-merge, role, role-args, styled, text-keys, theme-presets
#assert(default-labels.chapter == "Chapter")
#assert(resolve-labels((chapter: "Kapitel")).chapter == "Kapitel")
#assert(resolve-labels((chapter: "Kapitel")).appendix == "Appendix")

// schema shape
#assert(default-theme.fonts.serif.first() == "ETbb")
#assert(default-theme.body.size == 11pt)
#assert(default-theme.heading.h1.size == 20pt)
#assert(default-theme.justify == false)
#assert(default-theme.toc-pagenums == "ragged")
#assert(default-theme.draft == false)

// every role carries the six text keys (values may be auto)
#let is-role(d) = type(d) == dictionary and "font" in d
#let check(d, path) = {
  if is-role(d) {
    for k in text-keys { assert(k in d, message: path + " missing " + k) }
  } else if type(d) == dictionary {
    for (k, v) in d { check(v, path + "." + k) }
  }
}
#check(default-theme, "theme")
#assert(is-role(default-theme.note))
#assert(is-role(default-theme.toc.group))
#assert(is-role(default-theme.cover.title))

// deep merge: partial nested overlay, arrays replace wholesale
#let t = resolve-theme((heading: (h2: (weight: "bold")), fonts: (serif: ("Override",))))
#assert(t.heading.h2.weight == "bold")
#assert(t.heading.h2.size == 18pt)          // sibling key preserved
#assert(t.heading.h1.size == 20pt)          // sibling role preserved
#assert(t.fonts.serif == ("Override",))     // arrays replace
#assert(t.fonts.sans.first() == "Gill Sans MT")
#assert(deep-merge((a: (b: 1, c: 2)), (a: (b: 9))) == (a: (b: 9, c: 2)))

// role access + alias resolution
#assert(role(default-theme, "heading.h1").style == "italic")
#let ra = role-args(t, "body")
#assert(ra.font == ("Override",))           // alias "serif" resolved through overridden fonts
#assert(ra.size == 11pt)
#assert(role-args(default-theme, "note").font.first() == "Gill Sans MT")
#assert("fill" not in role-args(default-theme, "note"))   // auto keys dropped
#assert(role-args(resolve-theme((note: (font: ("Zzz",)))), "note").font == ("Zzz",))  // explicit stack passes through
#assert(styled(default-theme, "body", [x]) != none)

// preset chain: user > preset > defaults (unchanged semantics, nested keys)
#let variants = ("trade": (body: (size: 10pt), toc-pagenums: "flush"))
#let t5 = resolve-theme((note: (size: 8pt)), presets: variants, preset: "trade")
#assert(t5.body.size == 10pt)
#assert(t5.toc-pagenums == "flush")
#assert(t5.note.size == 8pt)
#assert(t5.fonts.serif.first() == "ETbb")
#assert(resolve-theme((body: (size: 12pt)), presets: variants, preset: "trade").body.size == 12pt)
#assert(resolve-theme((:), presets: variants).body.size == 11pt)
#assert(resolve-theme((:), preset: "beautiful-evidence").body.size == 11pt)
#assert("beautiful-evidence" in theme-presets)
```

- [ ] **Step 2: Run to verify it fails**

`just install && env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts tests/assert/theme.typ out/x.pdf` → expect error `unresolved import` (deep-merge etc. don't exist).

- [ ] **Step 3: Rewrite `src/themes.typ`**

```typ
// Theme = fonts + roles. Every text site in the package is a named role
// with the same six text keys (text-keys); `auto` on any key means
// "inherit from the surrounding text". Roles that own vertical rhythm add
// above/below (auto = Typst default) or named gap keys; roles that
// transform case add case: "upper" | "smallcaps" | none.
//
// Resolution chain: explicit theme: dict > selected preset overlay > these
// defaults, DEEP-merged (dicts merge at every level, arrays — font stacks —
// replace wholesale). Preset SELECTION: preset: arg > --input theme=<name>
// > none (same pattern as media).
//
// Defaults ARE the print-proven Tufte look; change values here only with
// a parity check against the baseline renders.
#let text-keys = ("font", "size", "weight", "style", "tracking", "fill")

// helper for terse role literals — every role gets the six keys
#let r(font: auto, size: auto, weight: auto, style: auto, tracking: auto, fill: auto, ..extra) = (
  font: font, size: size, weight: weight, style: style, tracking: tracking, fill: fill,
) + extra.named()

#let default-theme = (
  fonts: (
    serif: ("ETbb", "ETBembo", "Palatino", "Georgia"),
    sans: ("Gill Sans MT", "Fira Sans", "Helvetica Neue", "Arial"),
    mono: ("Consolas", "Menlo", "Monaco"),
  ),
  justify: false,
  screen-bg: rgb("FFFFF8"),
  toc-pagenums: "ragged",   // "ragged" | "flush" — see frontmatter.typ toc()
  draft: false,

  // ── base text ──
  body: r(font: "serif", size: 11pt, weight: "regular", style: "normal", tracking: 0em,
    fill: luma(30), leading: 0.8em, spacing: 1.4em),
  note: r(font: "sans", size: 9pt, leading: 0.5em),
  folio: r(font: "serif", size: 8pt, weight: "regular", style: "normal", tracking: 0.12em),
  raw: r(font: "mono", size: 0.8em),
  list: (spacing: 1.2em, body-indent: 1em),
  heading: (
    h1: r(font: "serif", size: 20pt, weight: "regular", style: "italic", above: auto, below: auto),
    h2: r(font: "serif", size: 18pt, weight: "regular", style: "italic", above: auto, below: auto),
    h3: r(font: "serif", size: 16pt, weight: "regular", style: "italic", above: auto, below: auto),
    h4: r(font: "serif", size: 14pt, weight: "regular", style: "italic", above: auto, below: auto),
    h5: r(font: "serif", size: 12pt, weight: "regular", style: "italic", above: auto, below: auto),
  ),
  // ── chapter openers / part dividers (chapter.typ) ──
  chapter-label: r(font: "sans", size: 10pt, style: "normal", case: "smallcaps"),
  section-number: r(font: "sans", size: 8pt, fill: luma(120)),
  opener: (drop: 2.5em),
  part-label: r(font: "serif", size: 16pt),
  part-title: r(font: "serif", size: 24pt),
  part-divider: (top: 6.4em, gap: 0.3em),
  // ── figures / tables (typography.typ) ──
  caption: r(font: "sans", size: 9pt, below: 0.5em),
  table-head: r(size: 10pt, weight: "regular"),
  table-body: r(size: 9pt, weight: "regular"),
  table-rule: (top: 1pt, bottom: 0.3pt, hline: 0.7pt),
  // ── notes / quotes / lead-ins ──
  newthought: r(font: "serif", tracking: 0.05em, case: "smallcaps", above: 1em),
  quote: (inset-left: 1.5em, inset-right: 1em, attrib-gap: 0.3em),
  epigraph-attrib: r(style: "italic"),
  // ── front matter (frontmatter.typ) ──
  title-page: (
    author: r(font: "sans", size: 16pt, tracking: 0.2em, case: "upper"),
    title: r(font: "sans", size: 20pt, tracking: 0.16em, case: "upper"),
    subtitle: r(font: "serif", size: 15pt, style: "italic"),
    release: r(font: "sans", size: 12pt, tracking: 0.16em, case: "upper"),
    publisher: r(font: "sans", size: 14pt, tracking: 0.16em, case: "upper"),
    gap-author-title: 8em, gap-release: 2em,
  ),
  copyright: r(size: 9pt),
  dedication: r(style: "italic"),
  toc: (
    title: r(size: 20pt, style: "italic"),
    group: r(font: "serif", weight: "semibold", tracking: 0.16em, case: "upper", above: 1.3em),
    l1: r(font: "serif", size: 11pt, style: "italic", above: 1.1em),
    l2: r(font: "serif", size: 10pt, style: "normal"),
    prefix: r(font: "serif", style: "normal"),
    unnumbered: r(font: "serif", style: "italic"),
    title-gap: 2.1em, indent: 2em, entry-gap: 1.5em, backmatter-gap: 1.2em, folio-gap: 8,
  ),
  // ── back matter (backmatter.typ) ──
  backmatter-label: r(font: "sans", size: 10pt, tracking: 0.16em, case: "upper", below: 1.5em),
  colophon: r(size: 9pt),
  index: r(size: 9pt),
  // ── cover (cover.typ) ──
  cover: (
    base: r(font: "sans", fill: white),
    author: r(size: 14pt, tracking: 0.2em, case: "upper"),
    title: r(size: 26pt, tracking: 0.12em, case: "upper"),
    subtitle: r(font: "serif", size: 14pt, style: "italic"),
    release: r(size: 10pt, tracking: 0.16em, case: "upper"),
    spine: r(size: 11pt, tracking: 0.14em),
    isbn: r(font: "mono", size: 7pt, fill: black),
    stamp: r(font: "sans", size: 9pt, weight: "semibold", fill: black),
    subtitle-gap: 0.5em,
  ),
  // ── letter (classes/letter.typ) ──
  letter: (
    letterhead: r(font: "sans", size: 9pt),
    runner: r(font: "serif", size: 8pt, tracking: 0.12em),
    re: r(weight: "semibold"),
    meta: r(size: 9pt),
    after-letterhead: 2em, after-date: 1.5em, after-to: 1.5em, after-re: 1em,
    after-salutation: 0.8em, before-closing: 2em, before-signature: 0.4em,
    before-enclosures: 1.5em, before-cc: 0.3em,
  ),
  // ── handout (classes/handout.typ) ──
  handout: (
    title: r(font: "serif", size: 2.3em, weight: "regular"),
    subtitle: r(font: "serif", size: 1.3em, style: "italic"),
    author: r(font: "sans", size: 9pt),
    author-name: r(weight: "semibold"),
    meta: r(font: "sans", size: 8pt, fill: luma(100)),
    abstract: r(style: "italic"),
    footer: r(font: "sans", size: 8pt),
    after-title: 1em, author-gutter: 1.5em, after-authors: 0.6em, after-meta: 1.2em,
    abstract-inset: 2em, after-abstract: 1.5em,
  ),
  // ── extras / draft ──
  prompt: r(font: "mono", size: 10pt, weight: "bold"),
  response: r(font: "serif"),
  watermark: r(font: "sans", size: 96pt, fill: luma(85)),
)

// Named preset overlays, applied between default-theme and the user dict.
// The defaults ARE beautiful-evidence, so its overlay is empty.
#let theme-presets = ("beautiful-evidence": (:))

// dicts merge at every depth; anything else (arrays, scalars) replaces
#let deep-merge(a, b) = {
  let out = a
  for (k, v) in b {
    if k in out and type(out.at(k)) == dictionary and type(v) == dictionary {
      out.insert(k, deep-merge(out.at(k), v))
    } else { out.insert(k, v) }
  }
  out
}

#let resolve-theme(user, presets: (:), preset: auto) = {
  let all = theme-presets + presets
  let name = if preset == auto { sys.inputs.at("theme", default: none) } else { preset }
  let overlay = if name == none { (:) } else {
    assert(name in all, message: "unknown theme \"" + name
      + "\" — available: " + all.keys().join(", "))
    all.at(name)
  }
  deep-merge(deep-merge(default-theme, overlay), user)
}

// role(theme, "heading.h1") walks a dotted path
#let role(theme, path) = {
  let cur = theme
  for k in path.split(".") {
    assert(type(cur) == dictionary and k in cur,
      message: "theme role \"" + path + "\" not found (at \"" + k + "\")")
    cur = cur.at(k)
  }
  cur
}

#let resolve-font(theme, f) = if type(f) == str {
  assert(f in theme.fonts, message: "unknown font alias \"" + f
    + "\" — theme.fonts has: " + theme.fonts.keys().join(", "))
  theme.fonts.at(f)
} else { f }

// text() named args for a role: alias resolved, auto keys DROPPED (so a
// set text(..role-args(..)) inherits whatever the role leaves auto)
#let role-args(theme, path) = {
  let rl = role(theme, path)
  let out = (:)
  for k in text-keys {
    let v = rl.at(k)
    if v != auto { out.insert(k, if k == "font" { resolve-font(theme, v) } else { v }) }
  }
  out
}

#let cased(rl, body) = {
  let c = rl.at("case", default: none)
  if c == "upper" { upper(body) } else if c == "smallcaps" { smallcaps(body) } else { body }
}

// direct render of body in a role
#let styled(theme, path, body) = text(..role-args(theme, path), cased(role(theme, path), body))

// ambient accessors — classes write (media, paper, theme, labels, parts)
// into state("tuftelike") before any content; helpers read it inside
// context so callers never have to thread theme/labels by hand
#let current-theme() = state("tuftelike").get().at("theme", default: default-theme)
```

NOTE `current-labels()` needs `default-labels`, which lives in labels.typ — add to `src/labels.typ`:

```typ
#let current-labels() = state("tuftelike").get().at("labels", default: default-labels)
```

and guard `state("tuftelike").get()` being `none` (no class installed): in BOTH accessors write
`let s = state("tuftelike").get(); if s == none { default-theme } else { s.at("theme", default: default-theme) }` (resp. labels).

- [ ] **Step 4: Export from `src/lib.typ`**

Replace line 6 with:
```typ
#import "themes.typ": default-theme, theme-presets, resolve-theme, deep-merge, role, role-args, styled, cased, current-theme, text-keys
```
and line 5 with:
```typ
#import "labels.typ": default-labels, resolve-labels, current-labels
```

- [ ] **Step 5: Run the theme test** — `env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts tests/assert/theme.typ out/x.pdf` → PASS (no output). Other assert files / examples will now FAIL (they still use flat keys) — expected until Tasks 2–8.

- [ ] **Step 6: Write `commit.txt`**

```
feat(themes): nested fonts+roles schema, deep merge, role-args/styled/current-theme primitives

Breaking: flat keys (serif, h1-size, …) are gone. Every text site becomes a role
with six text keys; auto = inherit. Ambient accessors read state("tuftelike").
```

---

### Task 2: base-style + newthought/tufte-quote consume roles (typography.typ)

**Files:**
- Modify: `src/typography.typ` (whole file)
- Test: `tests/assert/roles-render.typ` (create)

**Interfaces:**
- Consumes: `role-args`, `styled`, `role`, `current-theme` from Task 1.
- Produces: `newthought(body, theme: auto)`, `lead-smallcaps(body)` (unchanged), `tufte-quote(body, attribution: none, theme: auto)`, `base-style(theme, labels, note-ext, media:, doc)` (same signature).

- [ ] **Step 1: Write the failing test** `tests/assert/roles-render.typ`:

```typ
// compiles = passes: helpers must accept body-first / theme: auto signatures
// and must NOT need a class installed (fall back to default-theme)
#import "@local/tuftelike:0.1.0": newthought, tufte-quote, base-style, resolve-theme, resolve-labels
#show: base-style.with(resolve-theme((raw: (font: ("Zzz",)))), resolve-labels((:)), 0mm)
#newthought[Lead in] and body.
#tufte-quote(attribution: "Someone")[Quoted.]
#tufte-quote[No attribution.]
`inline code` and
```typ
block code
```
```

- [ ] **Step 2: Run** → FAIL (`newthought` expects theme positional / `theme.serif` missing).

- [ ] **Step 3: Rewrite `src/typography.typ`**

```typ
#import "utils.typ": plain-text, lead-split
#import "themes.typ": role, role-args, styled, current-theme

// theme: auto reads the class's stored theme; pass one to override
#let with-theme(theme, f) = if theme == auto { context f(current-theme()) } else { f(theme) }

#let newthought(body, theme: auto) = with-theme(theme, th => {
  v(role(th, "newthought").above, weak: true)
  styled(th, "newthought", plain-text(body))
})

#let lead-smallcaps(body) = {
  let (head, tail) = lead-split(plain-text(body))
  [#smallcaps(head)#tail]
}

// Tufte blockquote: indented, no bar, roomy. Attributed variant for epigraphs.
#let tufte-quote(body, attribution: none, theme: auto) = with-theme(theme, th => {
  let q = role(th, "quote")
  block(inset: (left: q.inset-left, right: q.inset-right))[
    #body
    #if attribution != none [ #v(q.attrib-gap) #align(right, styled(th, "epigraph-attrib", [— #attribution])) ]
  ]
})

// Applies document-wide text + heading + list + figure/table rules.
// `note-ext` = how far captions/tables extend into the note column.
// `media` drives the print-only parity behaviors (caption/table alignment
// flips to the outer edge on versos; tables become unbreakable).
// Every metric comes from the theme roles; defaults are the prototype
// book's print-proven values.
#let base-style(theme, labels, note-ext, media: "screen", doc) = {
  let body = role(theme, "body")
  set text(..role-args(theme, "body"))
  set par(justify: theme.justify, leading: body.leading, spacing: body.spacing)
  set list(body-indent: theme.list.body-indent, spacing: theme.list.spacing)
  set enum(body-indent: theme.list.body-indent, spacing: theme.list.spacing)
  show list: set par(justify: false)
  show raw: set text(..role-args(theme, "raw"))
  // level 1 needs an explicit size: a show-heading text override suppresses
  // Typst's built-in heading scaling. chapter.typ replaces level-1
  // rendering for books; the role still styles it there via styled().
  show heading.where(level: 1): set text(..role-args(theme, "heading.h1"))
  show heading.where(level: 2): set text(..role-args(theme, "heading.h2"))
  show heading.where(level: 3): set text(..role-args(theme, "heading.h3"))
  show heading.where(level: 4): set text(..role-args(theme, "heading.h4"))
  show heading.where(level: 5): set text(..role-args(theme, "heading.h5"))
  // above/below: auto = Typst's own heading spacing (block accepts auto)
  show heading.where(level: 1): set block(above: theme.heading.h1.above, below: theme.heading.h1.below)
  show heading.where(level: 2): set block(above: theme.heading.h2.above, below: theme.heading.h2.below)
  show heading.where(level: 3): set block(above: theme.heading.h3.above, below: theme.heading.h3.below)
  show heading.where(level: 4): set block(above: theme.heading.h4.above, below: theme.heading.h4.below)
  show heading.where(level: 5): set block(above: theme.heading.h5.above, below: theme.heading.h5.below)
  set heading(numbering: none) // mainmatter turns numbering on

  // Captions: "Supplement N." on its own sticky line, body below,
  // extending into the note column; on print versos the whole block sets
  // flush to the outer (left) edge.
  show figure.caption: it => context {
    let outer = if media == "print" and calc.even(here().page()) { right } else { left }
    align(outer, block(width: 100% + note-ext, inset: 0mm, sticky: true,
      align(left, {
        block(below: role(theme, "caption").below, sticky: true,
          styled(theme, "caption", [#it.supplement #context it.counter.display(it.numbering).]))
        styled(theme, "caption", it.body)
      })))
  }

  // Tables: caption on top, minimal strokes (header rule pair only; authors
  // close with table.hline), themed head/body cells, full width into the
  // note column, unbreakable in print, verso-flush in print.
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(supplement: labels.table, numbering: "1")
  show figure.where(kind: table): set block(breakable: media != "print")
  show figure.where(kind: table): it => context {
    let outer = if media == "print" and calc.even(here().page()) { right } else { left }
    align(outer, it)
  }
  show figure.where(kind: image): set figure(supplement: labels.figure, numbering: "1")
  show figure.where(kind: raw): set figure.caption(position: top)
  show figure.where(kind: raw): set figure(supplement: labels.code, numbering: "1")
  show table.cell: set par(justify: false)   // prototype book's cells are ragged-right
  show table.cell: it => {
    set text(..role-args(theme, "table-head")) if it.y == 0
    set text(..role-args(theme, "table-body")) if it.y > 0
    set align(left)
    it
  }
  let rule = theme.table-rule
  set table(stroke: (_, y) => if y == 0 { (top: rule.top + body.fill, bottom: rule.bottom + body.fill) })
  set table.hline(stroke: rule.hline + body.fill)
  show table: t => block(width: 100% + note-ext, inset: 0mm, t)

  show quote.where(block: true): it => tufte-quote(it.body, attribution: it.attribution, theme: theme)
  if theme.draft {
    set page(foreground: rotate(-55deg, styled(theme, "watermark", labels.draft)))
    doc
  } else { doc }
}
```

- [ ] **Step 4: Run** the new test AND `tests/assert/typography.typ` → both PASS.

- [ ] **Step 5: `commit.txt`**: `refactor(typography): base-style + newthought/tufte-quote read theme roles; raw gets theme.fonts.mono; justify is a theme knob`

---

### Task 3: Ambient notes, markdown, extras, mainmatter passthrough

**Files:**
- Modify: `src/notes.typ`, `src/markdown.typ`, `src/extras/instructional.typ`
- Test: `tests/assert/ambient.typ` (create)

**Interfaces:**
- Produces: `sidenote(dy: 0pt, theme: auto, body)`, `marginnote(dy: 0pt, theme: auto, body)`, `sidecite(key, supplement: none, theme: auto)`, `footnote-transform(theme, doc)` (unchanged), `md(src, reader:, content-root:, theme: auto, extensions:, label-prefix:)`, `instructional-extensions(theme: auto)`.

- [ ] **Step 1: Failing test** `tests/assert/ambient.typ`:

```typ
// A book with a custom sans; helpers called WITHOUT theme must see it.
#import "@local/tuftelike:0.1.0": *
#show: book.with(title: "Ambient", theme: (fonts: (sans: ("Zzz Sans", "Fira Sans"))))
#show: begin-chapters.with(resolve-media())
= One
#context assert(current-theme().fonts.sans.first() == "Zzz Sans")
#context assert(current-labels().chapter == "Chapter")
Body#sidenote[side] and#marginnote[margin] and #newthought[lead] then
#tufte-quote[q]
#md("Para with a note.<note>n</note>\n\n<prompt>p</prompt>", extensions: instructional-extensions())
```

- [ ] **Step 2: Run** → FAIL (`current-theme` ok, `sidenote` still fine, `instructional-extensions()` missing arg → error).

- [ ] **Step 3: Rewrite `src/notes.typ` bodies**

```typ
#import "@preview/marginalia:0.3.1" as marginalia
#import "themes.typ": role, styled, current-theme

#let arabic-note-numbering = (..i) => super(numbering("1", ..i))

// note body styled by the "note" role; theme: auto reads the class's
// stored theme inside context (the fix for silent fallback fonts)
#let note-body(theme, body) = context {
  let th = if theme == auto { current-theme() } else { theme }
  // block + set par, NOT par(..)[..]: par() silently DROPS block-level
  // content and warns on markdown-rendered footnotes
  styled(th, "note", block({ set par(leading: role(th, "note").leading); body }))
}

#let sidenote(dy: 0pt, theme: auto, body) = marginalia.note(dy: dy,
  numbering: arabic-note-numbering, note-body(theme, body))

#let marginnote(dy: 0pt, theme: auto, body) = marginalia.note(counter: none, dy: dy,
  note-body(theme, body))

#let notefigure(content, caption: none, dy: 0pt) = (
  marginalia.notefigure(content, caption: caption, dy: dy)
)

#let sidecite(key, supplement: none, theme: auto) = sidenote(theme: theme,
  cite(key, form: "full", supplement: supplement))

#let wideblock = marginalia.wideblock

#let footnote-transform(theme, doc) = {
  show footnote: it => sidenote(theme: theme, it.body)
  show footnote.entry: none
  set footnote.entry(separator: none)
  doc
}
```
Keep the existing explanatory comments about numbering and ordering.

`src/markdown.typ`: change the signature default to `theme: auto`; every `sidenote(theme: theme, …)`/`marginnote(theme: theme, …)` stays as-is (auto flows through); `blockquote: body => tufte-quote(body, theme: theme)`.

`src/extras/instructional.typ`:
```typ
#import "../themes.typ": styled, current-theme
#let instructional-extensions(theme: auto) = {
  let with(f) = if theme == auto { context f(current-theme()) } else { f(theme) }
  (
    prompt: (attrs, body) => block(inset: (left: 1em), with(th => styled(th, "prompt", body))),
    response: (attrs, body) => block(inset: (left: 1em, right: 1em), with(th => styled(th, "response", body))),
  )
}
```
(update the header comment's usage example to `instructional-extensions()`).

- [ ] **Step 4: Run** `tests/assert/ambient.typ` → PASS. Also `tests/visual/notes-page.typ` compiles.

- [ ] **Step 5: `commit.txt`**: `fix(notes): sidenote/marginnote/md/instructional read the ambient theme — no more silent Gill Sans fallback`

---

### Task 4: chapter.typ + runners.typ roles

**Files:**
- Modify: `src/chapter.typ`, `src/runners.typ`

**Interfaces:**
- Produces: `chapter-heading-rules(theme, labels, note-ext, icons:, doc)` (same), `part-divider(number, title, theme: auto, labels: auto)`, `folio(theme, note-ext:, media:, alt-runners:)` (same).

- [ ] **Step 1: Edit `src/chapter.typ`**

```typ
#import "utils.typ": plain-text
#import "themes.typ": role, styled, current-theme
#import "labels.typ": current-labels

#let chapter-heading-rules(theme, labels, note-ext, icons: (:), doc) = {
  show heading.where(level: 1): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      let num = counter(heading).display(it.numbering)
      let word = if num.match(regex("^[A-Z]")) != none { labels.appendix } else { labels.chapter }
      styled(theme, "chapter-label", word) + [ ] + text(..role-args(theme, "chapter-label"), num.trim("."))
      linebreak()
    }
    #styled(theme, "heading.h1", it.body)
    #v(role(theme, "opener").drop)
  ]
  show heading.where(level: 2): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      styled(theme, "section-number", counter(heading).display(it.numbering))
      linebreak()
    }
    #it.body
  ]
  show heading.where(level: 3): it => { … unchanged … }
  doc
}

#let part-divider(number, title, theme: auto, labels: auto) = page(header: none, footer: none)[
  #metadata(none) <divider-page>
  #context {
    let th = if theme == auto { current-theme() } else { theme }
    let lb = if labels == auto { current-labels() } else { labels }
    let pd = role(th, "part-divider")
    align(center)[
      #v(pd.top)
      #styled(th, "part-label", [#lb.part #number])
      #v(pd.gap)
      #styled(th, "part-title", title)
    ]
  }
]
```
(chapter-label: the old code applied `smallcaps(word)` but NOT to the number — the split above preserves that: `styled` cases the word, the number gets the same font/size without case. Add `role-args` to the import.)

- [ ] **Step 2: Edit `src/runners.typ`** — replace the `style(body)` helper with `let style(body) = styled(theme, "folio", body)`; import `styled` from themes.typ.

- [ ] **Step 3: Compile** `tests/visual/chapter-pages.typ` and `tests/visual/runners-pages.typ` (fix their `part-divider(theme, labels, …)` calls to `part-divider(…, theme: theme, labels: labels)`) → both compile.

- [ ] **Step 4: `commit.txt`**: `refactor(chapter,runners): opener/section-number/part-divider/folio read theme roles; part-divider is body-first + ambient`

---

### Task 5: frontmatter.typ roles (title page, copyright, dedication, epigraph, TOC)

**Files:**
- Modify: `src/frontmatter.typ`

**Interfaces:**
- Signatures unchanged (`title-page(theme, …)`, `copyright-page(theme, …)`, `dedication-page(theme, d)`, `epigraph-page(theme, e)`, `toc(theme, labels, parts:)`) — these are class-internal.

- [ ] **Step 1: Edit title-page**

```typ
#let title-page(theme, title: none, subtitle: none, authors: (), release: none,
                publisher: none) = align(left)[
  #let tp = role(theme, "title-page")
  #for a in authors [#styled(theme, "title-page.author", a) \ ]
  #v(tp.gap-author-title)
  #styled(theme, "title-page.title", title)
  #if subtitle != none [ \ #styled(theme, "title-page.subtitle", subtitle) ]
  #if release != none [ #v(tp.gap-release) #styled(theme, "title-page.release", release) ]
  #if publisher != none [ #align(bottom + left, styled(theme, "title-page.publisher", publisher.at("name", default: publisher))) ]
]
```
copyright-page: `#set text(..role-args(theme, "copyright"))` replaces `#set text(size: 9pt)`; keep its internal `v(0.5em)`/`v(1em)` → move to role keys `copyright.gap: 0.5em, copyright.publisher-gap: 1em` (add to default-theme: `copyright: r(size: 9pt, gap: 0.5em, publisher-gap: 1em)`).
dedication-page: `#set text(..role-args(theme, "dedication"))`; the `v(1.5em)`/`v(0.2em)`/`v(2em)` become `dedication.gap: 1.5em, dedication.attrib-gap: 0.2em, dedication.group-gap: 2em` (add to default-theme).
epigraph-page: `tufte-quote(q, attribution: a, theme: theme)`; `v(2em)` → `epigraph-gap: 2em` top-level key in default-theme.

- [ ] **Step 2: Edit toc()** — mechanical substitutions:
  - `let tc = role(theme, "toc")` at top
  - `folio-gap = if pagenums == "ragged" { "\u{a0}" * tc.folio-gap } else { h(1fr) }`
  - `group-header(title) = block(above: tc.group.above, sticky: true, styled(theme, "toc.group", title))`
  - `show outline.entry.where(level: 1): set block(above: tc.l1.above, sticky: true)`
  - `row(prefix, inner) = link(el.location(), pad(left: tc.indent, it.indented(prefix, inner, gap: tc.entry-gap)))`
  - backmatter gap: `block(above: tc.backmatter-gap, text(none))`
  - unnumbered row: `row(" ", styled(theme, "toc.unnumbered", it.body()) + folio-gap + it.page())`
  - numbered rows: `let lvl = if it.level == 1 { "toc.l1" } else { "toc.l2" }` then `row(text(..role-args(theme, "toc.prefix"), size: role(theme, lvl).size, padded), styled(theme, lvl, it.body()) + folio-gap + it.page())`
  - title: `styled(theme, "toc.title", labels.contents)` then `v(tc.title-gap)`
  Keep every existing comment (they document parity findings).

- [ ] **Step 3: Parity check** — rebuild the TOC fixture and diff line bboxes against the baseline:

```bash
env -u TYPST_PACKAGE_PATH typst compile --root . --font-path fonts tests/visual/toc-page.typ out/toc-after.pdf
mutool draw -F stext -o - out/toc-after.pdf 1 2>/dev/null | grep -oE '<line bbox="[^"]*"[^>]*text="[^"]*"' > out/toc-after.txt
diff out/baseline-toc.txt out/toc-after.txt && echo PARITY-OK
```
Expected: `PARITY-OK` (identical bboxes). If not, the offending role default is wrong — fix the default, not the fixture.

- [ ] **Step 4: `commit.txt`**: `refactor(frontmatter): title/copyright/dedication/epigraph/TOC read theme roles; TOC geometry parity verified vs baseline`

---

### Task 6: backmatter.typ + book class

**Files:**
- Modify: `src/backmatter.typ`, `src/classes/book.typ`

**Interfaces:**
- Produces: `about-author(body, theme: auto, labels: auto)`, `colophon(body, theme: auto, labels: auto)`, `book-index(theme: auto, labels: auto, columns: 2)`, `references(bib, hidden:)` unchanged.

- [ ] **Step 1: Rewrite the three helpers**

```typ
#import "labels.typ": default-labels, current-labels
#import "themes.typ": role, role-args, styled, current-theme

#let resolve-ambient(theme, labels, f) = context {
  let th = if theme == auto { current-theme() } else { theme }
  let lb = if labels == auto { current-labels() } else { labels }
  f(th, lb)
}

#let about-author(body, theme: auto, labels: auto) = page(header: none, footer: none,
  resolve-ambient(theme, labels, (th, lb) => {
    [#metadata(none) <no-folio>]
    toc-entry(lb.about-author)
    styled(th, "backmatter-label", lb.about-author)
    v(role(th, "backmatter-label").below)
    body
  }))

#let colophon(body, theme: auto, labels: auto) = page(header: none, footer: none,
  resolve-ambient(theme, labels, (th, lb) => {
    [#metadata(none) <no-folio>]
    toc-entry(lb.colophon)
    set text(..role-args(th, "colophon"))
    align(center + bottom, body)
  }))

#let book-index(theme: auto, labels: auto, columns: 2) = resolve-ambient(theme, labels, (th, lb) => {
  import "@preview/in-dexter:0.7.2" as in-dexter
  set text(..role-args(th, "index"))
  set par(justify: false)
  heading(level: 1, numbering: none, lb.index)
  std.columns(columns, in-dexter.make-index(title: none, outlined: false, use-page-counter: true))
})
```
RISK: `toc-entry` (a heading) and `<no-folio>` metadata inside `context` — headings inside context are allowed but the folio's `query(<no-folio>)` and the outline must still see them. Verify by compiling `examples/book` print and checking (a) About the Author appears in the TOC, (b) no running head on that page. If the outline loses the entry, hoist the metadata + `toc-entry` OUT of the context block (labels resolved via a second, outer `context` only for the label string is not possible — instead keep `labels: auto` resolved inside `context` for display text and emit `toc-entry` from a `context` block too; test which works; document the finding in a comment).

- [ ] **Step 2: `src/classes/book.typ`** — no schema references remain except `theme.screen-bg` (still valid). Confirm with `grep -n "theme\." src/classes/book.typ`. Update the state write comment: "helpers read this via current-theme()/current-labels()".

- [ ] **Step 3: Migrate `examples/book/main.typ`** — `part-divider("I", "Threads")`, `extensions: instructional-extensions()`, `about-author[…]`, `colophon[…]`, `book-index()`. Migrate `examples/book/themes.typ`:
```typ
#let trade-serif = ("ETbb", "Palatino", "Georgia")
#let book-presets = (
  // 10pt body is the 6x9-friendly measure; flush folios de-Tufte the TOC
  trade: (body: (size: 10pt), note: (size: 8.5pt), toc-pagenums: "flush",
    fonts: (serif: trade-serif)),
)
```
Also grep `tests/visual/*.typ` and `template/main.typ` for `about-author(`, `colophon(`, `book-index(`, `part-divider(`, `newthought(`, `tufte-quote(` and migrate call sites.

- [ ] **Step 4: Verify** `just demo book print && just demo book screen`; `pdffonts out/book-print.pdf | awk 'NR>2{print $1}' | sed 's/^[A-Z]*+//' | sort -u | diff - out/baseline-book-fonts.txt && echo FONTS-OK`; page count equals baseline (`pdfinfo … | grep Pages`).

- [ ] **Step 5: `commit.txt`**: `refactor(backmatter): about-author/colophon/book-index body-first + ambient theme/labels; migrate book example`

---

### Task 7: letter, handout, cover classes

**Files:**
- Modify: `src/classes/letter.typ`, `src/classes/handout.typ`, `src/cover.typ`

- [ ] **Step 1: letter.typ** — `let L = role(theme, "letter")`; header text → `styled(theme, "letter.runner", […])`; letterhead `text(..role-args(theme, "letter.letterhead"))[…]`; `v(2em)`→`v(L.after-letterhead)`, `v(1.5em)` after date→`L.after-date`, after to→`L.after-to`, re line → `styled(theme, "letter.re", [Re: #re]); v(L.after-re)`, salutation→`L.after-salutation`, closing→`L.before-closing`, signature→`L.before-signature`, enclosures→`v(L.before-enclosures); styled(theme, "letter.meta", […])`, cc→`L.before-cc`.
- [ ] **Step 2: handout.typ** — `let H = role(theme, "handout")`; footer `styled(theme, "handout.footer", content)`; title `styled(theme, "handout.title", title)`, subtitle `styled(theme, "handout.subtitle", subtitle)`; `v(1em)`→`H.after-title`; grid gutter `H.author-gutter`; author cell `text(..role-args(theme, "handout.author"))[#styled(theme, "handout.author-name", name) \ …]`; `v(0.6em)`→`H.after-authors`; meta block `styled(theme, "handout.meta", […])`; `v(1.2em)`→`H.after-meta`; abstract `block(inset: (left: H.abstract-inset, right: H.abstract-inset), styled(theme, "handout.abstract", abstract))`; `v(1.5em)`→`H.after-abstract`. Update the stale comment about "base-style's document-wide justify:true" (justify is now a theme knob, default false; the `par(justify: false)` on the title block stays as belt-and-braces).
- [ ] **Step 3: cover.typ** — `set text(..role-args(theme, "cover.base"))`; barcode zone: `styled(theme, "cover.stamp", labels.review-copy)`, `styled(theme, "cover.isbn", "ISBN " + barcode.isbn)`; spine `styled(theme, "cover.spine", [...])`; front panel: `styled(theme, "cover.author", …)`, `styled(theme, "cover.title", …)`, `v(role(theme,"cover").subtitle-gap)` + `styled(theme, "cover.subtitle", …)`, `styled(theme, "cover.release", …)`. (`upper()` calls go away — `case: "upper"` on the roles does it.)
- [ ] **Step 4: Verify** `just cover`, `just demo letter`, `just demo handout`; open PDFs side by side with the previous `out/matrix-*` builds — visually identical.
- [ ] **Step 5: `commit.txt`**: `refactor(classes): letter/handout/cover metrics move into theme roles`

---

### Task 8: Lint script + test wiring + README

**Files:**
- Create: `tests/lint-hardcoded.sh`
- Modify: `justfile` (test recipe), `README.md` (Theme & labels section)

- [ ] **Step 1: `tests/lint-hardcoded.sh`**

```bash
#!/usr/bin/env bash
# Guard: every typographic knob lives in src/themes.typ. Any literal size,
# tracking, weight, color, font stack, or justify:true elsewhere in src/ fails.
set -euo pipefail
cd "$(dirname "$0")/.."
pattern='(size|tracking|above|below|inset|leading|spacing): [0-9.]+(pt|em|mm)|weight: "|luma\(|rgb\(|font: \("|justify: true'
hits=$(grep -rnE "$pattern" src --include='*.typ' | grep -v '^src/themes.typ' | grep -v 'lint-ok' || true)
if [[ -n "$hits" ]]; then
  echo "hardcoded typography outside src/themes.typ:" >&2
  echo "$hits" >&2
  exit 1
fi
echo "lint-hardcoded: clean"
```
Escape hatch: a line ending in `// lint-ok: <reason>` is exempt (use for geometry that is genuinely not typography, e.g. `inset: 0mm` on wide blocks, `height: 1em` icon boxes). Expect a handful; each needs a reason.

- [ ] **Step 2: Run it**, fix every hit by moving the value into a role (add keys to `default-theme` as needed — e.g. `chapter.typ` icon `grid(columns: (1.5em, auto), gutter: 0.5em)` → `heading.h3-icon: (width: 1.5em, gutter: 0.5em)`), or annotate `lint-ok`. Iterate until clean.
- [ ] **Step 3: justfile** — in `test:` add `tests/lint-hardcoded.sh` before the assert loop; add `tests/assert/ambient.typ`/`roles-render.typ` are picked up by the glob automatically.
- [ ] **Step 4: `just test`** → all green (6+2 asserts, matrix, lint).
- [ ] **Step 5: README** — rewrite "Theme & labels" (lines ~259-330): show the nested shape (`theme: (fonts: (serif: ("Georgia",)), body: (size: 10pt), heading: (h2: (weight: "bold", above: 2em)))`), the alias rule (`font: "serif"|"sans"|"mono"` or a stack), `auto` = inherit, deep-merge + arrays-replace warning, `justify: false` default, and a pointer: "`default-theme` in `src/themes.typ` is the complete list of knobs". Update presets example to nested keys and the instructional example to `instructional-extensions()`. Add one line under a new "Extending" note: helpers (`sidenote`, `newthought`, `part-divider`, `about-author`, …) read the class's theme automatically; pass `theme:` only to override.
- [ ] **Step 6: `commit.txt`**: `test(lint): guard against hardcoded typography in src/; docs(readme): nested theme schema`

---

### Task 9: `bin/typst-deps` + just recipes

**Files:**
- Create: `bin/typst-deps` (chmod +x)
- Modify: `justfile`

- [ ] **Step 1: Script**

```bash
#!/usr/bin/env bash
# typst-deps — report/update @preview package pins in this repo.
#   typst-deps outdated          list pins vs Typst Universe latest (exit 1 if any behind)
#   typst-deps update [name…]    rewrite pins to latest (all, or named); run `just test` after
set -euo pipefail
cd "$(dirname "$0")/.."
INDEX_URL="https://packages.typst.org/preview/index.json"
SCAN_DIRS=(src template examples tests)
usage() { sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; }
[[ $# -ge 1 ]] || { usage >&2; exit 2; }
cmd=$1; shift
command -v jq >/dev/null || { echo "jq required" >&2; exit 2; }
command -v curl >/dev/null || { echo "curl required" >&2; exit 2; }

# name<TAB>version<TAB>file:line, one row per pin site
scan() {
  grep -rnoE '@preview/[a-z0-9-]+:[0-9]+\.[0-9]+\.[0-9]+' "${SCAN_DIRS[@]}" \
    | sed -E 's|^([^:]+:[0-9]+):@preview/([a-z0-9-]+):([0-9.]+)$|\2\t\3\t\1|' | sort
}
latest_of() { # name -> highest version in the index
  jq -r --arg n "$1" '.[] | select(.name==$n) | .version' <<<"$INDEX" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1
}
INDEX=$(curl -fsSL "$INDEX_URL")

case "$cmd" in
  outdated)
    behind=0
    printf '%-14s %-9s %-9s %s\n' NAME PINNED LATEST SITES
    while IFS=$'\t' read -r name ver _; do
      sites=$(scan | awk -F'\t' -v n="$name" -v v="$ver" '$1==n && $2==v' | wc -l | tr -d ' ')
      latest=$(latest_of "$name"); [[ -n "$latest" ]] || latest="?"
      flag=""; [[ "$latest" != "$ver" && "$latest" != "?" ]] && { flag="  <-- behind"; behind=1; }
      printf '%-14s %-9s %-9s %s%s\n' "$name" "$ver" "$latest" "$sites" "$flag"
    done < <(scan | cut -f1,2 | sort -u)
    exit $behind ;;
  update)
    want=("$@")
    while IFS=$'\t' read -r name ver; do
      if [[ ${#want[@]} -gt 0 ]]; then
        printf '%s\n' "${want[@]}" | grep -qx "$name" || continue
      fi
      latest=$(latest_of "$name")
      [[ -n "$latest" && "$latest" != "$ver" ]] || continue
      echo "$name: $ver -> $latest"
      scan | awk -F'\t' -v n="$name" -v v="$ver" '$1==n && $2==v {print $3}' | cut -d: -f1 | sort -u \
        | while read -r f; do sed -i '' -E "s|@preview/$name:$ver|@preview/$name:$latest|g" "$f"; echo "  $f"; done
      [[ "$name" == "in-dexter" ]] && echo "  NOTE: in-dexter is ALSO pinned in colophon's config — bump it there too." >&2
    done < <(scan | cut -f1,2 | sort -u)
    echo "done — run: just test" ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Manual test** — `bin/typst-deps outdated` prints 4 rows (marginalia 0.3.1, cmarker 0.1.10, tiaoma 0.3.0, in-dexter 0.7.2) with real latest versions; `bin/typst-deps update nonexistent` prints only "done"; `git diff --stat` empty. Do NOT run a real update in this task (bumps are a separate decision — memory says marginalia/in-dexter bumps may need code changes).
- [ ] **Step 3: justfile**

```just
# list @preview package pins vs Typst Universe (exit 1 if any are behind)
outdated:
    bin/typst-deps outdated

# bump @preview pins to latest (optionally only the named packages), then test
update *pkgs:
    bin/typst-deps update {{pkgs}}
    just test
```
- [ ] **Step 4: `just outdated`** runs. `commit.txt`: `feat(just): outdated/update recipes via bin/typst-deps (Universe index)`

---

### Task 10: Field migration — wiring-guides + final verification

**Files (other repo, `~/source/wiring-guides`):**
- Modify: `src/setup.typ`, `src/phases/how-to-use.typ`, `src/guide-ext.typ`

- [ ] **Step 1: setup.typ theme** — replace `guide-theme` and delete the three heading show rules in `guide-book` (they become roles):

```typ
#let helv = ("Helvetica Neue", "Helvetica")
#let guide-theme = (
  fonts: (serif: ("Times New Roman", "Times"), sans: helv, mono: ("Menlo", "Consolas")),
  heading: (
    h2: (font: "sans", size: 14pt, weight: "bold", style: "normal", fill: luma(30), above: 1.2em, below: 0.4em),
    h3: (font: "sans", size: 11pt, weight: "bold", style: "normal", fill: luma(60), above: 0.8em, below: 0.2em),
    h4: (font: "serif", size: 10pt, weight: "bold", style: "italic", fill: luma(60), above: 0.5em, below: 0.1em),
  ),
  draft: false,
)
```
Keep `show heading: set par(justify: false)` (harmless). If the h2/h3 rendering differs from the old explicit `v()` version (Typst heading `above/below` are block spacing, the old code was inline `v()`), adjust `above`/`below` numbers by eye — that IS the knob now.
- [ ] **Step 2: how-to-use.typ** — `#newthought(default-theme)[The prose]` → `#newthought[The prose]` (both sites). **guide-ext.typ** — remove every `theme: (:)` param and `theme: theme` forward on `time-est`, `strip-guide`, `note`, `ground-note`, `margin-skip` (marginnote is ambient now).
- [ ] **Step 3: Rebuild + font inventory**

```bash
cd ~/source/wiring-guides && just build
n=$(pdfinfo out/guide.pdf | awk '/^Pages/{print $2}')
for p in $(seq 1 $n); do mutool draw -F stext -o - out/guide.pdf $p 2>/dev/null | grep -o 'font name="[^"]*"'; done | sort | uniq -c
```
Expected: only TimesNewRoman*, HelveticaNeue*, Menlo* (+ possibly STIX math). **Zero** ETbb / GillSans / Hack / Libertinus / .SFNS. If `.SFNS-RegularItalic` persists it is Helvetica Neue lacking an italic face in the note role — that is a real font-availability issue in his stack, report it, don't paper over it.
- [ ] **Step 4: Back in tuftelike:** `just test` green; `direnv exec . just proto-check` compiles; write final `commit.txt` if anything changed; update memory `build-status.md` (Clay's book theme file still to migrate — ask for its path).

---

## Self-review

- Spec coverage: schema+merge+primitives (T1), base-style/raw/justify (T2), ambient helpers incl. md/extras (T3), chapter/runners (T4), frontmatter+TOC parity (T5), backmatter+book+examples (T6), letter/handout/cover (T7), lint+README (T8), deps recipes (T9), wiring-guides + field check (T10). Clay's own book: flagged in T10 (path unknown).
- Type consistency: role paths use dots; `styled(theme, path, body)`; helpers are `body`-first with `theme: auto, labels: auto`; `role-args` drops `auto`. `epigraph-gap`, `copyright.gap/publisher-gap`, `dedication.gap/attrib-gap/group-gap`, `heading.h3-icon` are added to `default-theme` in T5/T8 — T1's schema-completeness test only checks roles that have `font`, so adding keys later is safe.
- Known risk called out: `context`-wrapped headings/metadata in T6 (verify outline + folio); heading `above/below` semantics differ from inline `v()` in the wiring guide (T10 says tune by eye).
