#import "utils.typ": plain-text, lead-split

#let newthought(theme, body) = {
  v(1em, weak: true)
  text(font: theme.serif, tracking: 0.05em, smallcaps(plain-text(body)))
}

#let lead-smallcaps(body) = {
  let (head, tail) = lead-split(plain-text(body))
  [#smallcaps(head)#tail]
}

// Tufte blockquote: indented, no bar, roomy. Attributed variant for epigraphs.
#let tufte-quote(theme, body, attribution: none) = block(inset: (left: 1.5em, right: 1em))[
  #body
  #if attribution != none [ #v(0.3em) #align(right, text(style: "italic", [— #attribution])) ]
]

// Applies document-wide text + heading + list + figure/table rules.
// `note-ext` = how far captions/tables extend into the note column.
// `media` drives the print-only parity behaviors (caption/table alignment
// flips to the outer edge on versos; tables become unbreakable).
// Paragraph, list, caption, and table metrics are the prototype book's
// print-proven values, ported verbatim.
#let base-style(theme, labels, note-ext, media: "screen", doc) = {
  set text(font: theme.serif, size: theme.body-size, fill: theme.text-fill)
  set par(justify: true, leading: theme.body-leading, spacing: theme.par-spacing)
  set list(body-indent: 1em, spacing: 1.2em)
  set enum(body-indent: 1em, spacing: 1.2em)
  show list: set par(justify: false)
  show heading: set text(font: theme.serif, weight: "regular", style: "italic")
  // level 1 needs an explicit size: the base show-heading override suppresses
  // Typst's built-in heading scaling (measured h1 at 9.92pt without this —
  // smaller than h3). chapter.typ replaces level-1 rendering for books.
  show heading.where(level: 1): set text(size: theme.h1-size)
  show heading.where(level: 2): set text(size: theme.h2-size)
  show heading.where(level: 3): set text(size: theme.h3-size)
  show heading.where(level: 4): set text(size: theme.h4-size)
  show heading.where(level: 5): set text(size: theme.h5-size)
  set heading(numbering: none) // mainmatter turns numbering on

  // Captions: sans, "Supplement N." on its own sticky line, body below,
  // extending into the note column; on print versos the whole block sets
  // flush to the outer (left) edge.
  show figure.caption: it => context {
    let outer = if media == "print" and calc.even(here().page()) { right } else { left }
    align(outer, block(width: 100% + note-ext, inset: 0mm, sticky: true,
      align(left, {
        block(below: 0.5em, sticky: true,
          text(font: theme.sans, size: theme.note-size,
            [#it.supplement #context it.counter.display(it.numbering).]))
        text(font: theme.sans, size: theme.note-size, it.body)
      })))
  }

  // Tables: caption on top, minimal strokes (header rule pair only; authors
  // close with table.hline), 10pt header / 9pt body cells, full width into
  // the note column, unbreakable in print, verso-flush in print.
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(supplement: labels.table, numbering: "1")
  show figure.where(kind: table): set block(breakable: media != "print")
  show figure.where(kind: table): it => context {
    let outer = if media == "print" and calc.even(here().page()) { right } else { left }
    align(outer, it)
  }
  show figure.where(kind: image): set figure(supplement: labels.figure, numbering: "1")
  show figure.where(kind: raw): set figure.caption(position: top)
  show figure.where(kind: raw): set figure(supplement: labels.code, numbering: "1")
  show table.cell: set par(justify: false)   // shipped book's cells are ragged-right
  show table.cell: it => {
    set text(size: 10pt, weight: "regular") if it.y == 0
    set text(size: theme.note-size, weight: "regular") if it.y > 0
    set align(left)
    it
  }
  set table(stroke: (_, y) => if y == 0 { (top: 1pt + theme.text-fill, bottom: 0.3pt + theme.text-fill) })
  set table.hline(stroke: 0.7pt + theme.text-fill)
  show table: t => block(width: 100% + note-ext, inset: 0mm, t)

  show quote.where(block: true): it => tufte-quote(theme, it.body,
    attribution: it.attribution)
  if theme.draft {
    set page(foreground: rotate(-55deg,
      text(size: 96pt, fill: luma(85), font: theme.sans, labels.draft)))
    doc
  } else { doc }
}
