#import "@local/tuftelike:0.1.0": *
#import "theme.typ": swap-theme
#cover(page-count: 200,
  front: (title: "Title", author: "Author", subtitle: "Sub", release: "Rel"),
  spine: (title: "Title", author: "Author"), back: (blurb: [Blurb.]),
  barcode: (isbn: "978-1-0000-0000-9"), theme: swap-theme)
#pagebreak()
#cover(page-count: 200, front: (title: "T"), barcode: (review-copy: true), theme: swap-theme)
