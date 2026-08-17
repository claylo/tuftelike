// Chapter/Appendix opener + H2/H3 treatments + part divider page.
// icons: dict mapping keyword -> image content, e.g. ("Quick Try": image(...)).
// A level-3 heading whose text starts with (or contains) a key gets its icon.
//
// Typst imports are file-scoped, not block-scoped — keep them here, never
// inside a show-rule closure.
#import "utils.typ": plain-text
#import "themes.typ": role, role-args, styled, current-theme
#import "labels.typ": current-labels

#let chapter-heading-rules(theme, labels, note-ext, icons: (:), doc) = {
  show heading.where(level: 1): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      let num = counter(heading).display(it.numbering)
      let word = if num.match(regex("^[A-Z]")) != none { labels.appendix } else { labels.chapter }
      // the label word takes the role's case (smallcaps); the number keeps
      // the same font/size but is never cased
      styled(theme, "chapter-label", word)
      text(..role-args(theme, "chapter-label"), [ ] + num.trim("."))
      linebreak()
    }
    #styled(theme, "heading.h1", it.body)
    #v(role(theme, "opener").drop)
  ]
  show heading.where(level: 2): it => block(width: 100% + note-ext)[
    #if it.numbering != none {
      styled(theme, "section-number", counter(heading).display(it.numbering))
      linebreak()
    }
    #it.body
  ]
  show heading.where(level: 3): it => {
    let t = plain-text(it.body)
    // skip empty keys: "".starts-with matches every heading
    let hit = icons.pairs().find(((k, _)) => k != "" and (t.starts-with(k) or t.contains(k)))
    if hit != none {
      let ic = role(theme, "heading.h3-icon")
      grid(columns: (ic.width, auto), gutter: ic.gutter,
        box(height: 1em, hit.last()), it.body)   // lint-ok: icon box is 1 text-line tall by definition
    } else { it.body }
  }
  doc
}

// theme/labels: auto reads the class's stored values (current-theme /
// current-labels) — pass explicitly only to override.
#let part-divider(number, title, theme: auto, labels: auto) = page(header: none, footer: none)[
  #metadata(none) <divider-page>
  #context {
    let th = if theme == auto { current-theme() } else { theme }
    let lb = if labels == auto { current-labels() } else { labels }
    let pd = role(th, "part-divider")
    align(center)[
      #v(pd.top)
      #styled(th, "part-label", [#lb.part #number])
      #v(pd.gap)
      #styled(th, "part-title", title)
    ]
  }
]
