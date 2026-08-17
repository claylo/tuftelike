#import "typography.typ": tufte-quote
#import "utils.typ": plain-text
#import "themes.typ": role, role-args, styled

#let isbn-lines(isbn) = {
  if isbn == none { () }
  else if type(isbn) == str { ("ISBN " + isbn,) }
  else { isbn.pairs().map(((fmt, num)) => "ISBN " + num + " (" + fmt + ")") }
}

// A front-matter page: narrow symmetric margins, no note column, no folio.
#let frontmatter-page(paper, media, body) = {
  page(margin: (left: 25.4mm, right: 25.4mm, top: 25.4mm, bottom: 19.05mm),
       header: none, footer: none, body)
}

#let title-page(theme, title: none, subtitle: none, authors: (), release: none,
                publisher: none) = align(left)[
  #let tp = role(theme, "title-page")
  #for a in authors [#styled(theme, "title-page.author", a) \ ]
  #v(tp.gap-author-title)
  #styled(theme, "title-page.title", title)
  #if subtitle != none [ \ #styled(theme, "title-page.subtitle", subtitle) ]
  #if release != none [ #v(tp.gap-release) #styled(theme, "title-page.release", release) ]
  #if publisher != none [ #align(bottom + left, styled(theme, "title-page.publisher", publisher.at("name", default: publisher))) ]
]

#let copyright-page(theme, copyright: (:), publisher: none) = align(bottom + left)[
  #let cr = role(theme, "copyright")
  #set text(..role-args(theme, "copyright"))
  #if "holders" in copyright [Copyright © #copyright.at("year", default: "") #copyright.holders \ ]
  #for line in isbn-lines(copyright.at("isbn", default: none)) [#line \ ]
  #if "release-line" in copyright [#copyright.release-line \ ]
  #if "disclaimer" in copyright [#v(cr.gap) #copyright.disclaimer \ ]
  #if "extra" in copyright [#v(cr.gap) #copyright.extra \ ]
  #if publisher != none [
    #v(cr.publisher-gap)
    #smallcaps(publisher.at("name", default: "")) \
    #publisher.at("address", default: "") \
    #publisher.at("website_url", default: "")
  ]
]

// Polymorphic: string | array | dict(author -> dedication)
// NOTE: the if/else-if/else selection is wrapped in an explicit #{ } code
// block. Typst's markup-mode `#if […] else if […] else […]` chain only
// chains correctly when written on ONE line; a bare newline before `else`
// (no blank line — normal multi-line formatting) makes the parser treat
// `else` as literal text instead of continuing the chain, silently running
// only the `if` branch and printing the rest as words. Wrapping in `#{ }`
// forces code-mode parsing, where multi-line if/else-if/else chains are
// unaffected by newlines. Verified with an isolated repro before landing
// this fix — see Task 8 report for the reproduction.
#let dedication-page(theme, dedication) = align(center + horizon)[
  #let dd = role(theme, "dedication")
  #set text(..role-args(theme, "dedication"))
  #{
    if type(dedication) == str { dedication }
    else if type(dedication) == array { dedication.join(v(dd.gap)) }
    else { dedication.pairs().map(((who, what)) => [#what #v(dd.attrib-gap) #text(style: "normal", smallcaps(who))]).join(v(dd.group-gap)) }
  }
]

// Polymorphic: string | (quote, author) | array | dict(author -> quote)
// Same markup-mode if/else-chain hazard as dedication-page above — wrapped
// in #{ } for the same reason.
#let epigraph-page(theme, epigraphs) = align(left + horizon)[
  #let one(q, a) = [#tufte-quote(q, attribution: a, theme: theme) #v(theme.epigraph-gap)]
  #{
    if type(epigraphs) == str { one(epigraphs, none) }
    else if type(epigraphs) == array and epigraphs.len() == 2 and type(epigraphs.first()) == str {
      one(epigraphs.first(), epigraphs.last())
    } else if type(epigraphs) == array { epigraphs.map(e => one(e, none)).join() }
    else { epigraphs.pairs().map(((a, q)) => one(q, a)).join() }
  }
]

