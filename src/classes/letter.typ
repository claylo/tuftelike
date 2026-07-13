#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-media, resolve-paper
#import "../themes.typ": resolve-theme
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../notes.typ": footnote-transform

#let letter(
  paper: "us-letter", media: auto,
  from: (:),                 // (name:, title:, org:, address:, email:) or content
  to: none, date: auto, re: none, salutation: none,
  closing: "Sincerely,", signature: none,   // content|image|str
  enclosures: (), cc: (),
  numbered-sections: false,
  theme: (:), labels: (:),
  footnotes-as-sidenotes: true,
  doc,
) = {
  let media = resolve-media(media: media)
  let paper = resolve-paper(paper)
  let theme = resolve-theme(theme)
  let labels = resolve-labels(labels)
  let m = paper.letter-margin
  // note column occupies the wide right margin; letters are one-sided
  show: marginalia.setup.with(
    inner: (far: m.left, width: 0mm, sep: 0mm),
    outer: (far: m.right - paper.note-col - paper.note-gap, width: paper.note-col, sep: paper.note-gap),
    top: m.top, bottom: m.bottom, book: false)
  set page(width: paper.trim.w, height: paper.trim.h,
    fill: if media == "screen" { theme.screen-bg } else { none },
    header: context if counter(page).get().first() > 1 {
      text(font: theme.serif, size: theme.folio-size, tracking: 0.12em,
        [#smallcaps(if re != none { re } else { "" }) #h(1fr) #counter(page).display("1")])
    })
  show: base-style.with(theme, labels, paper.note-col + paper.note-gap, media: media)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if footnotes-as-sidenotes { footnote-transform(theme, d) } else { d }
  // NOTE: `set heading(numbering: if … { … } else { none })`, not the
  // plan's `if numbered-sections { set heading(...) }`. A `set` rule
  // inside a bare `if { }` with no matching content in that SAME block
  // never escapes the if-block's scope — verified with an isolated probe:
  // `if flag { set heading(numbering: "1.1.A.") }` followed by `doc` one
  // level up rendered headings completely unnumbered even with flag: true,
  // no error, no warning. Moving the condition into the VALUE (this line)
  // keeps the `set` unconditional and lets its scope reach `doc` normally,
  // matching the working pattern already proven in mainmatter.typ's
  // begin-chapters().
  set heading(numbering: if numbered-sections { "1.1.A." } else { none })

  // letterhead
  if type(from) == dictionary {
    text(font: theme.sans, size: 9pt)[
      #smallcaps(from.at("name", default: "")) \
      #from.at("title", default: none) #if "title" in from [\ ]
      #from.at("org", default: none) #if "org" in from [\ ]
      #from.at("address", default: none) #if "address" in from [\ ]
      #from.at("email", default: none)
    ]
  } else { from }
  v(2em)
  if date == auto { datetime.today().display("[month repr:long] [day], [year]") } else { date }
  v(1.5em)
  if to != none { to; v(1.5em) }
  if re != none { text(weight: "semibold", [Re: #re]); v(1em) }
  if salutation != none { salutation; v(0.8em) }

  doc

  v(2em)
  closing
  if signature != none { v(0.4em); signature }
  if enclosures.len() > 0 { v(1.5em); text(size: 9pt, [#labels.enclosures: #enclosures.join(", ")]) }
  if cc.len() > 0 { v(0.3em); text(size: 9pt, [#labels.cc: #cc.join(", ")]) }
}
