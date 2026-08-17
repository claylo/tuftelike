// All paper geometry is DATA: printers (bleed model, gutter rules, coil,
// spine formulas) × trims → papers named "<printer>-<trim>". Every paper
// carries status: "proven" (a physical proof was measured) or "initial"
// (numbers derived from the proven crown-quarto measure — tune against a
// printed proof before promoting; `just measure <paper>` reports body/note
// width, characters per line, lines per page).
//
// Tiers (see docs/papers.md):
//   1 — full Tufte: 11pt body, 9pt notes, ≥ 37mm note column
//   2 — Tufte at 10pt (theme preset "tier2"), 26–30mm note column
//   3 — no note column (theme preset "tier3"); notes render as footnotes
//
// A custom paper dict passed to resolve-paper needs: trim(w,h), bleed,
// safety, note-col, note-gap, top-extra, bottom-extra, gutter-table; and
// SHOULD carry printer + bleed-model + bindings so covers/coil/targets work.
// Optional: outer-extra, theme-preset, letter-margin, handout-margin.

// ── printers ────────────────────────────────────────────────────────────
// Sources: KDP "Set trim size, bleed, and margins" + "Paperback cover
// specs"; Lulu Book Creation Guide + coil help articles (URLs in
// record/superpowers/specs/2026-08-17-print-sizes-design.md).
#let printers = (
  lulu: (
    bleed: 3.175mm,
    bleed-model: "all-sides",       // interior page = trim + 2×bleed on both axes
    safety: 12.7mm,
    // additive gutter over safety, by page count (Lulu guide table)
    gutter-table: ("0-60": 0mm, "61-150": 3mm, "151-400": 13mm, "401-600": 16mm, "over-600": 19mm),
    // coil bites ~9mm; Lulu suggests a 12.7mm inside margin, no gutter table
    coil: (inside: 12.7mm, min-pages: 2, max-pages: 470),
    spine: (
      // PROVEN: back-derived from the prototype's real Lulu cover template
      // (13.03mm at ~228pp). Lulu's published formula (below) is ~11%
      // thicker — check Lulu's generated template for your page count.
      "standard-bw": (per-page: 0.0572mm, plus: 0mm),
      // Lulu Book Creation Guide, paperback: pages/444 + 0.06in
      "guide-formula": (per-page: 1mm / 17.48, plus: 1.524mm),
    ),
    default-range: "151-400",       // page-count-range: auto lands here
    spine-text-min-pages: 81,       // "80 pages or fewer: no spine text"
    min-pages: 32,
    cover-safety: 12.7mm,
  ),
  kdp: (
    bleed: 3.175mm,
    bleed-model: "outer-only",      // interior page = trim + 2×bleed tall, trim + 1×bleed wide
    safety: 12.7mm,                 // KDP min is 6.4 (9.6 with bleed); we keep the proven 12.7
    // KDP publishes TOTAL inside minimums (9.6/12.7/15.9/19.1/22.3mm); these
    // additive-over-safety extras reproduce the proven crown-quarto feel and
    // clear every minimum
    gutter-table: ("24-150": 3mm, "151-300": 13mm, "301-500": 14mm, "501-700": 16mm, "701-828": 19mm),
    coil: none,
    spine: (
      "white": (per-page: 0.0572mm, plus: 0mm),          // 0.002252 in/page
      "cream": (per-page: 0.0635mm, plus: 0mm),          // 0.0025 in/page
      "premium-color": (per-page: 0.0596mm, plus: 0mm),  // 0.002347 in/page
    ),
    default-range: "151-300",
    spine-text-min-pages: 80,       // "more than 79 pages"
    min-pages: 24,
    cover-safety: 3.2mm,            // KDP minimum; text still sits at 12.7mm like Lulu
  ),
)

