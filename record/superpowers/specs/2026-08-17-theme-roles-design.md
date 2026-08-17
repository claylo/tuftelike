# Theme roles, ambient theme, dependency recipes — design

Date: 2026-08-17. Status: approved for planning (option A: clean break, no compat shim).

## Problem

Field use on a second project (an 8×10.5 wiring guide themed away from ETbb/Gill Sans)
exposed three defects in the v0.1.0 theme layer:

1. **Theme is threaded by argument, not ambient.** `sidenote`, `marginnote`, `sidecite`,
   `newthought`, `tufte-quote`, `md`, `part-divider`, `about-author`, `colophon`,
   `book-index`, `instructional-extensions` all take a `theme` and silently fall back to
   hardcoded ETbb/Gill Sans when a caller omits it. The class already stores the resolved
   theme in `state("tuftelike")`; nothing reads it. Result in the field: Gill Sans on
   ~every page of a Times/Helvetica book, ETbb from `newthought(default-theme)`, and our own
   `examples/book/main.typ` documents the trap (`part-divider(default-theme, …)`).
2. **Incomplete knob coverage.** ~40 sites hardcode size/weight/tracking/fill/spacing
   (title page, TOC group headers, chapter label, section numbers, table cells, folio
   tracking, opener drop, part divider, colophon, cover, letter/handout). `theme.mono` is
   declared but never applied — `raw` renders in Typst's fallback.
3. **Justification default.** Body was `justify: true`; the decision is zero justified
   defaults, exposed as a knob.

Plus housekeeping: no way to see or bump Typst package pins (marginalia, cmarker, tiaoma,
in-dexter).

Name stays `tuftelike`.

## Design

### 1. Theme schema: fonts + roles, deep-merged

`default-theme` becomes a nested dict and the single documented record of every knob.

```typ
#let default-theme = (
  fonts: (
    serif: ("ETbb", "ETBembo", "Palatino", "Georgia"),
    sans:  ("Gill Sans MT", "Fira Sans", "Helvetica Neue", "Arial"),
    mono:  ("Consolas", "Menlo", "Monaco"),
  ),
  justify: false,
  screen-bg: rgb("FFFFF8"),
  toc-pagenums: "ragged",
  draft: false,

  // roles — every text site in the package is one of these
  body:  (font: "serif", size: 11pt, weight: "regular", style: "normal", tracking: 0em,
          fill: luma(30), leading: 0.8em, spacing: 1.4em),
  note:  (font: "sans",  size: 9pt, …, leading: 0.5em),
  folio: (font: "serif", size: 8pt, tracking: 0.12em, …),
  raw:   (font: "mono",  size: 0.8em, …),
  heading: (
    h1: (font: "serif", size: 20pt, weight: "regular", style: "italic", …, above: auto, below: auto),
    h2: (… 18pt …), h3: (… 16pt …), h4: (… 14pt …), h5: (… 12pt …),
  ),
  …
)
```

