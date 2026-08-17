#import "@local/tuftelike:0.1.0": chapter-heading-rules, part-divider, base-style, footnote-transform, resolve-theme, resolve-labels, resolve-paper, resolve-media, marginalia-config, page-size
#import "@preview/marginalia:0.3.1" as marginalia

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let mc = marginalia-config(paper, media)
#let ps = page-size(paper, media)
#let theme = resolve-theme((:))
#let labels = resolve-labels((:))
#let note-ext = paper.note-col + paper.note-gap
#let icons = ("Quick Try": image("../../examples/_assets/icon-flask.svg"))

#show: marginalia.setup.with(..mc)
#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })
#show: footnote-transform.with(theme)
#show: base-style.with(theme, labels, note-ext)
#show: chapter-heading-rules.with(theme, labels, note-ext, icons: icons)

#set heading(numbering: "1.1.1")

= A Numbered Chapter

Body text under a numbered chapter opener. This paragraph exists to give the
opener some breathing room before the next heading.

=== Quick Try: something with an icon

This level-3 heading should carry the flask icon to its left, since its text
starts with the "Quick Try" key in the icons dict.

=== An icon-free heading

This level-3 heading has no matching key, so it renders with no icon and no
grid layout.

#pagebreak()
#counter(heading).update(0)
#set heading(numbering: "A.1")

= An Appendix

This heading should read "Appendix A", not "Chapter A" — the level-1 rule
detects a leading uppercase letter in the displayed number and swaps the
label word.

#part-divider(2, "The Second Part", theme: theme, labels: labels)
