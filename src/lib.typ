// tuftelike — public API. Users import ONLY this file.
#let tuftelike-version = version(0, 1, 0)

#import "geometry.typ": papers, resolve-media, resolve-paper, page-size, marginalia-config
#import "labels.typ": default-labels, resolve-labels
#import "themes.typ": default-theme, resolve-theme
#import "utils.typ": plain-text, lead-split
#import "typography.typ": newthought, lead-smallcaps, tufte-quote, base-style
#import "notes.typ": sidenote, marginnote, notefigure, sidecite, wideblock, footnote-transform
#import "markdown.typ": md
