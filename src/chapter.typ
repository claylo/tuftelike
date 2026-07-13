// Chapter/Appendix opener + H2/H3 treatments + part divider page.
// icons: dict mapping keyword -> image content, e.g. ("Quick Try": image(...)).
// A level-3 heading whose text starts with (or contains) a key gets its icon.
//
// DEVIATION from plan: `import "utils.typ": plain-text` moved here to file
// scope. Typst imports are file-scoped, not block-scoped — the plan's draft
// had the import statement INSIDE the level-3 show-rule closure, which
// would re-run the import on every heading match (harmless but wasteful)
// and reads as if it were closure-local, which Typst imports never are.
#import "utils.typ": plain-text

#let chapter-heading-rules(theme, labels, note-ext, icons: (:), doc) = {
  show heading.where(level: 1): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      let num = counter(heading).display(it.numbering)
      let word = if num.match(regex("^[A-Z]")) != none { labels.appendix } else { labels.chapter }
      text(font: theme.sans, size: 10pt, style: "normal",
        [#smallcaps(word) #num.trim(".")])
      linebreak()
    }
    #text(size: theme.h1-size, style: "italic", it.body)
    #v(2.5em)
  ]
  show heading.where(level: 2): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      text(font: theme.sans, size: 8pt, fill: luma(120),
        counter(heading).display(it.numbering))
      linebreak()
    }
    #it.body
  ]
  show heading.where(level: 3): it => {
    let t = plain-text(it.body)
    // skip empty keys: "".starts-with matches every heading
    let hit = icons.pairs().find(((k, _)) => k != "" and (t.starts-with(k) or t.contains(k)))
    if hit != none {
      grid(columns: (1.5em, auto), gutter: 0.5em,
        box(height: 1em, hit.last()), it.body)
    } else { it.body }
  }
  doc
}

#let part-divider(theme, labels, number, title) = page(header: none, footer: none)[
  #metadata(none) <divider-page>
  #align(center)[
    #v(6.4em)
    #text(size: 16pt, font: theme.serif, [#labels.part #number])
    #v(0.3em)
    #text(size: 24pt, font: theme.serif, title)
  ]
]
