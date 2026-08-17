// Every book-side helper and region, under a fully swapped font theme.
#import "@local/tuftelike:0.1.0": *
#import "theme.typ": swap-theme
#let reader = (p, ..a) => read(p, ..a.named())
#show: book.with(
  title: "Swap", subtitle: "Every role", authors: ("A. Author",),
  publisher: (name: "Press"), release: "Test Edition",
  copyright: (year: "2026", holders: "A. Author", isbn: "978-1-0000-0000-9"),
  dedication: "For the lint.", epigraphs: ("Someone": "Quoted."),
  front: (preface: [Front matter text.]),
  parts: ((title: "Part I", first-chapter: 1),),
  bib: bibliography("../visual/refs.bib"), bib-visible: true,
  theme: swap-theme,
)
#show: begin-chapters.with(resolve-media())
#part-divider("I", "Part One")
= Chapter One
#newthought[Lead in] body text#sidenote[side] and#marginnote[margin] and
#sidecite(<demo1>) footnote#footnote[foot] `inline` code.
== Section
#lorem(20)
=== Sub
#tufte-quote(attribution: "Attr")[Quote.]
#quote(block: true)[Block quote]
```typ
raw block
```
#figure(table(columns: 2, [h1], [h2], [a], [b]), caption: [A table])
#figure(rect(width: 2em, height: 1em), caption: [A figure])
- list item
+ enum item
#md("Md para.<note>md note</note> <note numbered>numbered</note>\n\n<prompt>p</prompt><response>r</response>\n\n> md quote\n\n`md code`\n\n#index[term]",
  extensions: instructional-extensions())
#appendices(("../visual/md/appx.md",), reader: reader, media: resolve-media())
#about-author[Bio.]
#colophon[Set for the test.]
#book-index()
