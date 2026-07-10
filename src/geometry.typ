// All paper geometry is DATA. Print-proven crown-quarto values come from the
// prototype book, verbatim. 6x9 note-col/top/bottom are initial values — tune
// against printed proofs before calling the preset stable.
// A paper preset dict requires: trim(w,h), bleed, safety, note-col, note-gap,
// top-extra, bottom-extra, gutter-table. Custom dicts passed to resolve-paper
// need that same shape for marginalia-config/page-size to work.
#let lulu-gutter-table = (
  "0-60": 0mm, "61-150": 3mm, "151-400": 13mm, "401-600": 16mm, "over-600": 19mm,
)

#let papers = (
  "crown-quarto": (
    trim: (w: 189mm, h: 246mm), bleed: 3.18mm, safety: 12.7mm,
    note-col: 37mm, note-gap: 4mm, top-extra: 15mm, bottom-extra: 3.17mm,
    gutter-table: lulu-gutter-table,
  ),
  "us-trade-6x9": (
    trim: (w: 152.4mm, h: 228.6mm), bleed: 3.175mm, safety: 12.7mm,
    note-col: 26mm, note-gap: 4mm, top-extra: 10mm, bottom-extra: 3mm,
    gutter-table: lulu-gutter-table,
  ),
  // letter/handout classes read letter-margin/handout-margin directly and
  // bypass marginalia-config — hence the minimal one-entry gutter-table.
  "us-letter": (
    trim: (w: 215.9mm, h: 279.4mm), bleed: 0mm, safety: 12.7mm,
    note-col: 2in, note-gap: 0.5in, top-extra: 25.4mm, bottom-extra: 19mm,
    gutter-table: ("0-60": 0mm),
    letter-margin: (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in),
    handout-margin: (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in),
  ),
)

#let resolve-media(media: auto) = {
  if media != auto { media } else { sys.inputs.at("media", default: "screen") }
}

#let resolve-paper(paper) = {
  if type(paper) == str { papers.at(paper) } else { paper }
}

#let page-size(paper, media) = {
  let b = if media == "print" { paper.bleed } else { 0mm }
  (width: paper.trim.w + 2 * b, height: paper.trim.h + 2 * b)
}

// Maps a paper preset onto marginalia's margin model. Inner column carries the
// binding gutter; outer column carries the note column. Screen = no bleed, one-sided.
#let marginalia-config(paper, media, page-count-range: "151-400") = {
  let b = if media == "print" { paper.bleed } else { 0mm }
  // no default: a typo'd page-count-range must FAIL LOUDLY, not silently
  // produce a 0mm binding gutter (0mm is a legitimate value for short books,
  // so a silent fallback would be indistinguishable from a real one)
  let gutter = paper.gutter-table.at(page-count-range)
  (
    inner: (far: b + paper.safety + gutter, width: 0mm, sep: 0mm),
    outer: (far: b + paper.safety, width: paper.note-col, sep: paper.note-gap),
    top: b + paper.safety + paper.top-extra,
    bottom: b + paper.safety + paper.bottom-extra,
    book: media == "print",
  )
}
