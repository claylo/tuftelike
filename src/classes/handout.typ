#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-media, resolve-paper
#import "../themes.typ": resolve-theme
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../notes.typ": footnote-transform

// Tufte-memo lineage: title block + author grid replace letter's
// letterhead/salutation, otherwise mirrors classes/letter.typ's skeleton
// verbatim (marginalia setup shape, base-style, footnote-transform order).
#let handout(
  paper: "us-letter", media: auto,
  title: none, subtitle: none, authors: (),  // ((name:, role:, affiliation:, email:), …)
  abstract: none, document-number: none, distribution: none,
  footer-content: (none, none),   // (first-page content, rest-page content)
  toc: false, bib: none,
  theme: (:), presets: (:), theme-preset: auto, labels: (:),
  footnotes-as-sidenotes: true,
  doc,
) = {
  let media = resolve-media(media: media)
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme, presets: presets, preset: theme-preset)
  let labels = resolve-labels(labels)
  let m = paper.handout-margin
  // note column occupies the wide right margin; handouts are one-sided —
  // same shape as letter.typ's marginalia setup, handout-margin instead
  // of letter-margin.
  show: marginalia.setup.with(
    inner: (far: m.left, width: 0mm, sep: 0mm),
    outer: (far: m.right - paper.note-col - paper.note-gap, width: paper.note-col, sep: paper.note-gap),
    top: m.top, bottom: m.bottom, book: false)
  set page(width: paper.trim.w, height: paper.trim.h,
    fill: if media == "screen" { theme.screen-bg } else { none },
    footer: context {
      let content = if counter(page).get().first() == 1 {
        footer-content.at(0, default: none)
      } else {
        footer-content.at(1, default: none)
      }
      if content != none {
        text(font: theme.sans, size: theme.folio-size, content)
      }
    })
  show: base-style.with(theme, labels, paper.note-col + paper.note-gap, media: media)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if footnotes-as-sidenotes { footnote-transform(theme, d) } else { d }

  // title block. Un-justified: base-style's document-wide justify:true
  // stretches word-spacing on the FIRST line whenever a display-size
  // title wraps to two lines — fine for body prose, wrong for a title.
  par(justify: false)[
    #text(font: theme.serif, weight: "regular", size: 2.3em, title)
    #if subtitle != none [ \ #text(font: theme.serif, style: "italic", size: 1.3em, subtitle) ]
  ]
  if authors.len() > 0 {
    v(1em)
    grid(columns: (1fr,) * authors.len(), gutter: 1.5em,
      ..authors.map(a => text(font: theme.sans, size: 9pt)[
        #text(weight: "semibold", a.at("name", default: "")) \
        #a.at("role", default: none) #if "role" in a [\ ]
        #a.at("affiliation", default: none) #if "affiliation" in a [\ ]
        #a.at("email", default: none)
      ]))
  }
  if document-number != none or distribution != none {
    v(0.6em)
    text(font: theme.sans, size: 8pt, fill: luma(100))[
      #if document-number != none [#document-number \ ]
      #if distribution != none [#labels.distribution: #distribution]
    ]
  }
  if abstract != none {
    v(1.2em)
    block(inset: (left: 2em, right: 2em))[
      #text(style: "italic", abstract)
    ]
  }
  v(1.5em)

  doc

  if toc { outline(title: labels.contents, depth: 2) }
  if bib != none { bib }
}
