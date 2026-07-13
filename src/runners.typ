#import "utils.typ": plain-text

// Running heads: verso "N   CHAPTER", recto "SECTION   N", set flush with
// the page's OUTER edge (the folio extends into the note column via
// negative padding — the header box itself only spans the text column).
// Skipped on pages carrying <divider-page> or <no-folio> metadata, before
// <chapters-begin-here>, on chapter-opener pages (a level-1 heading on the
// page), and — in print — on the page immediately before an opener (the
// blank verso inserted by recto chapter starts).
// Cost note: the before(here()) heading queries rescan all headings so far
// on every page — measured ~O(n²): +0.3s at 300pp, +1.3s at 600pp on a
// bare doc. Acceptable for the supported page-count ranges; revisit with
// a cached-state design only if 1000+ page books become a target.
#let folio(theme, note-ext: 0mm, media: "screen", alt-runners: (:)) = context {
  let pg = here().page()
  if query(<chapters-begin-here>).len() == 0 { return }
  let begin = query(<chapters-begin-here>).first().location().page()
  if pg < begin { return }
  let markers = query(selector(<divider-page>).or(selector(<no-folio>)))
  if markers.any(m => m.location().page() == pg) { return }
  let h1-pages = query(heading.where(level: 1)).map(h => h.location().page())
  if h1-pages.contains(pg) { return }
  // print: suppress the page immediately before a chapter opener. This
  // silences the blank filler versos from recto starts AND any content
  // page facing an opener — deliberately matching the print-proven
  // prototype (tag-the-filler alternatives are bistable; see mainmatter).
  if media == "print" and h1-pages.contains(pg + 1) { return }
  let shorten(t) = alt-runners.at(t, default: t)
  let numtxt = counter(page).display("1")
  let style(body) = text(font: theme.serif, size: theme.folio-size,
    tracking: 0.12em, style: "normal", weight: "regular", body)
  let before(lvl) = {
    let hs = query(heading.where(level: lvl).before(here()))
    if hs.len() == 0 { none } else { upper(shorten(plain-text(hs.last().body))) }
  }
  // verso: outer edge is LEFT of the text column (note column side in
  // book mode); recto: outer edge is RIGHT. Screen media keeps the note
  // column on the right for every page, so only recto-style extension
  // applies there.
  let verso = media == "print" and calc.even(pg)
  if verso {
    pad(left: -note-ext, align(left, style([#numtxt#h(2em)#before(1)])))
  } else {
    let title = if before(2) != none { before(2) } else { before(1) }
    pad(right: -note-ext, align(right, style([#title#h(2em)#numtxt])))
  }
}
