// tuftelike — public API. Users import ONLY this file.
#let tuftelike-version = version(0, 1, 0)

#import "geometry.typ": papers, resolve-media, resolve-paper, page-size, marginalia-config
#import "labels.typ": default-labels, resolve-labels
#import "themes.typ": default-theme, resolve-theme
#import "utils.typ": plain-text, lead-split
#import "typography.typ": newthought, lead-smallcaps, tufte-quote, base-style
#import "notes.typ": sidenote, marginnote, notefigure, sidecite, wideblock, footnote-transform
#import "markdown.typ": md
#import "frontmatter.typ": isbn-lines, frontmatter-page, title-page, copyright-page, dedication-page, epigraph-page, toc
#import "chapter.typ": chapter-heading-rules, part-divider
#import "runners.typ": folio
#import "mainmatter.typ": begin-chapters, chapter-break, chapters, appendices
#import "backmatter.typ": about-author, colophon, references
