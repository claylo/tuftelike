#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-target
#import "../themes.typ": resolve-theme, role, role-args, styled
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../notes.typ": footnote-transform

// Tufte-memo lineage: title block + author grid replace letter's
// letterhead/salutation, otherwise mirrors classes/letter.typ's skeleton
// verbatim (marginalia setup shape, base-style, footnote-transform order).
#let handout(
  paper: "us-letter", media: auto, target: auto, targets: (:),
  title: none, subtitle: none, authors: (),  // ((name:, role:, affiliation:, email:), …)
  abstract: none, document-number: none, distribution: none,
  footer-content: (none, none),   // (first-page content, rest-page content)
  toc: false, bib: none,
  theme: (:), presets: (:), theme-preset: auto, labels: (:),
  footnotes-as-sidenotes: auto,
  doc,
) = {
  let tg = resolve-target(target: target, targets: targets, media: media, paper: paper,
    theme-preset: theme-preset)
  let media = tg.media
  let paper = tg.paper
  assert("handout-margin" in paper, message: "this class needs a letter-sized paper (us-letter, a4 presets) — \"handout-margin\" missing")
  let theme = resolve-theme(theme, presets: presets, preset: tg.theme-preset)
  let fas = if footnotes-as-sidenotes == auto { paper.note-col > 0mm } else { footnotes-as-sidenotes }
  let labels = resolve-labels(labels)
  let m = paper.handout-margin
  let H = role(theme, "handout")
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
        styled(theme, "handout.footer", content)
      }
    })
  show: base-style.with(theme, labels, paper.note-col + paper.note-gap, media: media)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if fas { footnote-transform(theme, d) } else { d }
  // helpers read this via current-theme()/current-labels()/current-target() — never thread it
  state("tuftelike").update((media: media, paper: paper, theme: theme, labels: labels,
    target: tg.name, binding: "perfect"))

  // title block. Never justified regardless of theme.justify: justified
  // word-spacing stretches the FIRST line whenever a display-size title
  // wraps to two lines — fine for body prose, wrong for a title.
  par(justify: false)[
    #styled(theme, "handout.title", title)
    #if subtitle != none [ \ #styled(theme, "handout.subtitle", subtitle) ]
  ]
  if authors.len() > 0 {
    v(H.after-title)
    grid(columns: (1fr,) * authors.len(), gutter: H.author-gutter,
      ..authors.map(a => text(..role-args(theme, "handout.author"))[
        #styled(theme, "handout.author-name", a.at("name", default: "")) \
        #a.at("role", default: none) #if "role" in a [\ ]
        #a.at("affiliation", default: none) #if "affiliation" in a [\ ]
        #a.at("email", default: none)
      ]))
  }
  if document-number != none or distribution != none {
    v(H.after-authors)
    styled(theme, "handout.meta")[
      #if document-number != none [#document-number \ ]
      #if distribution != none [#labels.distribution: #distribution]
    ]
  }
  if abstract != none {
    v(H.after-meta)
    block(inset: (left: H.abstract-inset, right: H.abstract-inset),
      styled(theme, "handout.abstract", abstract))
  }
  v(H.after-abstract)

  doc

  if toc { outline(title: labels.contents, depth: 2) }
  if bib != none { bib }
}
