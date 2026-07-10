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

// Applies document-wide text + heading + list + figure-caption rules.
// `note-ext` = how far captions/openers extend into the note column.
#let base-style(theme, labels, note-ext, doc) = {
  set text(font: theme.serif, size: theme.body-size, fill: theme.text-fill)
  set par(justify: true, leading: 0.65em)
  set list(indent: 0.05em, spacing: 0.65em, body-indent: 0.7em)
  set enum(indent: 0.05em, spacing: 0.65em, body-indent: 0.7em)
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
  show figure.caption: it => block(width: 100% + note-ext)[
    #text(font: theme.sans, size: theme.note-size)[
      #it.supplement #context it.counter.display(it.numbering)#linebreak()#it.body]
  ]
  show quote.where(block: true): it => tufte-quote(theme, it.body,
    attribution: it.attribution)
  if theme.draft {
    set page(foreground: rotate(-55deg,
      text(size: 96pt, fill: luma(85), font: theme.sans, labels.draft)))
    doc
  } else { doc }
}
