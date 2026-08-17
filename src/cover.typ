#import "@preview/tiaoma:0.3.0"
#import "geometry.typ": resolve-paper, printers, resolve-stock, resolve-target
#import "themes.typ": resolve-theme, role, role-args, styled
#import "labels.typ": resolve-labels

// Spine width from the printer's per-stock formula (per-page × pages + plus).
// See geometry.typ printers.<p>.spine for sources; lulu "standard-bw" is the
// proven template-derived constant. Coil binding has no spine.
#let spine-width(page-count, printer: "lulu", stock: auto, binding: "perfect") = {
  if binding == "coil" { return 0mm }
  let f = printers.at(printer).spine.at(resolve-stock(printer, stock))
  page-count * f.per-page + f.plus
}
// printer: auto reads paper.printer (custom dicts must carry one or pass printer:)
#let cover-printer(paper, printer) = if printer != auto { printer } else {
  assert("printer" in paper, message: "cover(): paper dict has no printer — pass printer: \"lulu\" | \"kdp\"")
  paper.printer
}
// both printers bleed the cover on all four edges
#let cover-size(paper, page-count, stock: auto, binding: "perfect", printer: auto) = (
  width: 2 * paper.trim.w + spine-width(page-count, printer: cover-printer(paper, printer), stock: stock, binding: binding) + 2 * paper.bleed,
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
  paper: "crown-quarto", page-count: 200, stock: auto, binding: "perfect", printer: auto,
  target: auto, targets: (:),
  background: none,
  front: (:), spine: (:), back: (:),
  barcode: none, theme: (:), presets: (:), theme-preset: auto, labels: (:),
) = {
  // a target may pick paper/binding/theme-preset (same mechanism as the classes)
  let tg = resolve-target(target: target, targets: targets, media: "print", paper: paper,
    binding: binding, theme-preset: theme-preset)
  let paper = tg.paper
  let pr = cover-printer(paper, printer)
  let theme = resolve-theme(theme, presets: presets, preset: tg.theme-preset)
  let labels = resolve-labels(labels)
  // helpers read this via current-theme()/current-labels() — never thread it
  state("tuftelike").update((media: "print", paper: paper, theme: theme, labels: labels,
    target: tg.name, binding: tg.binding))
  let sw = spine-width(page-count, printer: pr, stock: stock, binding: tg.binding)
  let cs = cover-size(paper, page-count, stock: stock, binding: tg.binding, printer: pr)
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
    // SPINE — text auto-hidden below the printer's spine-text threshold; a
    // coil cover has no spine at all (sw = 0mm → empty column)
    if sw > 0mm and page-count >= printers.at(pr).spine-text-min-pages {
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
