#import "@preview/cmarker:0.1.10" as cmarker
// VERSION PIN: keep in-dexter in lockstep with backmatter.typ and with
// colophon's configured emit version.
#import "@preview/in-dexter:0.7.2": index, index-main
#import "notes.typ": sidenote, marginnote, notefigure, wideblock
#import "typography.typ": tufte-quote
#import "breaks.typ": chapter-break

// Renders CommonMark with the tuftelike scope pre-wired.
// `reader` MUST be created in the USER's file so paths resolve there:
//     #let reader = (p, ..a) => read(p, ..a.named())
// Images load as bytes through it; <note src="…"> reads through it too.
#let md(
  src,                        // markdown string (pass reader("file.md") to read a file)
  reader: none,
  content-root: "",           // prefix applied to relative image/src paths
  theme: auto,                // auto = the class's stored theme (current-theme())
  extensions: (:),            // extra html tag handlers, merged over defaults
  label-prefix: "",
) = {
  // NOTE: footnote→sidenote transform intentionally NOT here — it is
  // ordering-sensitive and lives at class level (notes.typ footnote-transform).
  let path-of(p) = if content-root == "" { p } else { content-root + "/" + p }
  let render-file(p) = md(reader(path-of(p)), reader: reader,
    content-root: content-root, theme: theme, extensions: extensions,
    label-prefix: label-prefix)

  // Numbering follows ANCHORING (Tufte's own practice: unnumbered margin
  // notes are the workhorse; numbered sidenotes only where a precise
  // in-text anchor matters). Markdown footnotes [^1] are anchored by
  // definition → numbered (see footnote-transform). <note> is floating
  // commentary → unnumbered, unless the author opts in: <note numbered>.
  let html-handlers = (
    note: (attrs, body) => {
      let pick = if "numbered" in attrs { sidenote } else { marginnote }
      if "src" in attrs { pick(theme: theme, render-file(attrs.src)) }
      else { pick(theme: theme, body) }
    },
    margin: (attrs, body) => marginnote(theme: theme, body),
    wide: (attrs, body) => wideblock(body),
  ) + extensions

  let out = cmarker.render(
    src,
    html: html-handlers,
    heading-labels: "github",
    label-prefix: label-prefix,
    blockquote: body => tufte-quote(body, theme: theme),
    scope: (
      // forwards width/height/fit etc. so raw-typst image calls can size
      image: (path, alt: none, ..args) => image(bytes(reader(path-of(path), encoding: none)), alt: alt, ..args.named()),
      sidenote: body => sidenote(theme: theme, body),
      marginnote: body => marginnote(theme: theme, body),
      notefigure: notefigure,   // margin figures from raw-typst blocks
      chapter-break: chapter-break, // injected between chapter files by chapters()
      index: index,             // in-dexter markers from raw-typst blocks
      index-main: index-main,   // (colophon's render stage emits these)
    ),
  )

  // Bare index markers as plain markdown text (flat bracket form only —
  // hierarchical #index("parent", "child") needs a raw-typst block, where
  // the scoped functions above handle it). Lets colophon annotate .md
  // sources directly. -main matched first: it contains the plain prefix.
  let index-match = regex("#index(-main)?\\[((?s).*?)\\]")
  show index-match: it => {
    let m = it.text.matches(index-match).first()
    if m.captures.at(0) != none { index-main(m.captures.at(1)) }
    else { index(m.captures.at(1)) }
  }

  // Continuity tier: legacy #note[...] regex + ```note fences, from the prototype era.
  // Legacy tier renders UNNUMBERED (marginnote): the prototype book's
  // notes carried no markers, and this tier exists to reproduce that
  // content faithfully. The footnote and <note> tiers stay numbered.
  let note-match = regex("#note\\[((?s).*?)\\]")
  show note-match: it => {
    let arg = it.text.matches(note-match).first().captures.at(0)
    if arg.ends-with(".md") { marginnote(theme: theme, render-file(arg)) }
    else { marginnote(theme: theme, cmarker.render(arg)) }
  }
  show raw.where(lang: "note"): it => marginnote(theme: theme, it.text.trim())

  out
}
