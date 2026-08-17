// KDP 7.5×9.25, 250 pages on cream — spine from KDP's cream formula.
#import "@local/tuftelike:0.1.0": *
#cover(
  paper: "kdp-7.5x9.25", page-count: 250, stock: "cream",
  background: rect(width: 100%, height: 100%, fill: rgb("3b2f2f")),
  front: (author: "A. Demo Author", title: "Margins of Error", subtitle: "A Field Guide", release: "First Edition"),
  spine: (title: "Margins of Error", author: "A. Demo Author"),
  back: (blurb: [Back-cover copy.]),
  barcode: (isbn: "978-1-0000-0000-9"),
)
