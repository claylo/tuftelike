// Lulu US Letter, coil bound, 120 pages — no spine panel, no spine text.
#import "@local/tuftelike:0.1.0": *
#cover(
  paper: "lulu-us-letter", page-count: 120, binding: "coil",
  background: rect(width: 100%, height: 100%, fill: rgb("1f3d2b")),
  front: (author: "A. Demo Author", title: "Wiring Guide", subtitle: "Custom build", release: "Field Edition"),
  back: (blurb: [Back-cover copy.]),
  barcode: (review-copy: true),
)
