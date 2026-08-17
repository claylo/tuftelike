#import "@local/tuftelike:0.1.0": spine-width, cover-size, resolve-paper, printers
// Lulu paperback spine = pages/444 + 0.06in, PROVEN against four real Lulu
// cover templates: 140→9.53, 180→11.82, 295→18.40, 300→18.69 mm
#let near(a, b) = calc.abs((a - b).mm()) < 0.02
#assert(near(spine-width(140, printer: "lulu"), 9.53mm))
#assert(near(spine-width(180, printer: "lulu"), 11.82mm))
#assert(near(spine-width(295, printer: "lulu"), 18.40mm))
#assert(near(spine-width(300, printer: "lulu"), 18.69mm))
#assert(spine-width(228, printer: "lulu", stock: "lulu-standard-bw") == spine-width(228, printer: "lulu"))   // legacy name → paperback
#let cs = cover-size(resolve-paper("crown-quarto"), 228, stock: "paperback")
#assert(near(cs.width, 2 * 189mm + 14.57mm + 2 * 3.18mm))
#assert(cs.height == 246mm + 2 * 3.18mm)
// the whole cover matches Lulu's template document size at 180pp: 15.595 × 9.93 in
#assert(near(cover-size(resolve-paper("crown-quarto"), 180).width, 396.12mm + 0.1mm) or calc.abs((cover-size(resolve-paper("crown-quarto"), 180).width - 396.12mm).mm()) < 0.3)
#assert(calc.abs((spine-width(250, printer: "kdp", stock: "white") - 14.3mm).mm()) < 0.05)
#assert(spine-width(250, printer: "kdp") == spine-width(250, printer: "kdp", stock: "white"))  // per-printer default stock
#let cq = resolve-paper("crown-quarto")
#assert(cover-size(cq, 200, binding: "coil").width == 2 * cq.trim.w + 2 * cq.bleed)   // no spine
#let k = resolve-paper("kdp-7.5x9.25")
#assert(calc.abs((cover-size(k, 250, stock: "white").width - (2 * 190.5mm + 14.3mm + 2 * 3.175mm)).mm()) < 0.05)
#assert(cover-size(resolve-paper("lulu-us-letter"), 120, binding: "coil").width == 2 * 215.9mm + 2 * 3.175mm)
#assert(printers.lulu.barcode-zone.w == 92mm and printers.kdp.barcode-zone.w == 50.8mm)
