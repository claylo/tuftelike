#import "@local/tuftelike:0.1.0": begin-chapters, chapter-break, chapters, appendices, chapter-heading-rules, base-style, footnote-transform, resolve-theme, resolve-labels, resolve-paper, resolve-media, marginalia-config, page-size, folio, about-author, colophon, references, sidecite
#import "@preview/marginalia:0.3.1" as marginalia

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let mc = marginalia-config(paper, media)
#let ps = page-size(paper, media)
#let theme = resolve-theme((:))
#let labels = resolve-labels((:))
#let note-ext = paper.note-col + paper.note-gap
#let reader = (p, ..a) => read(p, ..a.named())

#show: marginalia.setup.with(..mc)
#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none },
  header: folio(theme, note-ext: paper.note-col + paper.note-gap, media: media))
#show: footnote-transform.with(theme)
#show: base-style.with(theme, labels, note-ext)
#show: chapter-heading-rules.with(theme, labels, note-ext)

Front-matter placeholder page, standing in for a title/copyright/TOC
sequence. Exists only so the recto-forcing break below has something to
push off of.

// NOTE: called via #show:, NOT bare `#begin-chapters(media)` — see the
// DEVIATION comment in src/mainmatter.typ. This is the verified-working
// invocation.
#show: begin-chapters.with(media)
#chapter-break(media, "odd")

#chapters(("md/ch1.md", "md/ch2.md"), reader: reader, media: media, split: "odd", theme: theme)

#chapter-break(media, "odd")
#appendices(("md/appx.md",), reader: reader, media: media, theme: theme)

#chapter-break(media, "odd")
#about-author(theme: theme)[
  A short biographical note, exercising `about-author` — this page carries
  `<no-folio>`, so it should show no folio despite being well past the
  main-matter boundary.
]

A closing paragraph that cites a demo source#sidecite(<demo1>, theme: theme)
to verify that `references(bib, hidden: true)` resolves the citation into a
margin note without printing a References section.

#colophon(theme: theme)[
  Set in tuftelike. This page also carries `<no-folio>`.
]

#references(bibliography("refs.bib"), hidden: true)
