#import "@local/tuftelike:0.1.0": *

#cover(
  paper: "us-trade-6x9",
  page-count: 228,
  stock: "lulu-standard-bw",
  background: rect(width: 100%, height: 100%, fill: rgb("1a3a5c")),
  front: (
    author: "A. Demo Author",
    title: "Margins of Error",
    subtitle: "A Field Guide to Thinking in the Margins",
    release: "First Edition",
  ),
  spine: (title: "Margins of Error", author: "A. Demo Author"),
  back: (
    blurb: text(size: 10pt)[
      Every page has an edge, and every edge is a decision: dead space,
      or a second channel the reader can trust. This field guide makes
      the case for the second option, one margin note at a time.
    ],
  ),
  barcode: (isbn: "978-1-0000-0000-9"),
)
