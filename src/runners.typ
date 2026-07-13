#import "utils.typ": plain-text

// Running heads: verso "N   CHAPTER", recto "SECTION   N". Skipped on pages
// carrying <divider-page> or <no-folio> metadata, before <chapters-begin-here>,
// and on chapter-opener pages (a level-1 heading on the page).
// Cost note: the before(here()) heading queries rescan all headings so far
// on every page — measured ~O(n²): +0.3s at 300pp, +1.3s at 600pp on a
// bare doc. Acceptable for the supported page-count ranges; revisit with
// a cached-state design only if 1000+ page books become a target.
#let folio(theme, alt-runners: (:)) = context {
  let pg = here().page()
  if query(<chapters-begin-here>).len() == 0 { return }
  let begin = query(<chapters-begin-here>).first().location().page()
  if pg < begin { return }
  let markers = query(selector(<divider-page>).or(selector(<no-folio>)))
  if markers.any(m => m.location().page() == pg) { return }
  let h1-here = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
  if h1-here.len() > 0 { return }
  let shorten(t) = alt-runners.at(t, default: t)
  let numtxt = counter(page).display("1")
  let style(body) = text(font: theme.serif, size: theme.folio-size,
    tracking: 0.12em, style: "normal", weight: "regular", body)
  let before(lvl) = {
    let hs = query(heading.where(level: lvl).before(here()))
    if hs.len() == 0 { none } else { upper(shorten(plain-text(hs.last().body))) }
  }
  if calc.even(pg) {
    align(left, style([#numtxt#h(2em)#before(1)]))
  } else {
    let title = if before(2) != none { before(2) } else { before(1) }
    align(right, style([#title#h(2em)#numtxt]))
  }
}
