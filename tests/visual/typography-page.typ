#import "@local/tuftelike:0.1.0": resolve-theme, resolve-labels, base-style, lead-smallcaps

#let theme = resolve-theme((:))
#let labels = resolve-labels((:))

#set page(margin: 2cm)
#show: base-style.with(theme, labels, 0mm)

= Heading Level 1
== Heading Level 2
=== Heading Level 3
==== Heading Level 4
===== Heading Level 5

#lead-smallcaps("Call me Ishmael, or something") is how a Tufte-style chapter
opener begins its first paragraph, with the lead-in words rendered in small
capitals before settling into normal running text for the remainder of the
paragraph.

#quote(block: true, attribution: [Herman Melville])[
  Call me Ishmael. Some years ago—never mind how long precisely—having little
  or no money in my purse, and nothing particular to interest me on shore, I
  thought I would sail about a little and see the watery part of the world.
]
