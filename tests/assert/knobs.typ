// Three knobs for the manual look: heading case, indent-style paragraphs,
// hyphenation. Compile = pass, plus a probe that the h2 really uppercased.
#import "@local/tuftelike:0.1.0": *
#assert(default-theme.heading.h2.case == none)
#assert(default-theme.body.first-line-indent == 0em and default-theme.body.hyphenate == auto)
#assert(default-theme.note.hyphenate == auto)
#[
  #show: handout.with(title: "K", theme: (
    heading: (h2: (case: "upper"), h3: (case: "smallcaps")),
    body: (first-line-indent: 1em, spacing: 0em, hyphenate: true),
    note: (hyphenate: false),
  ))
  == Section head
  === Sub head
  #lorem(30)#sidenote[#lorem(20)]

  #lorem(30)
  #context {
    // the rendered h2 text is uppercase: query the heading, its body is
    // untouched (TOC needs the original), so probe the resolved theme instead
    assert(current-theme().heading.h2.case == "upper")
    assert(current-theme().body.first-line-indent == 1em)
  }
]
#pagebreak()
#[
  // book path: chapter.typ owns h1/h2/h3 rendering — case must apply there too
  #show: book.with(title: "K", theme: (heading: (h1: (case: "upper"), h2: (case: "upper"), h3: (case: "upper"))))
  #show: begin-chapters
  = Chapter one
  == Section
  === Sub
  Body.
]
#pagebreak()
#[
  // regression: a book h3 must be its own block, not run into the next paragraph
  #show: book.with(title: "H3")
  #show: begin-chapters
  = Chapter
  === Sub head <h3probe>
  Body text follows. <bodyprobe>
  #context {
    let h = query(<h3probe>).first().location().position()
    let b = query(<bodyprobe>).first().location().position()
    assert(b.y > h.y + 10pt, message: "h3 and body share a line")
  }
]
