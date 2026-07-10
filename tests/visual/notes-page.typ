#import "@local/tuftelike:0.1.0": sidenote, marginnote, notefigure, wideblock, resolve-paper, resolve-media, marginalia-config, page-size
#import "@preview/marginalia:0.3.1" as marginalia

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let mc = marginalia-config(paper, media)
#let ps = page-size(paper, media)

#show: marginalia.setup.with(..mc)
#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })

= Notes smoke test

Three clustered sidenotes check collision avoidance: this is the
first#sidenote[First sidenote, testing the arabic-numeral anchor and
collision avoidance with its two neighbors.] and immediately after it comes
the second#sidenote[Second sidenote, packed tightly against the first and
third to force marginalia's automatic vertical shifting.] and then the
third#sidenote[Third sidenote, completing the tightly clustered trio on this
line.] in quick succession.

A floating comment on the side.#marginnote[An unnumbered marginnote — no
marker, no anchor, just floating commentary.]

#notefigure(image("../spike/img.svg"), caption: [A circle, floating in the margin.])

#wideblock[#rect(width: 100%, height: 2em, fill: luma(230), align(center + horizon,
  text(size: 9pt, [wideblock spans into the margin])))]

#pagebreak()

= Second page

This page exists to verify verso (left/outer) placement in print
media.#sidenote[Fourth sidenote — should land on the LEFT margin when
compiled with `--input media=print` since page 2 is even/verso in book
mode.]
