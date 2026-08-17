#import "@local/tuftelike:0.1.0": spine-width, cover-size, resolve-paper
#assert(spine-width(228, printer: "lulu", stock: "standard-bw") == 228 * 0.0572mm)
#assert(spine-width(228, printer: "lulu", stock: "lulu-standard-bw") == 228 * 0.0572mm)   // legacy name
#let cs = cover-size(resolve-paper("crown-quarto"), 228, stock: "standard-bw")
#assert(cs.width == 2 * 189mm + 228 * 0.0572mm + 2 * 3.18mm)
#assert(cs.height == 246mm + 2 * 3.18mm)
#assert(calc.abs((spine-width(228, printer: "lulu", stock: "guide-formula") - 14.57mm).mm()) < 0.05)
#assert(calc.abs((spine-width(250, printer: "kdp", stock: "white") - 14.3mm).mm()) < 0.05)
#assert(spine-width(250, printer: "kdp") == spine-width(250, printer: "kdp", stock: "white"))  // per-printer default stock
#let cq = resolve-paper("crown-quarto")
#assert(cover-size(cq, 200, binding: "coil").width == 2 * cq.trim.w + 2 * cq.bleed)   // no spine
#let k = resolve-paper("kdp-7.5x9.25")
#assert(calc.abs((cover-size(k, 250, stock: "white").width - (2 * 190.5mm + 14.3mm + 2 * 3.175mm)).mm()) < 0.05)
#assert(cover-size(resolve-paper("lulu-us-letter"), 120, binding: "coil").width == 2 * 215.9mm + 2 * 3.175mm)
