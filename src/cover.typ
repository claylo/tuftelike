#import "@preview/tiaoma:0.3.0"
#import "geometry.typ": resolve-paper
#import "themes.typ": resolve-theme, role, role-args, styled
#import "labels.typ": resolve-labels

// mm of spine per page. lulu-standard-bw back-derived from the prototype
// cover (13.03mm at ~228pp). Re-check printer docs when stakes are real:
// Lulu book-creation-guide + KDP paperback submission specs.
#let stocks = (
  "lulu-standard-bw": 0.0572mm,
  "kdp-white": 0.0572mm,     // 0.002252in/page
  "kdp-cream": 0.0635mm,     // 0.0025in/page
)
#let spine-width(page-count, stock) = page-count * stocks.at(stock)
#let cover-size(paper, page-count, stock) = (
  width: 2 * paper.trim.w + spine-width(page-count, stock) + 2 * paper.bleed,
  height: paper.trim.h + 2 * paper.bleed,
)

// stretch content to fully bleed the cover canvas. Not image-specific
// despite the name: box() accepts any content, so a solid-color rect()
// background works identically to a photo (verified — see Task 16 report).
#let image-fill(img, cs) = block(width: cs.width, height: cs.height, clip: true,
  align(center + horizon, box(width: cs.width, height: cs.height, img)))

#let barcode-zone(theme, labels, barcode) = {
  let zone(body) = rect(width: 50.8mm, height: 30.5mm, fill: white, inset: 3mm,   // lint-ok: printer barcode-zone spec, not typography
    align(center + horizon, body))
  if barcode == none { none }
  else if type(barcode) == dictionary and barcode.at("review-copy", default: false) {
    // fill: black — cover() sets white text page-wide for the jacket
    // panels; the white zone needs ink or the stamp is invisible
    zone(styled(theme, "cover.stamp", labels.review-copy))
  } else if type(barcode) == dictionary and "isbn" in barcode {
    let digits = barcode.isbn.replace("-", "")
    zone[
      #styled(theme, "cover.isbn", "ISBN " + barcode.isbn)
      #v(1mm)
      #tiaoma.ean(digits, options: (height: 18.0))
    ]
  } else { zone(barcode) } // pre-made image
}

#let cover(
  paper: "crown-quarto", page-count: 200, stock: "lulu-standard-bw",
  background: none,
  front: (:), spine: (:), back: (:),
  barcode: none, theme: (:), presets: (:), theme-preset: auto, labels: (:),
) = {
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme, presets: presets, preset: theme-preset)
  let labels = resolve-labels(labels)
  // helpers read this via current-theme()/current-labels() — never thread it
  state("tuftelike").update((media: none, paper: paper, theme: theme, labels: labels))
  let sw = spine-width(page-count, stock)
  let cs = cover-size(paper, page-count, stock)
  set page(width: cs.width, height: cs.height, margin: 0mm,
    background: if background != none { image-fill(background, cs) } else { none })
  set text(..role-args(theme, "cover.base"))
  grid(columns: (paper.trim.w + paper.bleed, sw, paper.trim.w + paper.bleed), rows: 100%,
    // BACK (left panel)
    block(width: 100%, height: 100%, inset: (x: paper.bleed + paper.safety + 6mm, y: paper.bleed + paper.safety + 6mm))[
      #if "overlay" in back { place(top + left, dx: -paper.safety - 6mm, dy: -paper.safety - 6mm,
        rect(width: 100% + 2 * (paper.safety + 6mm), height: 100% + 2 * (paper.safety + 6mm), fill: back.overlay)) }
      #back.at("blurb", default: none)
      #place(bottom + right, barcode-zone(theme, labels, barcode))
    ],
    // SPINE — auto-hidden under 80 pages (printer minimums)
    if page-count >= 80 {
      // rotate(-90deg, reflow: true), not the plan draft's bare
      // rotate(90deg, ...): two corrections, verified in isolation before
      // landing here (see Task 16 report for the probes).
      // 1. Direction: +90deg reads TOP-TO-BOTTOM tilting the head LEFT —
      //    backwards from the standard spine convention this is meant to
      //    produce (bottom-to-top, tilt right). -90deg is correct.
      // 2. reflow: rotate()'s default reflow:false reserves layout space
      //    using the PRE-rotation footprint (here: cs.height wide, one
      //    text-line tall) instead of the rotated one, so the content
      //    overflows its grid cell — with +90deg the overflow happened to
      //    fall inside the visible spine column (looked fine by luck);
      //    with -90deg it overflowed past the top of the page and was
      //    clipped almost entirely off-canvas. reflow: true sizes the
      //    container from the actual (rotated) footprint, which both
      //    directions need regardless of which way they rotate.
      align(center, rotate(-90deg, reflow: true, box(width: cs.height)[
        #align(horizon, styled(theme, "cover.spine",
          [#spine.at("author", default: none) #h(1fr) #upper(spine.at("title", default: ""))]))
      ]))
    },
    // FRONT (right panel)
    block(width: 100%, height: 100%, inset: paper.bleed + paper.safety + 6mm)[
      #styled(theme, "cover.author", front.at("author", default: ""))
      #v(1fr)
      #styled(theme, "cover.title", front.at("title", default: ""))
      #if "subtitle" in front [ #v(role(theme, "cover").subtitle-gap) #styled(theme, "cover.subtitle", front.subtitle) ]
      #v(1fr)
      #if "release" in front [ #styled(theme, "cover.release", front.release) ]
    ])
}
