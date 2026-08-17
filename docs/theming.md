# Theming tuftelike

tuftelike ships one look — the print-proven Tufte book: ETbb body, Gill Sans margin
notes, italic serif headings, ragged contents page. Every number behind that look is
a knob in the **theme**, and the theme is designed so you can move a long way from
Tufte (bold Helvetica heads, Times body, no italics anywhere) without touching a
show rule.

This document is the long-form reference. The short version is in the README's
"Theme & labels" section. The *authoritative* list of knobs is the `default-theme`
dict in `src/themes.typ` — this page explains the shape; that file has the values.

Contents:

1. [Mental model](#1-mental-model)
2. [The schema](#2-the-schema)
3. [Roles, key by key](#3-roles-key-by-key)
4. [Font aliases](#4-font-aliases)
5. [Merging and presets](#5-merging-and-presets)
6. [Ambient theme: helpers just work](#6-ambient-theme-helpers-just-work)
7. [Role reference](#7-role-reference)
8. [Recipes](#8-recipes)
9. [Extending: using roles in your own show rules](#9-extending-using-roles-in-your-own-show-rules)
10. [Guarantees, tests, and the lint](#10-guarantees-tests-and-the-lint)
11. [Design notes and non-goals](#11-design-notes-and-non-goals)

---

## 1. Mental model

Three ideas carry the whole system:

**Fonts are named, roles use the names.** The theme declares three font stacks —
`serif`, `sans`, `mono` — and every text site says *which* stack it wants by name.
Change `fonts.serif` once and the body, the headings, the folio, the TOC, the
title-page subtitle all follow. Any single site can still opt out by naming an
explicit stack.

**Every text site is a role.** A role is a small dict with the same six text keys
(`font`, `size`, `weight`, `style`, `tracking`, `fill`) plus, where it makes sense,
spacing keys and a `case` transform. `body`, `note`, `folio`, `heading.h2`,
`toc.group`, `title-page.author`, `cover.spine` — around fifty of them, one per
distinct piece of typography the package renders. There is no typography anywhere in
`src/` that is not a role: a lint enforces it.

**The class stores the theme; helpers read it.** `book()`, `letter()`, `handout()`,
`cover()` resolve the theme once and write it into `state("tuftelike")`. Every
content-level helper — `sidenote`, `newthought`, `part-divider`, `about-author`,
`md`, … — reads it from there. You never thread `theme:` through your own code.

## 2. The schema

Top level of `default-theme`:

| key | type | meaning |
|---|---|---|
| `fonts` | dict of stacks | `serif`, `sans`, `mono` — arrays of family names, first found wins |
| `justify` | bool | paragraph justification for body text. **Default `false`.** No class justifies unless you ask. |
| `screen-bg` | color | page fill in `media=screen` (print is always unfilled) |
| `toc-pagenums` | `"ragged"` \| `"flush"` | contents-page folio placement (Tufte's ragged style vs. right-edge) |
| `draft` | bool | rotated DRAFT watermark on every page (see the `watermark` role) |
| everything else | roles / role groups | see [§7](#7-role-reference) |

Roles are either top-level (`body`, `note`, `folio`, `raw`, `caption`, …) or grouped
one level down (`heading.h1`…`h5`, `toc.*`, `title-page.*`, `cover.*`, `letter.*`,
`handout.*`). Groups also carry a few plain values that aren't roles — spacing
constants like `toc.indent` or `title-page.gap-author-title`. Both live in the same
dict; you address them the same way.

Role paths are dotted strings when you use the helper functions:
`role(theme, "heading.h2")`, `styled(theme, "toc.group", body)`.

## 3. Roles, key by key

Every role has these six keys. Any of them may be `auto`, which means **inherit from
the surrounding text** — the role does not touch that property.

| key | values | notes |
|---|---|---|
| `font` | `"serif"` \| `"sans"` \| `"mono"` \| explicit array | alias resolves against `theme.fonts`; array is used verbatim |
| `size` | length | absolute (`10pt`) or relative to the enclosing text (`0.8em`, `1em - 1pt`) |
| `weight` | `"regular"`, `"bold"`, `"semibold"`, `"light"`, or an integer 100–900 | passed straight to `text(weight:)` |
| `style` | `"normal"` \| `"italic"` \| `"oblique"` | |
| `tracking` | length | letter-spacing; `0em` is explicit "none", `auto` is inherit |
| `fill` | color | text colour |

Optional keys some roles carry:

| key | where | meaning |
|---|---|---|
| `above`, `below` | `heading.h1`–`h5`, `toc.group`, `toc.l1`, `caption`, `newthought`, `backmatter-label` | vertical spacing the role owns. On headings, `auto` leaves Typst's own heading spacing alone; a length replaces it. |
| `leading` | `body`, `note` | line leading within the role's paragraphs |
| `spacing` | `body` | paragraph spacing |
| `case` | `chapter-label`, `newthought`, `toc.group`, `title-page.*`, `cover.*`, `backmatter-label` | `"upper"` \| `"smallcaps"` \| `none` — a text transform applied to the role's content |
| `inset` | `prompt`, `response` | block inset for the instructional dialogue tags |
| named gaps | `copyright.gap`, `dedication.group-gap`, `toc.title-gap`, `letter.after-date`, … | plain lengths a role or group owns; listed per role in [§7](#7-role-reference) |

Why six keys on every role even when most are `auto`? So the theme is *complete*:
you can look at any role and know exactly what it controls, and you can override any
property of any site without checking whether the package "happens to" set it. The
`tests/assert/theme.typ` schema test walks the whole dict and fails if a role is
missing a key.

## 4. Font aliases

```typ
theme: (
  fonts: (serif: ("Charter", "Georgia"), sans: ("Fira Sans", "Helvetica Neue")),
)
```

That is the whole "swap the fonts" story for a book. Every role whose `font` is
`"serif"` (body, headings, folio, TOC, quotes, title-page subtitle, part titles, …)
now sets in Charter; every `"sans"` role (notes, captions, chapter labels, section
numbers, title-page caps lines, cover) in Fira Sans.

Two rules:

- **Arrays replace wholesale.** `fonts: (serif: ("Georgia",))` gives you Georgia and
  *only* Georgia — the ETbb/Palatino fallbacks are gone. Pass the full stack you want.
  (This is deliberate: a fallback chain you didn't choose is a bug you can't see.)
- **A role can name a stack directly.** `heading: (h2: (font: ("Futura",)))` sets
  h2 in Futura regardless of `fonts.sans`. Use this sparingly; the aliases exist so
  that one decision propagates.

An unknown alias (`font: "display"`) is a compile-time assert with the list of valid
aliases. There are exactly three; if you need a fourth family, name it explicitly on
the roles that use it.

## 5. Merging and presets

### Deep merge

Your `theme:` dict is **deep-merged** over the defaults: dictionaries merge at every
level, everything else (arrays, lengths, strings, colours) replaces.

```typ
theme: (heading: (h2: (weight: "bold")))
```

touches exactly `heading.h2.weight`. `heading.h2.size`, `heading.h1`, and every other
key are untouched. You never have to restate a role to change one property of it.

### Presets

`presets:` on every class is a dict of *named* overlays; `--input theme=<name>` (or
`theme-preset: "<name>"`) selects one at compile time. The chain is:

```
default-theme  ←  selected preset overlay  ←  your theme: dict
```

Your `theme:` dict is unconditional — it applies under every preset. Presets are
where variants live: a 10pt "trade" cut of the same book, a large-print edition, a
per-trim type spec.

```typ
#show: book.with(
  theme: (fonts: (serif: my-serif)),                     // always
  presets: (
    trade: (body: (size: 10pt), note: (size: 8.5pt), toc-pagenums: "flush"),
    large: (body: (size: 13pt, leading: 0.9em), note: (size: 10.5pt)),
  ),
)
```

```sh
typst compile --input theme=trade main.typ
just demo book print trade
```

Built-in preset names live in `theme-presets`; `beautiful-evidence` is the identity
overlay (selecting it means "the defaults"). Presets for other print sizes will land
there as they're proven against printed proofs — the decision on record is that
**per-trim type sizes are theme presets, not paper-dict fields**: geometry stays in
`geometry.typ`, type stays here.

Selecting an unknown preset name is an assert listing what's available.

### Sharing presets across books

`presets:` takes any dict, so keep your house variants in one Typst module and
symlink it into each project (`examples/book/themes.typ` is the model):

```sh
ln -s ~/writing/my-themes.typ themes.typ
```

```typ
#import "themes.typ": book-presets
#show: book.with(presets: book-presets, …)
```

A module (unlike a data file) can hold helper functions, shared stacks, and imports.
A `--input theme-file=` mechanism was considered and rejected: package code cannot
read project files without a reader closure, and eval'd files can't import.

## 6. Ambient theme: helpers just work

Every class writes the resolved theme and labels into `state("tuftelike")` before
any content. Every content-level helper reads them from there inside a `context`
block:

| helper | signature |
|---|---|
| `sidenote`, `marginnote` | `(dy: 0pt, theme: auto, body)` |
| `sidecite` | `(key, supplement: none, theme: auto)` |
| `newthought` | `(body, theme: auto)` |
| `tufte-quote` | `(body, attribution: none, theme: auto)` |
| `md` | `(src, reader:, content-root:, theme: auto, extensions:, label-prefix:)` |
| `part-divider` | `(number, title, theme: auto, labels: auto)` |
| `about-author`, `colophon` | `(body, theme: auto, labels: auto)` |
| `book-index` | `(theme: auto, labels: auto, columns: 2)` |
| `instructional-extensions` | `(theme: auto)` |

So in a book file this is all you write:

```typ
#part-divider("I", "Triage")
Some prose#sidenote[in the class's note font] and #newthought[a lead-in].
#about-author[…]
#book-index()
```

Pass `theme:` only to *override*: the dict you pass is deep-merged over the ambient
theme (`with-theme`, exported), so a one-key overlay is enough — a one-off note in a
different face, a fixture that has no class installed. `labels:` is all-or-nothing. Outside any class (bare fixtures, tests) the
accessors fall back to `default-theme` / `default-labels`.

`current-theme()` and `current-labels()` are exported for your own `context` blocks:

```typ
#context text(..role-args(current-theme(), "note"))[styled like a margin note]
```

Why this matters: the previous design threaded `theme` as an argument, and every
caller that forgot to pass it silently rendered in the *default* fonts. Two real
books had Gill Sans margin notes in Times/Charter bodies without anyone noticing
until a font inventory was pulled. Ambient state makes the correct thing the only
thing.

## 7. Role reference

Defaults shown are the Tufte look. `auto` = inherit. Paths are what you write in a
`theme:` dict (nested) or pass to `role()`/`styled()` (dotted).

### Base text — `typography.typ` `base-style`

| role | default | applied to |
|---|---|---|
| `body` | serif · 11pt · regular · normal · 0em · `luma(30)` · `leading: 0.8em` · `spacing: 1.4em` | document text; `leading`/`spacing` feed `set par`; `fill` also strokes table rules |
| `note` | sans · 9pt · `leading: 0.5em` | sidenotes, marginnotes, sidecites, markdown footnotes/`<note>` |
| `folio` | serif · 8pt · regular · normal · tracking 0.12em | running heads (book) |
| `raw` | mono · 0.8em | inline and block code (`show raw`) |
| `list` | `spacing: 1.2em`, `body-indent: 1em` | lists and enums (not a text role — spacing only) |
| `heading.h1`…`h5` | serif · 20/18/16/14/12pt · regular · italic · `above: auto` · `below: auto` | heading text via show-set; `above`/`below` replace Typst's heading spacing only when set |
| `heading.h3-icon` | `width: 1.5em`, `gutter: 0.5em` | the keyword→icon grid on level-3 headings (`icons:` on `book()`) |
| `caption` | sans · 9pt · `below: 0.5em` | figure/table captions; `below` is the gap between "Figure N." and the caption body |
| `table-head` | 10pt · regular | table row 0 |
| `table-body` | 9pt · regular | table rows ≥ 1 |
| `table-rule` | `top: 1pt`, `bottom: 0.3pt`, `hline: 0.7pt` | stroke weights (colour = `body.fill`) |
| `newthought` | serif · tracking 0.05em · `case: "smallcaps"` · `above: 1em` | `newthought[…]` lead-ins |
| `quote` | `inset-left: 1.5em`, `inset-right: 1em`, `attrib-gap: 0.3em` | block quotes / `tufte-quote` geometry |
| `epigraph-attrib` | italic | the "— Author" line under an attributed quote |
| `epigraph-gap` | 2em | between stacked epigraphs on the epigraph page |
| `watermark` | sans · 96pt · `luma(85)` | the DRAFT stamp when `draft: true` |

### Chapters and parts — `chapter.typ`

| role | default | applied to |
|---|---|---|
| `chapter-label` | sans · 10pt · normal · `case: "smallcaps"` | "Chapter 3" / "Appendix B" line above an opener title (the number is not cased) |
| `section-number` | sans · 8pt · `luma(120)` | the "3.2" above a level-2 heading |
| `opener` | `drop: 2.5em` | space below a chapter title before the text starts |
| `part-label` | serif · 16pt | "Part II" on a divider page |
| `part-title` | serif · 24pt | the part's title |
| `part-divider` | `top: 6.4em`, `gap: 0.3em` | divider page vertical geometry |

### Front matter — `frontmatter.typ`

| role | default | applied to |
|---|---|---|
| `title-page.author` | sans · 16pt · tracking 0.2em · upper | |
| `title-page.title` | sans · 20pt · tracking 0.16em · upper | |
| `title-page.subtitle` | serif · 15pt · italic | |
| `title-page.release` | sans · 12pt · tracking 0.16em · upper | "First Edition" |
| `title-page.publisher` | sans · 14pt · tracking 0.16em · upper | bottom of page |
| `title-page.gap-author-title` / `.gap-release` | 8em / 2em | |
| `copyright` | 9pt · `gap: 0.5em` · `publisher-gap: 1em` | copyright page text |
| `dedication` | italic · `gap: 1.5em` · `attrib-gap: 0.2em` · `group-gap: 2em` | |
| `toc.title` | 20pt · italic | "Contents" |
| `toc.group` | serif · semibold · tracking 0.16em · upper · `above: 1.3em` | PART / APPENDICES headers |
| `toc.l1` | serif · `size: auto` · italic · `above: 1.1em` | chapter rows (size follows body) |
| `toc.l2` | serif · `size: 1em - 1pt` · normal | section rows (one point under body) |
| `toc.prefix` | serif · normal | the number column (size follows the row) |
| `toc.unnumbered` | serif · italic | front sections, About the Author, Colophon, Index |
| `toc.title-gap` / `.indent` / `.entry-gap` / `.backmatter-gap` | 2.1em / 2em / 1.5em / 1.2em | calibrated against the prototype's first-print PDF |
| `toc.folio-gap` | 8 | count of no-break spaces between title and page number in ragged mode |

### Back matter — `backmatter.typ`

| role | default | applied to |
|---|---|---|
| `backmatter-label` | sans · 10pt · tracking 0.16em · upper · `below: 1.5em` | "ABOUT THE AUTHOR" |
| `colophon` | 9pt | colophon body |
| `index` | 9pt | back-of-book index |

### Cover — `cover.typ`

| role | default |
|---|---|
| `cover.base` | sans · white — `set text` for the whole jacket |
| `cover.author` | 14pt · tracking 0.2em · upper |
| `cover.title` | 26pt · tracking 0.12em · upper |
| `cover.subtitle` | serif · 14pt · italic |
| `cover.release` | 10pt · tracking 0.16em · upper |
| `cover.spine` | 11pt · tracking 0.14em |
| `cover.isbn` | mono · 7pt · black — the "ISBN …" line in the barcode zone |
| `cover.stamp` | sans · 9pt · semibold · black — REVIEW COPY stamp |
| `cover.subtitle-gap` | 0.5em |

### Letter — `classes/letter.typ`

| role | default |
|---|---|
| `letter.letterhead` | sans · 9pt |
| `letter.runner` | serif · 8pt · tracking 0.12em — page-2+ header |
| `letter.re` | semibold |
| `letter.meta` | 9pt — enclosures / cc lines |
| `letter.after-letterhead` … `before-cc` | 2em, 1.5em, 1.5em, 1em, 0.8em, 2em, 0.4em, 1.5em, 0.3em — every vertical gap in the letter skeleton, named for where it sits |

### Handout — `classes/handout.typ`

| role | default |
|---|---|
| `handout.title` | serif · 2.3em · regular |
| `handout.subtitle` | serif · 1.3em · italic |
| `handout.author` | sans · 9pt |
| `handout.author-name` | semibold |
| `handout.meta` | sans · 8pt · `luma(100)` — document number / distribution |
| `handout.abstract` | italic |
| `handout.footer` | sans · 8pt |
| `handout.after-title` / `author-gutter` / `after-authors` / `after-meta` / `abstract-inset` / `after-abstract` | 1em / 1.5em / 0.6em / 1.2em / 2em / 1.5em |

### Extras — `extras/instructional.typ`

| role | default |
|---|---|
| `prompt` | mono · 10pt · bold · `inset: (left: 1em)` |
| `response` | serif · `inset: (left: 1em, right: 1em)` |

## 8. Recipes

**De-Tufte a technical manual** (bold sans heads, upright, tighter):

```typ
#let helv = ("Helvetica Neue", "Helvetica")
theme: (
  fonts: (serif: ("Times New Roman", "Times"), sans: helv, mono: ("Menlo", "Consolas")),
  heading: (
    h2: (font: "sans", size: 14pt, weight: "bold", style: "normal", above: 1.2em, below: 0.4em),
    h3: (font: "sans", size: 11pt, weight: "bold", style: "normal", above: 0.8em, below: 0.2em),
    h4: (font: "serif", size: 10pt, weight: "bold", style: "italic", above: 0.5em, below: 0.1em),
  ),
)
```

Note the heading `above`/`below`: these are *block* spacing, so they replace — not
add to — Typst's default heading gaps. If you're porting from `v(1.2em)` calls inside
show rules, expect to retune by eye; the page count will move.

**Shrink for a 6×9 trade cut, as a preset:**

```typ
presets: (trade: (body: (size: 10pt), note: (size: 8.5pt), caption: (size: 8.5pt),
                  table-body: (size: 8.5pt), toc-pagenums: "flush"))
```

TOC entries follow `body` automatically (`toc.l1.size: auto`, `toc.l2.size: 1em - 1pt`);
`note`, `caption`, `table-body`, `index` are absolute and need setting together if
you want them to shrink in step. That's a deliberate trade — every knob explicit —
not an oversight.

**No small caps anywhere:**

```typ
theme: (chapter-label: (case: none), newthought: (case: none), toc: (group: (case: none)))
```

**Loosen the whole book's rhythm:**

```typ
theme: (body: (leading: 0.9em, spacing: 1.6em), list: (spacing: 1.4em), opener: (drop: 3em))
```

**One margin note in a different face** (override, not the norm):

```typ
#marginnote(theme: (note: (font: "mono")))[a code-ish aside]
```

A helper's `theme:` is a **partial overlay on the ambient theme** — same contract as
`theme:` on the class — so that one-key dict means "the current theme, but the note
font is mono". Passing a full theme works too (it merges to itself).

**Justify body text** (you opted in, so it's one key): `theme: (justify: true)`.
Lists, table cells, and the handout title block stay ragged regardless.

## 9. Extending: using roles in your own show rules

If you write show rules in a book project, style them from the theme instead of
literal values, so a font swap or preset flip reaches your code too. Three exported
primitives:

- `role(theme, "path")` — the role dict (assert if missing).
- `role-args(theme, "path")` — a dict of `text()` named args with the font alias
  resolved and every `auto` key **dropped**, ready to spread: `set text(..role-args(th, "note"))`.
- `styled(theme, "path", body)` — `text(..role-args, cased(body))`; the direct-render form.

Inside a class, use `context` + `current-theme()`:

```typ
#show: book.with(…)

// a custom callout that follows the note role
#let callout(body) = context {
  let th = current-theme()
  block(inset: 0.6em, stroke: 0.5pt + role(th, "body").fill,
    styled(th, "note", body))
}
```

You can also add your own roles: the theme is an open dict, so
`theme: (callout: (font: "sans", size: 9pt, weight: "semibold", style: "normal", tracking: 0em, fill: auto))`
plus `styled(th, "callout", …)` works. Give custom roles all six keys so the shape
stays uniform (nothing enforces it for your keys, but future you will thank you).

If you're extending the *package* (a new region, a new class), the rule is absolute:
no typographic literal outside `themes.typ`. Add a role, give it a default that
reproduces the current look, and consume it via `role-args`/`styled`. The lint will
tell you if you forget.

## 10. Guarantees, tests, and the lint

- `tests/assert/theme.typ` — schema completeness (every role has the six keys),
  deep-merge semantics, alias resolution, `role-args` shape, preset chain.
- `tests/assert/roles-render.typ` — helpers accept body-first / `theme: auto` and
  work with no class installed.
- `tests/assert/ambient.typ` — a `book()` with a custom sans; helpers called without
  `theme:` see it (`current-theme()` asserted inside the doc).
- `tests/lint-hardcoded.sh` — runs in `just test`; greps `src/` (minus `themes.typ`)
  for `size:`/`tracking:`/`above:`/… literals, `weight: "`, `luma(`/`rgb(`, `font: ("`,
  `justify: true`, `v(Nem)`. Any hit fails. `// lint-ok: <reason>` opts out a line
  that is geometry rather than typography (zero insets, printer spec boxes).
- Parity: when the defaults changed shape (flat keys → roles) every default render
  was verified byte-identical against pre-change baselines — line bounding boxes and
  font/size per span via `mutool draw -F stext` — for the book (print and screen),
  the TOC fixture, letter, handout, and cover. Change a default only with the same
  check; the method is in `record/handoffs/`.

## 11. Design notes and non-goals

- **`auto` is a first-class value, not an omission.** A role that says `fill: auto`
  is promising to inherit; a role that says `fill: luma(30)` is promising to set. The
  schema test requires the key either way so the promise is visible.
- **Sizes are mostly absolute on purpose.** Presets that shrink the body should also
  set the roles they want to shrink. Two exceptions are relative because they are
  structurally tied to the body: `toc.l1.size: auto` and `toc.l2.size: 1em - 1pt`,
  and `raw.size: 0.8em` (Typst's own convention). If a future preset pattern makes a
  "scale everything" knob obviously right, it goes in as one more key — not as
  implicit ratios sprinkled through the roles.
- **Colours are inline, not a palette.** `body.fill`, `section-number.fill`,
  `handout.meta.fill`, `watermark.fill` are plain colours. A named palette layer was
  considered and skipped as YAGNI; the theme is an open dict, so a project can add
  one and reference it from its own overlays.
- **No compatibility layer for the old flat keys** (`serif`, `body-size`, `h1-size`,
  …). They were removed in one cut before any external user existed. If you see
  `theme.serif` in a fixture or a book, it's stale: the key is `fonts.serif`.
- **The theme does not know about paper.** Trim, bleed, margins, note-column width
  are `geometry.typ`'s job. Per-trim *type* choices are theme presets that happen to
  be named after a trim.
