#import "@local/tuftelike:0.1.0": folio, part-divider, resolve-theme, resolve-labels, resolve-paper, resolve-media, marginalia-config, page-size
#import "@preview/marginalia:0.3.1" as marginalia

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let mc = marginalia-config(paper, media)
#let ps = page-size(paper, media)
#let theme = resolve-theme((:))
#let labels = resolve-labels((:))
#let alt-runners = ("A Very Long Heading": "SHORT")

#show: marginalia.setup.with(..mc)
#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none },
  header: folio(theme, alt-runners: alt-runners))

// Page 1: front matter, strictly before <chapters-begin-here>. No folio.
Front-matter page. This is before the main-matter boundary marker, so no
folio should appear here.

#pagebreak()

// Page 2: the boundary page itself — carries <chapters-begin-here> but has
// no heading yet. At/after the boundary and not an opener/divider, so a
// folio SHOULD render — but with no preceding heading, the verso runner
// shows only the page number (edge case, not a bug).
#metadata(none) <chapters-begin-here>
This page carries the `<chapters-begin-here>` marker itself. It is at the
main-matter boundary (not before it), and is not a chapter opener or
divider, so it should show a folio — with no chapter title yet, since no
level-1 heading precedes it.

#pagebreak()

// Page 3: chapter opener. A level-1 heading lives on this page, so the
// h1-here check skips the folio.
= A Very Long Heading

Chapter opener body. No folio should appear on this page even though we are
past the boundary, because a level-1 heading is on this page.

#pagebreak()

// Page 4: body page, verso (even, page 4). Should show the page number and
// the shortened chapter title ("SHORT", via alt-runners), left-aligned.
Body text on the verso page, still under "A Very Long Heading".

== A Body Section

A level-2 heading, so the NEXT (recto) page's runner prefers this section
title over the chapter title.

#pagebreak()

// Page 5: body page, recto (odd, page 5). Should show the nearest preceding
// level-2 heading ("A BODY SECTION"), not the chapter title, right-aligned.
Body text on the recto page, continuing under "A Body Section".

#pagebreak()

// Page 6: part divider. Carries <divider-page>, so folio is skipped.
#part-divider(theme, labels, 2, "The Second Part")
