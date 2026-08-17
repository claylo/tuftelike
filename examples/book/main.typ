#import "@local/tuftelike:0.1.0": *
#import "themes.typ": book-presets
#let reader = (p, ..a) => read(p, ..a.named())

#show: book.with(
  paper: "us-trade-6x9",
  title: "Margins of Error",
  subtitle: "A Field Guide to Thinking in the Margins",
  authors: ("A. Demo Author",),
  publisher: (name: "Example Press", website_url: "example.org"),
  release: "First Edition",
  copyright: (year: "2026", holders: "A. Demo Author",
    isbn: (paperback: "978-1-0000-0000-9", ebook: "978-1-0000-0001-6")),
  dedication: "For everyone who reads the footnotes first.",
  epigraphs: ("A Typographer": "The margin is not empty space."),
  front: (introduction: [
    This field guide grew out of a simple observation: readers skim less
    when the page gives them somewhere to look besides straight down the
    column. Everything that follows tries to make that somewhere useful.
  ]),
  parts: ((title: "Part I: Threads", first-chapter: 1),),
  // named theme variants from the (symlinkable) library file — flipped at
  // compile time without editing this one: `just demo book print trade`
  // (or --input theme=trade); omit for the Tufte defaults
  presets: book-presets,
  // bundled keyword→icon map; root-absolute path because the image() call
  // inside instructional-icons resolves against the package, not this file
  icons: instructional-icons(assets: "/examples/_assets"),
)

#show: begin-chapters.with(resolve-media())
#part-divider("I", "Threads")
#chapters(
  ("content/part1-opening.md", "content/finding-the-thread.md", "content/margins-of-error.md"),
  reader: reader, media: resolve-media(), content-root: "content",
  extensions: instructional-extensions())
#appendices(("content/appendix-tooling.md",), reader: reader,
  media: resolve-media(), content-root: "content")

#about-author[
  A. Demo Author has been writing in the margins of other people's books
  for twenty years and finally decided to typeset some margins of their own.
]
#colophon[
  Set in ETbb and Gill Sans with the tuftelike template. \
  Composed on macOS; proofed at 6×9 on uncoated stock.
]

// Back-of-book index over the #index markers scattered through the
// chapters (colophon inserts these automatically in a real workflow).
#pagebreak(to: if resolve-media() == "print" { "odd" } else { none }, weak: true)
#book-index()
