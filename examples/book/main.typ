#import "@local/tuftelike:0.1.0": *
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
  icons: ("Quick Try": image("../_assets/icon-flask.svg")),
)

#show: begin-chapters.with(resolve-media())
#part-divider(default-theme, default-labels, "I", "Threads")
#chapters(
  ("content/part1-opening.md", "content/finding-the-thread.md", "content/margins-of-error.md"),
  reader: reader, media: resolve-media(), content-root: "content")
#appendices(("content/appendix-tooling.md",), reader: reader,
  media: resolve-media(), content-root: "content")