// TOC ported from the prototype book's print-proven contents treatment.
// parts: ((title: "…", first-chapter: 1), …) drives the part dividers —
// data-driven where the prototype hardcoded chapter numbers.
//
// Layout contract (page-against-page vs the prototype's first-print PDF):
// - PART / APPENDICES headers sit at the outline margin: serif semibold,
//   0.16em tracking, caps, 1.3em above.
// - Entry rows are padded 2em in from those headers. Chapter/appendix
//   numbers right-align in their column via a two-space pad on single-char
//   prefixes (two ETbb spaces ≈ one digit).
// - Level-2 rows indent one prefix column deeper (entry.indented), upright,
//   1pt smaller. Appendices and unnumbered sections list no second tier.
// - Unnumbered entries (front sections, About the Author, Colophon, Index)
//   render italic with an empty prefix column; the first one after the
//   numbered body opens the backmatter group with a 1.2em separator gap.
// - theme.toc-pagenums: "ragged" (default) sets the folio right after the
//   title — Tufte contents style; "flush" pushes it to the line's right edge.
#let toc(theme, labels, parts: ()) = {
  let pagenums = theme.at("toc-pagenums", default: "ragged")
  assert(pagenums in ("ragged", "flush"),
    message: "theme.toc-pagenums must be \"ragged\" or \"flush\", got " + repr(pagenums))
  // ragged gap is literal NO-BREAK spaces (same advance as a space in the
  // print-proven fonts, so geometry parity holds): text never stretches
  // under justification, and the line breaker can never strand the folio
  // alone on a wrapped line — an overlong title breaks among its own
  // words instead
  let tc = role(theme, "toc")
  let folio-gap = if pagenums == "ragged" { "\u{a0}" * tc.folio-gap } else { h(1fr) }
  // sticky: a group header never widows at a page bottom — it always
  // travels with the entry that triggered it
  let group-header(title) = block(above: tc.group.above, sticky: true,
    styled(theme, "toc.group", title))

  // sticky: a chapter row never strands from its first section row —
  // the page break moves before the chapter instead
  show outline.entry.where(level: 1): set block(above: tc.l1.above, sticky: true)
  show outline.entry: it => context {
    let el = it.element
    // custom rendering forfeits the default show's link — re-add it
    let row(prefix, inner) = link(el.location(),
      pad(left: tc.indent, it.indented(prefix, inner, gap: tc.entry-gap)))
    if it.prefix() == none {
      // unnumbered sections keep their sub-heads out of the contents
      if it.level == 1 {
        // inclusive: false — .before() otherwise includes el itself (an
        // unnumbered heading), which would defeat the numbered-predecessor
        // test below and silently drop the gap
        let prior = query(selector(heading).before(el.location(), inclusive: false))
        if prior.len() > 0 and prior.last().numbering != none {
          // first unnumbered entry after the numbered body — open the
          // backmatter group with an empty spacer block
          block(above: tc.backmatter-gap, text(none))
        }
        row(" ", styled(theme, "toc.unnumbered", it.body()) + folio-gap + it.page())
      }
    } else {
      let prefix = plain-text(it.prefix()).trim(".")
      // appendix = rendered numbering starts with a letter (same detection
      // as chapter.typ). Appendix counters restart at 1 like chapters, so
      // they must dodge parts.find; they also list no second tier.
      let is-appendix = prefix.match(regex("^[A-Z]")) != none
      if it.level == 1 or not is-appendix {
        if it.level == 1 {
          let num = counter(heading).at(el.location())
          if is-appendix {
            if num.first() == 1 { group-header(labels.appendices) }
          } else {
            let hit = parts.find(p => p.first-chapter == num.first())
            if hit != none { group-header(hit.title) }
          }
        }
        // poor-man's right alignment: two spaces ≈ one digit width
        let padded = if prefix.len() == 1 { "  " + prefix } else { prefix }
        let lvl = if it.level == 1 { "toc.l1" } else { "toc.l2" }
        // prefix column matches the entry's size (only when the level sets one)
        let la = role-args(theme, lvl)
        let sz = if "size" in la { (size: la.size) } else { (:) }
        row(
          text(..role-args(theme, "toc.prefix"), ..sz, padded),
          styled(theme, lvl, it.body()) + folio-gap + it.page())
      }
    }
  }
  // Title rendered directly, not via outline(title:) — the class-level
  // chapter-opener rule would style the outline's title heading as an
  // opener and add its opener drop. toc.title-gap is calibrated, not derived:
  // it closes the measured title→first-entry distance page-against-page
  // with the prototype's first-print PDF (47.5pt at 11pt body; the
  // prototype routed its title through a generic h1 rule whose heading
  // block spacing tuftelike's flow doesn't otherwise reproduce).
  styled(theme, "toc.title", labels.contents)
  v(tc.title-gap)
  outline(title: none, depth: 2)
}
