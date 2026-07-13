#import "markdown.typ": md

// Marks the front/main boundary for folio logic; starts heading numbering.
// MUST be invoked as `#show: begin-chapters.with(media)` — never called
// bare: a `set` rule inside a plain function call is scoped to that call's
// block and never reaches sibling content (headings stay unnumbered).
// The trailing `doc` param makes the show-chain form work; appendices()'s
// own set-rule still overrides this chain for appendix numbering.
#let begin-chapters(media, doc) = {
  // print: force a recto BEFORE the marker + page-counter reset, so
  // displayed page 1 lands on a physical odd page — keeping displayed
  // parity aligned with the physical recto/verso geometry forever after
  if media == "print" { pagebreak(to: "odd", weak: true) }
  [#metadata(none) <chapters-begin-here>]
  counter(heading).update(0)
  set heading(numbering: "1.1.1")
  counter(page).update(1)
  doc
}

// Recto starts in print via plain pagebreak(to: "odd"). Conditional
// tag-the-filler schemes are BISTABLE under Typst's layout iteration (the
// conditional break shifts the page it queries; the engine converges on
// the no-break state without warning) — probed extensively, don't retry.
// Instead folio() suppresses the page before an opener (prototype-proven
// behavior; see runners.typ).
#let chapter-break(media, split) = {
  if media == "print" and split == "odd" { pagebreak(to: "odd", weak: true) }
  else { pagebreak(weak: true) }
}

// srcs: array of markdown STRINGS (pass reader("…") results) or, with reader:,
// an array of PATHS. Rendered as ONE cmarker pass so labels/footnotes resolve
// across chapter files; breaks are injected as raw-typst between files.
#let chapters(srcs, reader: none, media: "screen", split: "odd", ..md-args) = {
  assert(split in ("odd", "soft"), message: "chapters(): split must be \"odd\" or \"soft\", got " + repr(split))
  // break BEFORE the first chapter too — openers start recto in print
  // (a part-divider or front page otherwise leaves ch1 on a verso)
  chapter-break(media, split)
  let texts = srcs.map(s => if reader != none and s.ends-with(".md") { reader(s) } else { s })
  // same recto-start rule as chapter-break(), inlined as raw-typst because
  // chapter files join into ONE cmarker pass
  let break-md = if media == "print" and split == "odd" {
    "\n\n<!--raw-typst #pagebreak(to: \"odd\", weak: true) -->\n\n"
  } else { "\n\n<!--raw-typst #pagebreak(weak: true) -->\n\n" }
  md(texts.join(break-md), reader: reader, ..md-args.named())
}

// Appendix mode: letters, own counter, Appendix label auto-detected by chapter.typ.
// Leads with its own break so the first appendix starts on a fresh page
// (recto in print) instead of mid-page after the last chapter's prose.
#let appendices(srcs, reader: none, media: "screen", ..md-args) = {
  chapter-break(media, "odd")
  counter(heading).update(0)
  set heading(numbering: "A.1")
  chapters(srcs, reader: reader, media: media, split: "odd", ..md-args.named())
}
