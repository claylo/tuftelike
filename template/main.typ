#import "@local/tuftelike:0.1.0": *
#let reader = (p, ..a) => read(p, ..a.named())

#show: book.with(
  title: "My Book",
  authors: ("Your Name",),
  paper: "us-trade-6x9",
)

#show: begin-chapters.with(resolve-media())
#chapters(
  ("content/chapter-one.md",),
  reader: reader, media: resolve-media(), content-root: "content")
