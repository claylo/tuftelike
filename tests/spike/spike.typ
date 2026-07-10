#import "@preview/marginalia:0.3.1" as marginalia
#import "@preview/cmarker:0.1.10" as cmarker

#let media = sys.inputs.at("media", default: "screen")
#let bleed = if media == "print" { 3.18mm } else { 0mm }

#show: marginalia.setup.with(
  inner: (far: bleed + 12.7mm + 13mm, width: 0mm, sep: 0mm),
  outer: (far: bleed + 12.7mm, width: 37mm, sep: 4mm),
  top: bleed + 12.7mm + 15mm, bottom: bleed + 12.7mm + 3.17mm,
  book: media == "print",
)
#set page(width: 189mm + 2 * bleed, height: 246mm + 2 * bleed,
  fill: if media == "screen" { rgb("FFFFF8") } else { none },
  header: marginalia.header(
    text(size: 8pt)[RUNNER-INNER],
    [],
    text(size: 8pt)[RUNNER-OUTER #context here().page()],
  ))

#let sidenote(body) = marginalia.note(text(size: 9pt, font: ("Gill Sans MT", "Helvetica Neue"), body))
// (e) runner probe — marginalia.header() wired into page(header:) above; verify it doesn't fight the note column

// (c) footnote transform — see FINDINGS.md (c) for the full story.
//     All three rules MUST be declared before the first note call.
#show footnote: it => sidenote(it.body)
#show footnote.entry: none
#set footnote.entry(separator: none)

Native note.#sidenote[I am a native marginalia note.]

// (b) reader-closure probe
#let reader = (p, ..a) => read(p, ..a.named())

// (a) html mapping + regex tier
#let note-match = regex("#note\\[((?s).*?)\\]")
#show note-match: it => sidenote(it.text.matches(note-match).first().captures.at(0))

#cmarker.render(
  reader("spike-content.md"),
  html: (note: (attrs, body) => sidenote(body)),
  scope: (image: (path, alt: none) => image(bytes(reader(path, encoding: none)), alt: alt)),
)

Unnumbered probe: #marginalia.note(counter: none)[no marker on me] // (a) counter: none disables the marker
#marginalia.wideblock[#rect(width: 100%, height: 2em)] // wide probe
#pagebreak()
Second page.#sidenote[I should land in the OUTER margin, which is LEFT on this verso page.] Verify notes land in the OUTER margin here in print media (verso).
