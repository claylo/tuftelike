// tuftelike — public API. Users import ONLY this file.
#let tuftelike-version = version(0, 1, 0)

#import "geometry.typ": papers, resolve-media, resolve-paper, page-size, marginalia-config
#import "labels.typ": default-labels, resolve-labels, current-labels
#import "themes.typ": default-theme, theme-presets, resolve-theme, deep-merge, role, role-args, styled, cased, current-theme, with-theme, text-keys
#import "utils.typ": plain-text, lead-split
#import "typography.typ": newthought, lead-smallcaps, tufte-quote, base-style
#import "notes.typ": sidenote, marginnote, notefigure, sidecite, wideblock, footnote-transform
#import "markdown.typ": md
#import "frontmatter.typ": isbn-lines, frontmatter-page, title-page, copyright-page, dedication-page, epigraph-page, toc
#import "chapter.typ": chapter-heading-rules, part-divider
#import "runners.typ": folio
#import "mainmatter.typ": begin-chapters, chapter-break, chapters, appendices
#import "backmatter.typ": about-author, colophon, references, book-index
#import "classes/book.typ": book
#import "classes/letter.typ": letter
#import "classes/handout.typ": handout
#import "cover.typ": cover, spine-width, cover-size
#import "extras/instructional.typ": instructional-extensions, instructional-icons
