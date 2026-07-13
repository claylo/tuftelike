// About-the-author / colophon pages + bibliography wiring.
#let about-author(theme, body) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #text(font: theme.sans, size: 10pt, tracking: 0.16em, upper("About the Author"))
  #v(1.5em)
  #body
]

#let colophon(theme, body) = page(header: none, footer: none)[
  #metadata(none) <no-folio>
  #set text(size: 9pt)
  #align(center + bottom, body)
]

// Renders the bibliography; hidden: true resolves citations (sidecite!) without
// printing a references section.
#let references(bib, hidden: false) = {
  if hidden { show bibliography: none; bib } else { bib }
}
