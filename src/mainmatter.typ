#import "markdown.typ": md
#import "breaks.typ": chapter-break
#import "geometry.typ": current-media

// Marks the front/main boundary for folio logic; starts heading numbering.
// MUST be invoked as `#show: begin-chapters` — never called bare: a `set`
// rule inside a plain function call is scoped to that call's block and
// never reaches sibling content (headings stay unnumbered). The trailing
// `doc` param makes the show-chain form work; appendices()'s own set-rule
// still overrides this chain for appendix numbering.
// media: auto reads the build target (current-media()); pass explicitly
// only outside a class.
#let begin-chapters(doc, media: auto) = {
  // print: force a recto BEFORE the marker + page-counter reset, so
  // displayed page 1 lands on a physical odd page — keeping displayed
  // parity aligned with the physical recto/verso geometry forever after
  let go(m) = if m == "print" { pagebreak(to: "odd", weak: true) }
  if media == auto { context go(current-media()) } else { go(media) }
  [#metadata(none) <chapters-begin-here>]
  counter(heading).update(0)
  set heading(numbering: "1.1.1")
  counter(page).update(1)
  doc
}

// srcs: array of markdown STRINGS (pass reader("…") results) or, with reader:,
// an array of PATHS. Rendered as ONE cmarker pass so labels/footnotes resolve
// across chapter files; breaks are injected as raw-typst between files and
// read the target's media themselves (chapter-break is in md's scope).
#let chapters(srcs, reader: none, split: "odd", ..md-args) = {
  assert(split in ("odd", "soft"), message: "chapters(): split must be \"odd\" or \"soft\", got " + repr(split))
  // break BEFORE the first chapter too — openers start recto in print
  // (a part-divider or front page otherwise leaves ch1 on a verso)
  chapter-break(split)
  let texts = srcs.map(s => if reader != none and s.ends-with(".md") { reader(s) } else { s })
  let break-md = "\n\n<!--raw-typst #chapter-break(\"" + split + "\") -->\n\n"
  md(texts.join(break-md), reader: reader, ..md-args.named())
}

// Appendix mode: letters, own counter, Appendix label auto-detected by chapter.typ.
// Leads with its own break so the first appendix starts on a fresh page
// (recto in print) instead of mid-page after the last chapter's prose.
#let appendices(srcs, reader: none, ..md-args) = {
  chapter-break("odd")
  counter(heading).update(0)
  set heading(numbering: "A.1")
  chapters(srcs, reader: reader, split: "odd", ..md-args.named())
}