// stock: auto → the printer's first (default) stock; legacy "<printer>-<stock>"
// names ("lulu-standard-bw", "kdp-white") are accepted and stripped
#let resolve-stock(printer, stock) = {
  assert(printer in printers, message: "unknown printer \"" + printer + "\" — " + printers.keys().join(", "))
  let table = printers.at(printer).spine
  let s = if stock == auto { table.keys().first() }
    else if stock.starts-with(printer + "-") { stock.slice(printer.len() + 1) }
    else { stock }
  assert(s in table, message: "unknown stock \"" + repr(stock) + "\" for " + printer + " — " + table.keys().join(", "))
  s
}

// ── trims → papers ──────────────────────────────────────────────────────
// (name, printer, w, h, tier, note-col, note-gap, top, bottom, status, coil, letter?)
// note-col 0 = tier 3 (no margin column). Widths/heights in mm; the
// crown-quarto row keeps its proven 3.18mm bleed (Lulu nominal is 3.175).
#let lulu-letter-margins = (
  letter-margin: (left: 1in, right: 3in, top: 1.5in, bottom: 1.25in),
  handout-margin: (left: 1in, right: 3.5in, top: 1.5in, bottom: 1.5in),
)
#let a4-letter-margins = (
  letter-margin: (left: 25mm, right: 76mm, top: 38mm, bottom: 32mm),
  handout-margin: (left: 25mm, right: 89mm, top: 38mm, bottom: 38mm),
)
#let T(name, printer, w, h, tier, note-col, note-gap, top, bottom, status: "initial", coil: false, extra: (:)) = (
  name: name, printer: printer, w: w, h: h, tier: tier, note-col: note-col, note-gap: note-gap,
  top: top, bottom: bottom, status: status, coil: coil, extra: extra,
)
#let trims = (
  // ── tier 1: full Tufte ──
  T("lulu-crown-quarto", "lulu", 189mm, 246mm, 1, 37mm, 4mm, 15mm, 3.17mm, status: "proven", coil: true, extra: (bleed: 3.18mm)),
  T("kdp-7.44x9.69",     "kdp", 189mm, 246.1mm, 1, 37mm, 4mm, 15mm, 3.17mm),
  T("kdp-7.5x9.25",      "kdp", 190.5mm, 235mm, 1, 37mm, 4mm, 15mm, 3.17mm),
  T("lulu-executive",    "lulu", 178mm, 254mm, 1, 37mm, 4mm, 15mm, 3.17mm, coil: true),
  T("kdp-7x10",          "kdp", 177.8mm, 254mm, 1, 37mm, 4mm, 15mm, 3.17mm),
  T("kdp-8x10",          "kdp", 203.2mm, 254mm, 1, 48mm, 5mm, 15mm, 3.17mm),
  T("lulu-us-letter",    "lulu", 215.9mm, 279.4mm, 1, 2in, 0.5in, 25.4mm, 19mm, coil: true, extra: lulu-letter-margins),
  T("kdp-8.5x11",        "kdp", 215.9mm, 279.4mm, 1, 2in, 0.5in, 25.4mm, 19mm, extra: lulu-letter-margins),
  T("lulu-a4",           "lulu", 210mm, 297mm, 1, 48mm, 12mm, 25.4mm, 19mm, coil: true, extra: a4-letter-margins),
  T("kdp-a4",            "kdp", 210mm, 297mm, 1, 48mm, 12mm, 25.4mm, 19mm, extra: a4-letter-margins),
  T("lulu-small-landscape", "lulu", 228.6mm, 177.8mm, 1, 66mm, 8mm, 12mm, 3.17mm, coil: true),  // landscape: wide margin, Tufte-quarto style
  T("kdp-8.25x6",        "kdp", 209.6mm, 152.4mm, 1, 52mm, 6mm, 10mm, 3mm),                          // landscape
  // ── tier 2: Tufte at 10pt ──
  T("lulu-us-trade",     "lulu", 152.4mm, 228.6mm, 2, 26mm, 4mm, 10mm, 3mm, coil: true),
  T("kdp-6x9",           "kdp", 152.4mm, 228.6mm, 2, 26mm, 4mm, 10mm, 3mm),
  T("lulu-royal",        "lulu", 156mm, 234mm, 2, 27mm, 4mm, 10mm, 3mm, coil: true),
  T("kdp-6.14x9.21",     "kdp", 156mm, 234mm, 2, 27mm, 4mm, 10mm, 3mm),
  T("kdp-6.69x9.61",     "kdp", 170mm, 244mm, 2, 30mm, 4mm, 12mm, 3mm),
  T("lulu-comic",        "lulu", 168mm, 260mm, 2, 30mm, 4mm, 12mm, 3mm, coil: true),
  // ── tier 3: no note column (notes → footnotes) ──
  T("lulu-digest",       "lulu", 139.7mm, 215.9mm, 3, 0mm, 0mm, 10mm, 3mm, coil: true),
  T("kdp-5.5x8.5",       "kdp", 139.7mm, 215.9mm, 3, 0mm, 0mm, 10mm, 3mm),
  T("lulu-a5",           "lulu", 148mm, 210mm, 3, 0mm, 0mm, 10mm, 3mm, coil: true, extra: (outer-extra: 12mm)),
  T("lulu-novella",      "lulu", 127mm, 203.2mm, 3, 0mm, 0mm, 10mm, 3mm, coil: true),
  T("kdp-5x8",           "kdp", 127mm, 203.2mm, 3, 0mm, 0mm, 10mm, 3mm),
  T("kdp-5.25x8",        "kdp", 133.4mm, 203.2mm, 3, 0mm, 0mm, 10mm, 3mm),
  T("kdp-5.06x7.81",     "kdp", 128.5mm, 198.4mm, 3, 0mm, 0mm, 10mm, 3mm),
  T("lulu-pocketbook",   "lulu", 108mm, 175mm, 3, 0mm, 0mm, 8mm, 3mm, coil: true, extra: (theme-preset: "tier3-small")),
)

