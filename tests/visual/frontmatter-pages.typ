#import "@local/tuftelike:0.1.0": frontmatter-page, title-page, copyright-page, dedication-page, epigraph-page, toc, resolve-theme, resolve-labels, resolve-paper, resolve-media, page-size

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let ps = page-size(paper, media)
#let theme = resolve-theme((:))
#let labels = resolve-labels((:))

#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })

// Title page.
#frontmatter-page(paper, media, title-page(theme,
  title: "The Sample Title",
  subtitle: "A Subtitle for Testing",
  authors: ("An Author",),
  release: "First Edition",
  publisher: (name: "Sample Press"),
))

// Copyright page, two-format ISBN dict.
#frontmatter-page(paper, media, copyright-page(theme,
  copyright: (
    year: "2026",
    holders: "An Author",
    isbn: (paperback: "978-1-0000-0000-1", ebook: "978-1-0000-0000-2"),
    release-line: "First release, 2026.",
    disclaimer: "All rights reserved.",
    extra: "Typeset with tuftelike.",
  ),
  publisher: (name: "Sample Press", address: "123 Main St, Anytown", website_url: "example.com"),
))

// Dedication, shape 1: plain string.
#frontmatter-page(paper, media, dedication-page(theme, "For everyone who reads margins first."))

// Dedication, shape 2: array (joined with spacing).
#frontmatter-page(paper, media, dedication-page(theme, (
  "For the first reason.",
  "For the second reason.",
)))

// Dedication, shape 3: dict (author -> dedication).
#frontmatter-page(paper, media, dedication-page(theme, (
  "A Friend": "For the years.",
  "A Mentor": "For the patience.",
)))

// Epigraph, dict shape (author -> quote).
#frontmatter-page(paper, media, epigraph-page(theme, (
  "A Notable Person": "The margin is where the real thinking happens.",
  "Another Voice": "Print proves what the screen only suggests.",
)))

// TOC with a part divider (regression: outline() has no fill: param in 0.15;
// entry fill + entry styling must come from set/show outline.entry rules).
#frontmatter-page(paper, media, toc(theme, labels, parts: ((title: "Part I: Threads", first-chapter: 1),)))
#set heading(numbering: "1.1")
= First Chapter
Body so the outline has a target.
= Second Chapter
More body.
