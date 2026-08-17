#import "@local/tuftelike:0.1.0": *
#let T = (kdp: (media: "print", paper: "kdp-8x10"), custom: (media: "print", paper: "lulu-us-letter", binding: "coil"))
#let r = resolve-target(target: "custom", targets: T, paper: "crown-quarto")
#assert(r.name == "custom" and r.media == "print" and r.binding == "coil" and r.paper.printer == "lulu")
#assert(resolve-target(targets: T, paper: "crown-quarto").name == "screen")            // no input, no arg
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9").paper.printer == "kdp")
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9").theme-preset == "tier2") // paper recommends
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9", theme-preset: "trade").theme-preset == "trade") // arg wins
#assert(resolve-target(target: "print", targets: T, paper: "kdp-7.5x9.25").theme-preset == none)
// ambient inside a class
#[
  #show: book.with(title: "T", paper: "kdp-7.5x9.25", targets: T, target: "kdp")
  #show: begin-chapters
  = One
  #context assert(current-target().name == "kdp")
  #context assert(current-media() == "print")
  #context assert(current-paper().trim.w == 203.2mm)
  #context assert(current-theme().body.size == 11pt)
]
#pagebreak()
#[
  // tier-2 paper recommends its type preset when nothing else is chosen
  #show: book.with(title: "T2", paper: "kdp-6x9", target: "print")
  #show: begin-chapters
  = One
  #context assert(current-theme().body.size == 10pt)
]
