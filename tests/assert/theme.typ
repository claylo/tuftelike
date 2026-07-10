#import "@local/tuftelike:0.1.0": default-labels, resolve-labels, default-theme, resolve-theme
#assert(default-labels.chapter == "Chapter")
#assert(resolve-labels((chapter: "Kapitel")).chapter == "Kapitel")
#assert(resolve-labels((chapter: "Kapitel")).appendix == "Appendix") // merge keeps defaults
#assert(default-theme.body-size == 11pt)
#let t = resolve-theme((body-size: 10pt))
#assert(t.body-size == 10pt and t.note-size == 9pt)
#assert(t.serif.first() == "ETbb")
#assert(default-theme.draft == false)
#assert(default-theme.h1-size == 20pt)
#let t2 = resolve-theme((serif: ("Override",)))
#assert(t2.serif == ("Override",)) // arrays replace wholesale
#assert(t2.body-size == 11pt) // untouched keys preserved through array override
