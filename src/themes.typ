// Theme = fonts + roles. Every text site in the package is a named role
// with the same six text keys (text-keys); `auto` on any key means
// "inherit from the surrounding text". Roles that own vertical rhythm add
// above/below (auto = Typst default) or named gap keys; roles that
// transform case add case: "upper" | "smallcaps" | none.
//
// Resolution chain: explicit theme: dict > selected preset overlay > these
// defaults, DEEP-merged (dicts merge at every level; arrays — font stacks —
// replace wholesale). Preset SELECTION: preset: arg > --input theme=<name>
// > none (same pattern as media).
//
// Font aliases: a role's `font` is either "serif" | "sans" | "mono"
// (resolved against theme.fonts) or an explicit stack — swapping the serif
// is one line, any single role can still diverge.
//
// This dict is the COMPLETE record of every knob. Defaults ARE the
// print-proven Tufte look; change a value here only with a parity check
// against the baseline renders (tests/lint-hardcoded.sh keeps every
// typographic literal out of the rest of src/).
#let text-keys = ("font", "size", "weight", "style", "tracking", "fill")

// terse role literal — every role gets the six keys, extras ride along
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
  // TOC folio placement: "ragged" = page number follows the title after a
  // fixed gap (prototype-proven Tufte contents); "flush" = pushed to the
  // right edge of the entry line
  toc-pagenums: "ragged",
  draft: false,

  // ── base text (typography.typ base-style) ──
  // first-line-indent + spacing pick the paragraph style: Tufte = spaced
  // paragraphs (0em indent, 1.4em spacing); manual/trade = indented
  // (1em indent, 0em spacing). The indent applies to EVERY paragraph,
  // including the first after a heading (Typst first-line-indent all: true).
  // hyphenate: auto = Typst default (hyphenate only when justified); true
  // gives ragged text with hyphens (Tufte's own books) — recommended for
  // narrow note columns
  body: r(font: "serif", size: 11pt, weight: "regular", style: "normal", tracking: 0em,
    fill: luma(30), leading: 0.8em, spacing: 1.4em, first-line-indent: 0em, hyphenate: auto),   // prototype's print-proven metrics
  note: r(font: "sans", size: 9pt, leading: 0.5em, hyphenate: auto),
  folio: r(font: "serif", size: 8pt, weight: "regular", style: "normal", tracking: 0.12em),
  raw: r(font: "mono", size: 0.8em),
  list: (spacing: 1.2em, body-indent: 1em),
  // case: none | "upper" | "smallcaps" transforms the rendered heading only —
  // TOC entries and PDF bookmarks keep the original text
  heading: (
    h1: r(font: "serif", size: 20pt, weight: "regular", style: "italic", above: auto, below: auto, case: none),
    h2: r(font: "serif", size: 18pt, weight: "regular", style: "italic", above: auto, below: auto, case: none),
    h3: r(font: "serif", size: 16pt, weight: "regular", style: "italic", above: auto, below: auto, case: none),
    h4: r(font: "serif", size: 14pt, weight: "regular", style: "italic", above: auto, below: auto, case: none),
    h5: r(font: "serif", size: 12pt, weight: "regular", style: "italic", above: auto, below: auto, case: none),
    h3-icon: (width: 1.5em, gutter: 0.5em),   // chapter.typ keyword→icon grid
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
  epigraph-gap: 2em,
  // ── front matter (frontmatter.typ) ──
  title-page: (
    author: r(font: "sans", size: 16pt, tracking: 0.2em, case: "upper"),
    title: r(font: "sans", size: 20pt, tracking: 0.16em, case: "upper"),
    subtitle: r(font: "serif", size: 15pt, style: "italic"),
    release: r(font: "sans", size: 12pt, tracking: 0.16em, case: "upper"),
    publisher: r(font: "sans", size: 14pt, tracking: 0.16em, case: "upper"),
    gap-author-title: 8em, gap-release: 2em,
  ),
  copyright: r(size: 9pt, gap: 0.5em, publisher-gap: 1em),
  dedication: r(style: "italic", gap: 1.5em, attrib-gap: 0.2em, group-gap: 2em),
  toc: (
    title: r(size: 20pt, style: "italic"),
    group: r(font: "serif", weight: "semibold", tracking: 0.16em, case: "upper", above: 1.3em),
    // entry sizes follow the BODY size (auto = inherit; 1em - 1pt = one
    // point smaller than whatever the body is) so a body-size preset
    // reshapes the contents page too
    l1: r(font: "serif", size: auto, style: "italic", above: 1.1em),
    l2: r(font: "serif", size: 1em - 1pt, style: "normal"),
    prefix: r(font: "serif", style: "normal"),
    unnumbered: r(font: "serif", style: "italic"),
    title-gap: 2.1em, indent: 2em, entry-gap: 1.5em, backmatter-gap: 1.2em,
    folio-gap: 8,   // count of no-break spaces between title and folio (ragged mode)
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
  prompt: r(font: "mono", size: 10pt, weight: "bold", inset: (left: 1em)),
  response: r(font: "serif", inset: (left: 1em, right: 1em)),
  watermark: r(font: "sans", size: 96pt, fill: luma(85)),
)

// Named preset overlays, applied between default-theme and the user dict.
// The defaults ARE beautiful-evidence, so its overlay is empty — selecting
// it by name is always valid and always means "the Tufte defaults". Shelf-
// matrix presets (v0.2) land here as sibling overlays.
// Per-tier type presets (geometry stays in geometry.typ; per-trim TYPE lives
// here — decided 2026-08-17). Every tier-2/3 paper name is registered as an
// alias to its tier preset, so --input theme=kdp-6x9 and --input theme=tier2
// mean the same thing; papers also RECOMMEND their preset (theme-preset:
// auto on a class falls through to the paper's pick).
#import "geometry.typ": papers
#let tier2 = (body: (size: 10pt), note: (size: 8.5pt), caption: (size: 8.5pt),
  table-body: (size: 8.5pt), index: (size: 8.5pt))
