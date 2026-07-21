// About-the-author / colophon pages + bibliography wiring.
#import "labels.typ": default-labels

// Outlined-but-invisible heading: registers the page with the TOC and the
// PDF bookmarks without disturbing the page's own display typography. The
// element survives `show heading: none` for introspection — same mechanism
// references() uses to resolve citations under `show bibliography: none`.
#let toc-entry(title) = {
  show heading: none
  heading(level: 1, numbering: none, title)
}

#let about-author(theme, body, labels: default-labels) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #toc-entry(labels.about-author)
  #text(font: theme.sans, size: 10pt, tracking: 0.16em, upper(labels.about-author))
  #v(1.5em)
  #body
]

#let colophon(theme, body, labels: default-labels) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #toc-entry(labels.colophon)
  #set text(size: 9pt)
  #align(center + bottom, body)
]

// Renders the bibliography; hidden: true resolves citations (sidecite!) without
// printing a references section.
#let references(bib, hidden: false) = {
  if hidden { show bibliography: none; bib } else { bib }
}

// Back-of-book index over in-dexter markers (#index[…] / #index-main[…]).
// VERSION PIN: 0.7.2 must match the version colophon is configured to
// emit in its import line (colophon-side config value) — Typst imports
// are compile-time strings, so the template pins exactly.
// Substantive entries (index-main) render bold per in-dexter's fmt.
#let book-index(theme: (:), labels: (:), columns: 2) = {
  import "@preview/in-dexter:0.7.2" as in-dexter
  set text(size: theme.at("note-size", default: 9pt))
  set par(justify: false)
  heading(level: 1, numbering: none, labels.at("index", default: "Index"))
  // use-page-counter: entries must cite the book's DISPLAYED folios (the
  // counter resets at begin-chapters), not physical page indices
  std.columns(columns, in-dexter.make-index(title: none, outlined: false, use-page-counter: true))
}
