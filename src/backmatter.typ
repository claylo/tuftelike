// About-the-author / colophon pages + bibliography wiring.
#import "labels.typ": default-labels, current-labels
#import "themes.typ": role, role-args, styled, current-theme

// Outlined-but-invisible heading: registers the page with the TOC and the
// PDF bookmarks without disturbing the page's own display typography. The
// element survives `show heading: none` for introspection — same mechanism
// references() uses to resolve citations under `show bibliography: none`.
#let toc-entry(title) = {
  show heading: none
  heading(level: 1, numbering: none, title)
}

// theme/labels: auto reads the class's stored values inside context; pass
// explicitly only to override.
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
#let book-index(theme: auto, labels: auto, columns: 2) = resolve-ambient(theme, labels, (th, lb) => {
  import "@preview/in-dexter:0.7.2" as in-dexter
  set text(..role-args(th, "index"))
  set par(justify: false)
  heading(level: 1, numbering: none, lb.index)
  // use-page-counter: entries must cite the book's DISPLAYED folios (the
  // counter resets at begin-chapters), not physical page indices
  std.columns(columns, in-dexter.make-index(title: none, outlined: false, use-page-counter: true))
})
