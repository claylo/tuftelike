#import "@local/tuftelike:0.1.0": *
#import "theme.typ": swap-theme
#show: handout.with(title: "Handout", subtitle: "Sub",
  authors: ((name: "N", role: "R", affiliation: "Aff", email: "e@x"),),
  abstract: [Abstract.], document-number: "DOC-1", distribution: "All",
  footer-content: ([first], [rest]), toc: true, theme: swap-theme)
= Heading
#newthought[Lead] body#sidenote[side]#marginnote[margin] `code` #tufte-quote[q]
#figure(table(columns: 1, [h], [b]), caption: [t])
#pagebreak()
Page two.