#let paper-from-trim(t) = {
  let pr = printers.at(t.printer)
  let base = (
    trim: (w: t.w, h: t.h),
    bleed: pr.bleed, bleed-model: pr.bleed-model, safety: pr.safety,
    note-col: t.note-col, note-gap: t.note-gap,
    top-extra: t.top, bottom-extra: t.bottom,
    outer-extra: if t.tier == 3 { 6mm } else { 0mm },
    gutter-table: pr.gutter-table,
    printer: t.printer, tier: t.tier, status: t.status,
    bindings: if t.coil and pr.coil != none { ("perfect", "coil") } else { ("perfect",) },
  )
  let preset = if t.tier == 2 { (theme-preset: "tier2") } else if t.tier == 3 { (theme-preset: "tier3") } else { (:) }
  base + preset + t.extra
}

#let papers = {
  let d = (:)
  for t in trims { d.insert(t.name, paper-from-trim(t)) }
  // legacy names (pre printer-keyed presets)
  d.insert("crown-quarto", d.at("lulu-crown-quarto"))
  d.insert("us-trade-6x9", d.at("lulu-us-trade"))
  d.insert("us-letter", d.at("lulu-us-letter"))
  d
}

#let resolve-paper(paper) = {
  if type(paper) == str {
    assert(paper in papers, message: "unknown paper \"" + paper + "\" — available: " + papers.keys().join(", "))
    papers.at(paper)
  } else { paper }
}

// ── media / page geometry ───────────────────────────────────────────────
// Compat form: media input > screen. Inside a class prefer the ambient
// current-media() (set by the resolved build target — see targets below).
#let resolve-media(media: auto) = {
  if media != auto { media }
  else if "media" in sys.inputs { sys.inputs.media }
  else if "target" in sys.inputs { if sys.inputs.target == "screen" { "screen" } else { "print" } }
  else { "screen" }
}

#let page-size(paper, media) = {
  if media != "print" { return (width: paper.trim.w, height: paper.trim.h) }
  let b = paper.bleed
  if paper.at("bleed-model", default: "all-sides") == "outer-only" {
    (width: paper.trim.w + b, height: paper.trim.h + 2 * b)
  } else {
    (width: paper.trim.w + 2 * b, height: paper.trim.h + 2 * b)
  }
}

