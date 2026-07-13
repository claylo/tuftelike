#import "@local/tuftelike:0.1.0": spine-width, cover-size, resolve-paper
#assert(spine-width(228, "lulu-standard-bw") == 228 * 0.0572mm)
#let cs = cover-size(resolve-paper("crown-quarto"), 228, "lulu-standard-bw")
#assert(cs.width == 2 * 189mm + 228 * 0.0572mm + 2 * 3.18mm)
#assert(cs.height == 246mm + 2 * 3.18mm)
