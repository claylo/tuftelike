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

// ── printers, bleed models, coil (Task 1) ──
#import "@local/tuftelike:0.1.0": printers, resolve-stock
#assert(printers.lulu.bleed-model == "all-sides")
#assert(printers.kdp.bleed-model == "outer-only")
#assert(printers.kdp.gutter-table.at("151-300") == 13mm)
#assert(printers.lulu.coil.inside == 12.7mm)
#assert(printers.kdp.coil == none)
#let lu = (trim: (w: 100mm, h: 200mm), bleed: 3mm, bleed-model: "all-sides", safety: 10mm, note-col: 20mm, note-gap: 2mm, top-extra: 5mm, bottom-extra: 5mm, gutter-table: ("0-60": 1mm), printer: "lulu")
#let kd = lu + (bleed-model: "outer-only", printer: "kdp")
#assert(page-size(lu, "print") == (width: 106mm, height: 206mm))
#assert(page-size(kd, "print") == (width: 103mm, height: 206mm))
#assert(page-size(kd, "screen") == (width: 100mm, height: 200mm))
#assert(marginalia-config(lu, "print", page-count-range: "0-60").inner.far == 3mm + 10mm + 1mm)
#assert(marginalia-config(kd, "print", page-count-range: "0-60").inner.far == 10mm + 1mm)   // no bleed on the bound edge
#assert(marginalia-config(lu, "print", binding: "coil").inner.far == 3mm + 12.7mm)          // coil ignores gutter table
#assert(resolve-stock("lulu", auto) == "paperback" and resolve-stock("kdp", auto) == "white")
#assert(resolve-stock("lulu", "lulu-standard-bw") == "paperback" and resolve-stock("kdp", "kdp-cream") == "cream")

// ── papers generated from trims × printers (Task 2) ──
#let required = ("trim","bleed","safety","note-col","note-gap","top-extra","bottom-extra","gutter-table","printer","tier","status","bindings","bleed-model")
#for (name, p) in papers { for k in required { assert(k in p, message: name + " missing " + k) } }
#assert(papers.len() >= 24)
#assert(resolve-paper("crown-quarto") == resolve-paper("lulu-crown-quarto"))
#assert(resolve-paper("us-trade-6x9") == resolve-paper("lulu-us-trade"))
#assert(resolve-paper("us-letter") == resolve-paper("lulu-us-letter"))
#assert(resolve-paper("kdp-7.5x9.25").trim == (w: 190.5mm, h: 235mm))
#assert(resolve-paper("kdp-7.5x9.25").tier == 1 and resolve-paper("kdp-7.5x9.25").status == "initial")
#assert(resolve-paper("lulu-crown-quarto").status == "proven")
#assert(resolve-paper("kdp-6x9").theme-preset == "tier2")
#assert(resolve-paper("lulu-digest").note-col == 0mm and resolve-paper("lulu-digest").theme-preset == "tier3")
#assert(resolve-paper("lulu-small-landscape").trim.w > resolve-paper("lulu-small-landscape").trim.h)
#assert("coil" in resolve-paper("lulu-us-letter").bindings)
#assert("coil" not in resolve-paper("kdp-8.5x11").bindings)
#assert("letter-margin" in resolve-paper("kdp-8.5x11") and "letter-margin" in resolve-paper("lulu-a4"))
#assert(resolve-paper("kdp-8x10").note-col == 48mm)
#assert(resolve-paper("kdp-7.5x9.25").bleed-model == "outer-only")
#assert(page-size(resolve-paper("kdp-7.5x9.25"), "print").width == 190.5mm + 3.175mm)