// Maps a paper onto marginalia's margin model. Inner column carries the
// binding gutter (or the coil inside margin); outer column carries the note
// column. Screen = no bleed, one-sided.
// page-count-range: auto → the paper's printer default band ("151-400" lulu,
// "151-300" kdp); custom dicts without a printer fall back to "151-400" if
// their table has it, else the table's first key
#let default-range(paper) = {
  if "printer" in paper { printers.at(paper.printer).default-range }
  else if "151-400" in paper.gutter-table { "151-400" }
  else { paper.gutter-table.keys().first() }
}
#let marginalia-config(paper, media, page-count-range: auto, binding: "perfect") = {
  let print = media == "print"
  let page-count-range = if page-count-range == auto { default-range(paper) } else { page-count-range }
  let b = if print { paper.bleed } else { 0mm }
  // outer-only bleed (KDP): the bound edge carries no bleed
  let b-inner = if print and paper.at("bleed-model", default: "all-sides") == "all-sides" { b } else { 0mm }
  let inner-far = if binding == "coil" {
    let pr = printers.at(paper.at("printer", default: "lulu"))
    assert(pr.coil != none, message: "printer \"" + paper.printer + "\" does not offer coil binding")
    b-inner + pr.coil.inside
  } else {
    // no default: a typo'd page-count-range must FAIL LOUDLY, not silently
    // produce a 0mm binding gutter (0mm is a legitimate value for short
    // books, so a silent fallback would be indistinguishable from a real one)
    b-inner + paper.safety + paper.gutter-table.at(page-count-range)
  }
  (
    inner: (far: inner-far, width: 0mm, sep: 0mm),
    outer: (far: b + paper.safety + paper.at("outer-extra", default: 0mm), width: paper.note-col, sep: paper.note-gap),
    top: b + paper.safety + paper.top-extra,
    bottom: b + paper.safety + paper.bottom-extra,
    book: print,
  )
}

// ── build targets ───────────────────────────────────────────────────────
// One source, several outputs. A target is (media, paper, binding,
// theme-preset, page-count-range) — any subset; unset keys fall back to
// the class arguments. Callers add their own to the built-ins via
// `targets:` and flip them with --input target=<name>.
#let built-in-targets = (screen: (media: "screen"), print: (media: "print"))

// Resolution: target: arg > --input target= > --input media= (compat: names a
// built-in) > "screen". theme-preset: arg > --input theme= > target > paper.
#let resolve-target(target: auto, targets: (:), media: auto, paper: "crown-quarto",
                    binding: "perfect", theme-preset: auto, page-count-range: auto) = {
  let all = built-in-targets + targets
  let name = if target != auto { target }
    else if "target" in sys.inputs { sys.inputs.target }
    else if "media" in sys.inputs { sys.inputs.media }
    else { "screen" }
  assert(name in all, message: "unknown target \"" + name + "\" — available: " + all.keys().join(", "))
  let t = all.at(name)
  let m = t.at("media", default: if media == auto { "screen" } else { media })
  let p = resolve-paper(t.at("paper", default: paper))
  let bd = t.at("binding", default: binding)
  if "bindings" in p {
    assert(bd in p.bindings, message: "paper does not support binding \"" + bd + "\" — " + p.bindings.join(", "))
  }
  let tp = if theme-preset != auto { theme-preset }
    else if "theme" in sys.inputs { sys.inputs.theme }
    else { t.at("theme-preset", default: p.at("theme-preset", default: none)) }
  let pcr = t.at("page-count-range", default: page-count-range)
  (name: name, media: m, paper: p, binding: bd, theme-preset: tp,
   page-count-range: if pcr == auto { default-range(p) } else { pcr })
}

// ambient accessors (inside context; classes publish these to state)
#let current-target() = {
  let s = state("tuftelike").get()
  if s == none { (name: "screen", media: "screen", paper: none, binding: "perfect") }
  else { (name: s.at("target", default: "screen"), media: s.at("media", default: "screen"),
          paper: s.at("paper", default: none), binding: s.at("binding", default: "perfect")) }
}
#let current-media() = current-target().at("media", default: "screen")
#let current-paper() = current-target().at("paper", default: none)
