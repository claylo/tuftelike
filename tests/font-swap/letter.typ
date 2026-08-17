#import "@local/tuftelike:0.1.0": *
#import "theme.typ": swap-theme
#show: letter.with(
  from: (name: "N", title: "T", org: "O", address: "A", email: "e@x"),
  to: [To], re: "Re line", salutation: [Dear,], closing: "Warmly,", signature: "S",
  enclosures: ("one",), cc: ("two",), numbered-sections: true, theme: swap-theme)
= Heading
#newthought[Lead] body#sidenote[side]#marginnote[margin] `code` #tufte-quote[q]
#figure(table(columns: 1, [h], [b]), caption: [t])
#pagebreak()
Page two carries the runner.
