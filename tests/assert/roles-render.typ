// compiles = passes: helpers must accept body-first / theme: auto signatures
// and must NOT need a class installed (fall back to default-theme)
#import "@local/tuftelike:0.1.0": newthought, tufte-quote, base-style, resolve-theme, resolve-labels
#show: base-style.with(resolve-theme((raw: (font: ("Menlo",)))), resolve-labels((:)), 0mm)
#newthought[Lead in] and body.
#tufte-quote(attribution: "Someone")[Quoted.]
#tufte-quote[No attribution.]
`inline code` and
```typ
block code
```
