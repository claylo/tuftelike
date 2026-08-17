#import "@preview/marginalia:0.3.1" as marginalia
#import "../geometry.typ": resolve-target
#import "../themes.typ": resolve-theme, role, role-args, styled
#import "../labels.typ": resolve-labels
#import "../typography.typ": base-style
#import "../notes.typ": footnote-transform

#let letter(
  paper: "us-letter", media: auto, target: auto, targets: (:),
  from: (:),                 // (name:, title:, org:, address:, email:) or content
  to: none, date: auto, re: none, salutation: none,
  closing: "Sincerely,", signature: none,   // content|image|str
  enclosures: (), cc: (),
  numbered-sections: false,
  theme: (:), presets: (:), theme-preset: auto, labels: (:),
  footnotes-as-sidenotes: auto,
  doc,
) = {
  let tg = resolve-target(target: target, targets: targets, media: media, paper: paper,
    theme-preset: theme-preset)
  let media = tg.media
  let paper = tg.paper
  assert("letter-margin" in paper, message: "this class needs a letter-sized paper (us-letter, a4 presets) — \"letter-margin\" missing")
  let theme = resolve-theme(theme, presets: presets, preset: tg.theme-preset)
  let fas = if footnotes-as-sidenotes == auto { paper.note-col > 0mm } else { footnotes-as-sidenotes }
  let labels = resolve-labels(labels)
  let m = paper.letter-margin
  let L = role(theme, "letter")
  // note column occupies the wide right margin; letters are one-sided
  show: marginalia.setup.with(
    inner: (far: m.left, width: 0mm, sep: 0mm),
    outer: (far: m.right - paper.note-col - paper.note-gap, width: paper.note-col, sep: paper.note-gap),
    top: m.top, bottom: m.bottom, book: false)
  set page(width: paper.trim.w, height: paper.trim.h,
    fill: if media == "screen" { theme.screen-bg } else { none },
    header: context if counter(page).get().first() > 1 {
      styled(theme, "letter.runner",
        [#smallcaps(if re != none { re } else { "" }) #h(1fr) #counter(page).display("1")])
    })
  show: base-style.with(theme, labels, paper.note-col + paper.note-gap, media: media)
  // MUST precede all content: ordering-sensitive (spike finding c)
  show: d => if fas { footnote-transform(theme, d) } else { d }
  // helpers read this via current-theme()/current-labels()/current-target() — never thread it
  state("tuftelike").update((media: media, paper: paper, theme: theme, labels: labels,
    target: tg.name, binding: "perfect"))
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
    text(..role-args(theme, "letter.letterhead"))[
      #smallcaps(from.at("name", default: "")) \
      #from.at("title", default: none) #if "title" in from [\ ]
      #from.at("org", default: none) #if "org" in from [\ ]
      #from.at("address", default: none) #if "address" in from [\ ]
      #from.at("email", default: none)
    ]
  } else { from }
  v(L.after-letterhead)
  if date == auto { datetime.today().display("[month repr:long] [day], [year]") } else { date }
  v(L.after-date)
  if to != none { to; v(L.after-to) }
  if re != none { styled(theme, "letter.re", [Re: #re]); v(L.after-re) }
  if salutation != none { salutation; v(L.after-salutation) }

  doc

  v(L.before-closing)
  closing
  if signature != none { v(L.before-signature); signature }
  if enclosures.len() > 0 { v(L.before-enclosures); styled(theme, "letter.meta", [#labels.enclosures: #enclosures.join(", ")]) }
  if cc.len() > 0 { v(L.before-cc); styled(theme, "letter.meta", [#labels.cc: #cc.join(", ")]) }
}