#let tier3 = (body: (size: 10pt), caption: (size: 8.5pt), table-body: (size: 8.5pt))
#let tier3-small = (body: (size: 9pt), caption: (size: 8pt), table-body: (size: 8pt), table-head: (size: 9pt))  // pocket trims
#let theme-presets = {
  let d = ("beautiful-evidence": (:), tier2: tier2, tier3: tier3, "tier3-small": tier3-small)
  for (name, p) in papers {
    let tp = p.at("theme-preset", default: none)
    if tp != none { d.insert(name, d.at(tp)) }
  }
  d
}

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

// user: unconditional overrides — they apply under EVERY preset.
// presets: caller-defined named overlays merged over the built-ins, so a
//   book can declare its own variants and flip them at compile time
//   (--input theme=<name>) without editing source.
// preset: auto reads --input theme=<name>; a string forces; none disables.
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
// `set text(..role-args(..))` inherits whatever the role leaves auto —
// text(fill: auto) would be a type error)
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

// Ambient accessor — classes write (media, paper, theme, labels, parts)
// into state("tuftelike") before any content; helpers read it inside
// `context` so callers never thread theme by hand. Falls back to the
// defaults when no class is installed (fixtures, bare tests).
#let current-theme() = {
  let s = state("tuftelike").get()
  if s == none { default-theme } else { s.at("theme", default: default-theme) }
}

// Helper-level `theme:` semantics: auto = the ambient theme; a dict is a
// PARTIAL overlay deep-merged over it (a full theme merges to itself). Same
// contract as `theme:` on the classes. Call inside context.
#let with-theme(theme, f) = if theme == auto { context f(current-theme()) } else {
  context f(deep-merge(current-theme(), theme))
}
