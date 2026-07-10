#import "@local/tuftelike:0.1.0": papers, resolve-paper, resolve-media, page-size, marginalia-config

#let cq = resolve-paper("crown-quarto")
#assert(cq.trim.w == 189mm and cq.trim.h == 246mm)
#assert(resolve-paper((trim: (w: 1mm, h: 2mm))).trim.h == 2mm) // custom dicts pass through

#let ps = page-size(cq, "print")
#assert(ps.width == 189mm + 2 * 3.18mm and ps.height == 246mm + 2 * 3.18mm)
#assert(page-size(cq, "screen").width == 189mm)

#let mc = marginalia-config(cq, "print", page-count-range: "151-400")
#assert(mc.book == true)
#assert(mc.inner.far == 3.18mm + 12.7mm + 13mm)   // bleed + safety + gutter
#assert(mc.outer.far == 3.18mm + 12.7mm)
#assert(mc.outer.width == 37mm and mc.outer.sep == 4mm)
#let ms = marginalia-config(cq, "screen", page-count-range: "151-400")
#assert(ms.book == false and ms.inner.far == 12.7mm + 13mm) // no bleed on screen
#let t69 = resolve-paper("us-trade-6x9")
#assert(t69.trim.w == 152.4mm and t69.note-col == 26mm)
#assert(t69.bleed == 3.175mm and t69.safety == 12.7mm and t69.top-extra == 10mm and t69.bottom-extra == 3mm) // pin tuning baseline
#assert(marginalia-config(cq, "print", page-count-range: "61-150").inner.far == 3.18mm + 12.7mm + 3mm) // gutter param threads through
#let usl = resolve-paper("us-letter")
#assert(usl.letter-margin == (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in))
#assert(usl.handout-margin == (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in))
#assert(resolve-media(media: "print") == "print") // explicit arg wins over sys.inputs
#assert(resolve-media() == "screen") // no --input media set during tests
