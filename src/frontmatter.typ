#import "typography.typ": tufte-quote
#import "utils.typ": plain-text

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
  #for a in authors [#upper(text(font: theme.sans, tracking: 0.2em, size: 16pt, a)) \ ]
  #v(8em)
  #upper(text(font: theme.sans, tracking: 0.16em, size: 20pt, title))
  #if subtitle != none [ \ #text(font: theme.serif, style: "italic", size: 15pt, subtitle) ]
  #if release != none [ #v(2em) #upper(text(font: theme.sans, tracking: 0.16em, size: 12pt, release)) ]
  #if publisher != none [ #align(bottom + left, upper(text(font: theme.sans, tracking: 0.16em, size: 14pt, publisher.at("name", default: publisher)))) ]
]

#let copyright-page(theme, copyright: (:), publisher: none) = align(bottom + left)[
  #set text(size: 9pt)
  #if "holders" in copyright [Copyright © #copyright.at("year", default: "") #copyright.holders \ ]
  #for line in isbn-lines(copyright.at("isbn", default: none)) [#line \ ]
  #if "release-line" in copyright [#copyright.release-line \ ]
  #if "disclaimer" in copyright [#v(0.5em) #copyright.disclaimer \ ]
  #if "extra" in copyright [#v(0.5em) #copyright.extra \ ]
  #if publisher != none [
    #v(1em)
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
  #set text(style: "italic")
  #{
    if type(dedication) == str { dedication }
    else if type(dedication) == array { dedication.join(v(1.5em)) }
    else { dedication.pairs().map(((who, what)) => [#what #v(0.2em) #text(style: "normal", smallcaps(who))]).join(v(2em)) }
  }
]

// Polymorphic: string | (quote, author) | array | dict(author -> quote)
// Same markup-mode if/else-chain hazard as dedication-page above — wrapped
// in #{ } for the same reason.
#let epigraph-page(theme, epigraphs) = align(left + horizon)[
  #let one(q, a) = [#tufte-quote(theme, q, attribution: a) #v(2em)]
  #{
    if type(epigraphs) == str { one(epigraphs, none) }
    else if type(epigraphs) == array and epigraphs.len() == 2 and type(epigraphs.first()) == str {
      one(epigraphs.first(), epigraphs.last())
    } else if type(epigraphs) == array { epigraphs.map(e => one(e, none)).join() }
    else { epigraphs.pairs().map(((a, q)) => one(q, a)).join() }
  }
]

// TOC with data-driven part dividers. parts: ((title: "…", first-chapter: 1), …)
#let toc(theme, labels, parts: ()) = {
  show outline.entry.where(level: 1): it => {
    let divider = context {
      let el = it.element
      let num = counter(heading).at(el.location())
      // Appendix headings restart counter(heading) at 1 too (mainmatter.typ's
      // appendices()), so a part starting at chapter 1 collided with every
      // book's first appendix — both had num.first() == 1. Detect appendix
      // entries the same way chapter.typ does (rendered numbering starts
      // with a letter) and exclude them: parts are a chapter-only concept.
      let is-appendix = (el.numbering != none
        and numbering(el.numbering, ..num).match(regex("^[A-Z]")) != none)
      let hit = if is-appendix { none } else { parts.find(p => p.first-chapter == num.first()) }
      if hit != none {
        block(above: 1.3em, text(font: theme.sans, tracking: 0.16em,
          weight: "semibold", size: 10pt, upper(hit.title)))
      }
    }
    divider
    it
  }
  show outline.entry: set text(font: theme.serif, style: "italic")
  // Tufte TOC: whitespace gap, not dot leaders. fill lives on outline.entry
  // in Typst 0.15 — outline() itself has no fill: parameter.
  set outline.entry(fill: h(1em))
  outline(title: labels.contents, depth: 2)
}
