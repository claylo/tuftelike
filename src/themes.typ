// Resolution chain everywhere: explicit arg > theme dict > these defaults.
#let default-theme = (
  serif: ("ETbb", "ETBembo", "Palatino", "Georgia"),
  sans: ("Gill Sans MT", "Fira Sans", "Helvetica Neue", "Arial"),
  mono: ("Consolas", "Menlo", "Monaco"),
  body-size: 11pt, note-size: 9pt, folio-size: 8pt,
  body-leading: 0.8em, par-spacing: 1.4em,   // prototype book's print-proven metrics
  h1-size: 20pt, h2-size: 18pt, h3-size: 16pt, h4-size: 14pt, h5-size: 12pt,
  text-fill: luma(30),
  screen-bg: rgb("FFFFF8"),
  note-leading: 0.5em,
  // TOC folio placement: "ragged" = page number follows the title after a
  // fixed gap (prototype-proven Tufte contents); "flush" = pushed to the
  // right edge of the entry line
  toc-pagenums: "ragged",
  draft: false,
)
// Shallow merge, right side wins. Arrays REPLACE wholesale: overriding serif
// with ("MyFont",) drops the fallbacks — pass the full stack you want.
#let resolve-theme(user) = default-theme + user
