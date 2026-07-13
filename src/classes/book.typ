#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-media, resolve-paper, page-size, marginalia-config
#import "../themes.typ": resolve-theme
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../chapter.typ": chapter-heading-rules, part-divider
#import "../frontmatter.typ": frontmatter-page, title-page, copyright-page, dedication-page, epigraph-page, toc
#import "../runners.typ": folio
#import "../backmatter.typ": references
#import "../notes.typ": footnote-transform

#let book(
  paper: "crown-quarto", media: auto, page-count-range: "151-400",
  title: none, subtitle: none, authors: (), publisher: none, release: none,
  copyright: (:), dedication: none, epigraphs: none,
  front: (:),                  // (introduction: content, preface: content, acknowledgments: content)
  parts: (), alt-runners: (:), icons: (:),
  theme: (:), labels: (:), bib: none, bib-visible: true,
  footnotes-as-sidenotes: true,
  doc,
) = {
  let media = resolve-media(media: media)
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme)
  let labels = resolve-labels(labels)
  let mc = marginalia-config(paper, media, page-count-range: page-count-range)
  let ps = page-size(paper, media)
  let note-ext = paper.note-col + paper.note-gap

  // NOTE: `author: authors` (not `authors.join(", ")` per the plan draft) —
  // document.author rejects `none`, and Typst's array.join() on an EMPTY
  // array returns `none` (not ""), so the default `authors: ()` crashed
  // `set document(...)` with "expected string or array, found none" before
  // a single word of content rendered. document.author natively accepts an
  // array of strings (multi-author case shows correctly in PDF metadata),
  // so passing the array through is both the fix and the more correct
  // mapping. Verified: authors: () and authors: ("A", "B") both compile.
  set document(title: if title == none { none } else { title }, author: authors)
  show: marginalia.setup.with(..mc)
  set page(width: ps.width, height: ps.height,
    fill: if media == "screen" { theme.screen-bg } else { none },
    header: folio(theme, note-ext: note-ext, media: media, alt-runners: alt-runners), header-ascent: 30%)
  show: base-style.with(theme, labels, note-ext, media: media)
  show: chapter-heading-rules.with(theme, labels, note-ext, icons: icons)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if footnotes-as-sidenotes { footnote-transform(theme, d) } else { d }
  state("tuftelike").update((media: media, paper: paper, theme: theme,
    labels: labels, parts: parts))

  // front matter sequence (print-proven order)
  if epigraphs != none { frontmatter-page(paper, media, epigraph-page(theme, epigraphs)) }
  frontmatter-page(paper, media, title-page(theme, title: title, subtitle: subtitle,
    authors: authors, release: release, publisher: publisher))
  // skip the copyright page entirely when there is nothing to put on it
  // (a minimal book(title: …) render otherwise shows a blank page)
  if copyright != (:) or publisher != none {
    frontmatter-page(paper, media, copyright-page(theme, copyright: copyright, publisher: publisher))
  }
  frontmatter-page(paper, media, toc(theme, labels, parts: parts))
  if dedication != none { frontmatter-page(paper, media, dedication-page(theme, dedication)) }
  for (name, body) in front.pairs() {
    frontmatter-page(paper, media, { heading(numbering: none, level: 1, upper(name.first()) + name.slice(1)); body })
  }

  doc

  if bib != none { references(bib, hidden: not bib-visible) }
}