**Role shape.** Every role carries the six text keys `font, size, weight, style, tracking,
fill`. Roles that own vertical rhythm add `above`/`below` (`auto` = leave Typst's default);
paragraph-bearing roles add `leading`/`spacing`; roles that currently apply `upper()` or
`smallcaps()` add `case: "upper" | "smallcaps" | none`.

**Font aliases.** `role.font` is either an alias string (`"serif" | "sans" | "mono"`)
resolved against `theme.fonts`, or an explicit stack (array). Swapping the serif stays one
line; any single role can still diverge. Unknown alias → assert with the alias list.

**Merge.** `resolve-theme` deep-merges dicts (`default-theme` ← preset overlay ← user);
arrays (font stacks) replace wholesale, as today. Chain and preset selection are unchanged.
Overlays may be partial at any depth: `theme: (heading: (h2: (weight: "bold")))` touches
one key.

**Primitives** (themes.typ, exported):

- `role-args(theme, name)` → dict of `text()` named args with the alias resolved and
  `case` stripped, spreadable into `set text(..role-args(theme, "note"))` — this is how
  show/set rules consume roles.
- `styled(theme, name, body)` → `text(..role-args(theme, name), cased(body))` for direct
  rendering.
- `current-theme()` / `current-labels()` → `state("tuftelike").get()` accessors with
  `default-theme`/`default-labels` fallback (for use inside `context`).

**Role inventory** (defaults = today's rendered values, so the Tufte look is unchanged):

| area | roles |
|---|---|
| base | `body`, `note`, `folio`, `raw`, `heading.h1..h5`, `list` (spacing, body-indent) |
| chapter | `chapter-label` (sans 10pt, smallcaps), `section-number` (sans 8pt luma 120), `opener` (`drop: 2.5em`), `part-label` (16pt), `part-title` (24pt), `part-divider` (`top: 6.4em`, `gap: 0.3em`) |
| figures/tables | `caption` (sans, note size, `below: 0.5em`), `table-head` (10pt), `table-body` (note size), `table-rule` (top/bottom/hline weights) |
| front matter | `title-page.author` (sans 16pt tracking 0.2em upper), `.title` (20pt 0.16em upper), `.subtitle` (serif italic 15pt), `.release` (12pt 0.16em upper), `.publisher` (14pt 0.16em upper), `.gap-author-title: 8em`, `.gap-release: 2em`; `copyright` (9pt); `dedication` (italic); `epigraph-attrib` (italic) |
| TOC | `toc.title` (h1 size, italic), `toc.group` (serif semibold 0.16em upper, `above: 1.3em`), `toc.l1` (body size italic, `above: 1.1em`), `toc.l2` (body−1pt), `toc.unnumbered` (italic), `toc.title-gap: 2.1em`, `toc.indent: 2em`, `toc.entry-gap: 1.5em`, `toc.backmatter-gap: 1.2em`, `toc.folio-gap: 8` (nbsp count) |
| back matter | `backmatter-label` (sans 10pt 0.16em upper, `below: 1.5em`), `colophon` (9pt), `index` (note size, columns) |
| notes/quotes | `newthought` (serif smallcaps tracking 0.05em, `above: 1em`), `quote` (inset left 1.5em right 1em, `attrib-gap: 0.3em`) |
| cover | `cover.author` (14pt 0.2em upper), `.title` (26pt 0.12em upper), `.subtitle` (serif italic 14pt), `.release` (10pt 0.16em upper), `.spine` (11pt 0.14em), `.isbn` (mono 7pt), `.stamp` (sans 9pt semibold) |
| letter | `letterhead` (sans 9pt), `re` (semibold), `meta` (9pt), spacing knobs (`after-letterhead: 2em`, `after-date: 1.5em`, `after-to: 1.5em`, `after-re: 1em`, `after-salutation: 0.8em`, `before-closing: 2em`, `before-signature: 0.4em`, `before-enclosures: 1.5em`, `before-cc: 0.3em`) |
| handout | `handout.title` (2.3em), `.subtitle` (italic 1.3em), `.author` (sans 9pt), `.meta` (sans 8pt luma 100), `.abstract` (italic, inset 2em), spacing knobs |
| extras | `prompt` (mono bold 10pt), `response` (serif) |
| draft | `watermark` (sans 96pt luma 85) |

Exact key names are fixed in the plan; the rule is: **no numeric literal, font, weight,
tracking, or fill in `src/` outside `themes.typ`** (see testing).

### 2. Ambient theme and labels

Every content-level helper reads the theme from state unless given one:

```typ
#let sidenote(dy: 0pt, theme: auto, body) = marginalia.note(dy: dy,
  numbering: arabic-note-numbering,
  context {
    let th = if theme == auto { current-theme() } else { theme }
    styled(th, "note", block({ set par(leading: th.note.leading); body }))
  })
```

Applies to: `sidenote`, `marginnote`, `sidecite`, `newthought`, `lead-smallcaps` (no
change), `tufte-quote`, `md`, `chapters`/`appendices` (pass-through), `part-divider`,
`about-author`, `colophon`, `book-index`, `instructional-extensions`. Same for `labels`.

Signatures change to `body` first, `theme: auto, labels: auto` named:
`newthought(body, theme: auto)`, `tufte-quote(body, attribution: none, theme: auto)`,
`part-divider(number, title, theme: auto, labels: auto)`, `about-author(body, …)`,
`colophon(body, …)`, `instructional-extensions(theme: auto)`. Positional theme-first forms
are gone (breaking; v0.1.0 has no external users).

Classes keep resolving and storing the theme in `state("tuftelike")` exactly as today —
that write must precede all content (it already does).

Class-level rules consume roles via `role-args`: `set text(..role-args(theme, "body"))`,
`show raw: set text(..role-args(theme, "raw"))`, `show heading.where(level: n): set
text(..)` + `set block(above:, below:)` when not `auto`, `set par(justify: theme.justify,
…)`, table cell rules, caption rules, folio, etc.

### 3. Dependency recipes

`bin/typst-deps` (bash, `set -euo pipefail`, `--help`):

- `outdated`: scan `src template examples tests` for `@preview/<name>:<ver>`, fetch
  `https://packages.typst.org/preview/index.json`, print `name  pinned  latest  sites`
  and exit 1 if any are behind (CI-friendly).
- `update [name…]`: rewrite every pin site to latest (all names, or the given ones) with
  `sed -i ''`, print the diff summary, then remind that in-dexter is *also* pinned in
  colophon's config (not touched — cross-repo). Caller runs `just test`.

`justfile`: `outdated: bin/typst-deps outdated`, `update: bin/typst-deps update && just test`.

Current pins: marginalia 0.3.1, cmarker 0.1.10, tiaoma 0.3.0, in-dexter 0.7.2. Bumping is a
separate decision after the recipes exist (marginalia/in-dexter bumps may need code changes;
`just test` + visual fixtures are the gate).

## Migration (part of this work)

- `examples/book/themes.typ` (`trade` preset → nested keys), `examples/*/main.typ`,
  `template/main.typ` (drop `default-theme`/`default-labels` args), README theme section
  (rewrite around fonts/roles/aliases/deep-merge; keep the arrays-replace warning), tests.
- `~/source/wiring-guides`: `setup.typ` theme dict → `fonts:` + heading roles (its custom
  h2/h3/h4 show rules can become theme roles), `how-to-use.typ` `newthought(default-theme)`
  → `newthought[…]`, `guide-ext.typ` drops `theme:` plumbing. Rebuild and re-run the
  font-inventory check: no ETbb/GillSans/Hack/Libertinus in `out/guide.pdf`.
- Clay's own book project: theme file path to be supplied; migrate on the same pattern.

## Testing

- `tests/assert/theme.typ` rewritten: schema completeness (every role has the six text
  keys), deep-merge semantics (partial nested overlay, arrays replace), alias resolution
  (+ unknown-alias assert), `role-args` output shape, preset chain unchanged.
- `tests/assert/ambient.typ`: a `book()` with `theme: (fonts: (sans: ("Zzz",)))`; inside the
  doc, `context assert(current-theme().fonts.sans.first() == "Zzz")`, and `sidenote` /
  `newthought` called with no theme compile.
- `tests/lint-hardcoded.sh` (run by `just test`): greps `src/` minus `themes.typ` for
  `size: [0-9.]+(pt|em)`, `tracking:`, `weight: "`, `luma(`, `rgb(`, `justify: true`; any
  hit fails. This is the guard that keeps "every knob in the theme" true going forward.
- Compile matrix + `just proto-check` parity: defaults must render byte-for-byte the same
  look (verify TOC geometry with the existing `mutool` coordinate method on
  `tests/visual/toc-page.typ` before/after).
- Field check: wiring-guides font inventory per page (the `mutool draw -F stext | grep font
  name` loop) shows only Times/Helvetica/mono.

## Out of scope

Shelf-matrix presets, 6×9 re-bake, Universe publication, colophon repo changes.
