#import "utils.typ": plain-text, lead-split
#import "themes.typ": role, role-args, styled, cased, current-theme, with-theme

#let newthought(body, theme: auto) = with-theme(theme, th => {
  v(role(th, "newthought").above, weak: true)
  styled(th, "newthought", plain-text(body))
})

#let lead-smallcaps(body) = {
  let (head, tail) = lead-split(plain-text(body))
  [#smallcaps(head)#tail]
}

// Tufte blockquote: indented, no bar, roomy. Attributed variant for epigraphs.
#let tufte-quote(body, attribution: none, theme: auto) = with-theme(theme, th => {
  let q = role(th, "quote")
  block(inset: (left: q.inset-left, right: q.inset-right))[
    #body
    #if attribution != none [ #v(q.attrib-gap) #align(right, styled(th, "epigraph-attrib", [— #attribution])) ]
  ]
})

// Applies document-wide text + heading + list + figure/table rules.
// `note-ext` = how far captions/tables extend into the note column.
// `media` drives the print-only parity behaviors (caption/table alignment
// flips to the outer edge on versos; tables become unbreakable).
// Every metric comes from the theme roles; the defaults are the prototype
// book's print-proven values.
#let base-style(theme, labels, note-ext, media: "screen", doc) = {
  let body = role(theme, "body")
  set text(..role-args(theme, "body"), hyphenate: body.hyphenate)
  set par(justify: theme.justify, leading: body.leading, spacing: body.spacing,
    first-line-indent: (amount: body.first-line-indent, all: true))
  set list(body-indent: theme.list.body-indent, spacing: theme.list.spacing)
  set enum(body-indent: theme.list.body-indent, spacing: theme.list.spacing)
  show list: set par(justify: false)
  show raw: set text(..role-args(theme, "raw"))
  // level 1 needs an explicit size: a show-heading text override suppresses
  // Typst's built-in heading scaling (measured h1 at 9.92pt without this —
  // smaller than h3). chapter.typ replaces level-1 rendering for books and
  // re-applies the role via styled().
  show heading.where(level: 1): set text(..role-args(theme, "heading.h1"))
  show heading.where(level: 2): set text(..role-args(theme, "heading.h2"))
  show heading.where(level: 3): set text(..role-args(theme, "heading.h3"))
  show heading.where(level: 4): set text(..role-args(theme, "heading.h4"))
  show heading.where(level: 5): set text(..role-args(theme, "heading.h5"))
  // above/below: only applied when the role sets them — auto leaves Typst's
  // own heading spacing intact (a set block(above: auto) would REPLACE it
  // with the generic block default; parity-checked)
  show heading.where(level: 1): set block(above: theme.heading.h1.above) if theme.heading.h1.above != auto
  show heading.where(level: 1): set block(below: theme.heading.h1.below) if theme.heading.h1.below != auto
  show heading.where(level: 2): set block(above: theme.heading.h2.above) if theme.heading.h2.above != auto
  show heading.where(level: 2): set block(below: theme.heading.h2.below) if theme.heading.h2.below != auto
  show heading.where(level: 3): set block(above: theme.heading.h3.above) if theme.heading.h3.above != auto
  show heading.where(level: 3): set block(below: theme.heading.h3.below) if theme.heading.h3.below != auto
  show heading.where(level: 4): set block(above: theme.heading.h4.above) if theme.heading.h4.above != auto
  show heading.where(level: 4): set block(below: theme.heading.h4.below) if theme.heading.h4.below != auto
  show heading.where(level: 5): set block(above: theme.heading.h5.above) if theme.heading.h5.above != auto
  show heading.where(level: 5): set block(below: theme.heading.h5.below) if theme.heading.h5.below != auto
  // case: wrap the whole heading in upper()/smallcaps() — the element renders
  // normally inside (this rule is outermost, so `it` does not re-enter it).
  // Book classes replace h1–h3 rendering in chapter.typ and apply case there.
  show heading: it => cased(theme.heading.at("h" + str(it.level), default: (:)), it)
  set heading(numbering: none) // mainmatter turns numbering on

  // Captions: "Supplement N." on its own sticky line, body below,
  // extending into the note column; on print versos the whole block sets
  // flush to the outer (left) edge.
  show figure.caption: it => context {
    let outer = if media == "print" and calc.even(here().page()) { right } else { left }
    align(outer, block(width: 100% + note-ext, inset: 0mm, sticky: true,   // lint-ok: zero inset is geometry
      align(left, {
        block(below: role(theme, "caption").below, sticky: true,
          styled(theme, "caption", [#it.supplement #context it.counter.display(it.numbering).]))
        styled(theme, "caption", it.body)
      })))
  }

  // Tables: caption on top, minimal strokes (header rule pair only; authors
  // close with table.hline), themed head/body cells, full width into the
  // note column, unbreakable in print, verso-flush in print.
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
  show table.cell: set par(justify: false)   // prototype book's cells are ragged-right
  show table.cell: it => {
    set text(..role-args(theme, "table-head")) if it.y == 0
    set text(..role-args(theme, "table-body")) if it.y > 0
    set align(left)
    it
  }
  let rule = theme.table-rule
  set table(stroke: (_, y) => if y == 0 { (top: rule.top + body.fill, bottom: rule.bottom + body.fill) })
  set table.hline(stroke: rule.hline + body.fill)
  show table: t => block(width: 100% + note-ext, inset: 0mm, t)   // lint-ok: zero inset is geometry

  show quote.where(block: true): it => tufte-quote(it.body, attribution: it.attribution, theme: theme)
  if theme.draft {
    set page(foreground: rotate(-55deg, styled(theme, "watermark", labels.draft)))
    doc
  } else { doc }
}
