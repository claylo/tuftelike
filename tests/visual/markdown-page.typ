#import "@local/tuftelike:0.1.0": md, marginalia-config, resolve-paper, resolve-media, resolve-theme, footnote-transform, page-size
#import "@preview/marginalia:0.3.1" as marginalia

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let mc = marginalia-config(paper, media)
#let ps = page-size(paper, media)

#show: marginalia.setup.with(..mc)
#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })
// Class-level footnote transform, installed BEFORE any content (FINDINGS.md
// c): md() intentionally does not install this itself — ordering-sensitive.
#show: footnote-transform.with(resolve-theme((:)))

#let reader = (p, ..a) => read(p, ..a.named())
#md(reader("md/sample.md"), reader: reader, content-root: "md")
