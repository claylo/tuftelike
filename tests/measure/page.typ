// Measuring fixture: one chapter of lorem + a long sidenote at any paper.
//   typst compile --root . --font-path fonts --input paper=<name> tests/measure/page.typ out/x.pdf
// bin/measure reads the result and reports body/note width, cpl, lines.
#import "@local/tuftelike:0.1.0": *
#let paper = sys.inputs.at("paper", default: "crown-quarto")
#show: book.with(title: "measure", paper: paper, target: "print")
#show: begin-chapters
= Measure
#lorem(120)#sidenote[#lorem(60)]
#lorem(500)
