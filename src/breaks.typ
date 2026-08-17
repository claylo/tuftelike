// Chapter/section page breaks that read the build target's media
// ambiently. Shared by mainmatter.typ (typst-side chapters) and
// markdown.typ (raw-typst breaks injected between chapter files).
#import "geometry.typ": current-media

// Recto starts in print via plain pagebreak(to: "odd"). Conditional
// tag-the-filler schemes are BISTABLE under Typst's layout iteration (the
// conditional break shifts the page it queries; the engine converges on
// the no-break state without warning) — probed extensively, don't retry.
// Instead folio() suppresses the page before an opener (prototype-proven
// behavior; see runners.typ). Reading media from state is NOT bistable:
// the value is fixed at class start, independent of layout.
#let chapter-break(split, media: auto) = {
  assert(split in ("odd", "soft"), message: "chapter-break: split must be \"odd\" or \"soft\", got " + repr(split))
  let go(m) = if m == "print" and split == "odd" { pagebreak(to: "odd", weak: true) } else { pagebreak(weak: true) }
  if media == auto { context go(current-media()) } else { go(media) }
}
