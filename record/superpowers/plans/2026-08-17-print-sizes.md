# Print Sizes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every mainstream Lulu/KDP trim as a `<printer>-<trim>` paper preset with tiered Tufte geometry, printer-correct bleed/gutter/spine, perfect + coil binding, build targets replacing `--input media=`, covers that follow, a measuring tool, tests, docs.

**Architecture:** `geometry.typ` gains a `printers` table and generates `papers` from a `trims` table × printer (bleed model, gutter table copied in). Classes resolve a **target** (media/paper/binding/theme-preset/page-count-range) via `resolve-target` and publish it to `state("tuftelike")`; media-dependent code reads that. Tier 2/3 type is `theme-presets` (`tier2`/`tier3` + per-paper aliases) that a paper can recommend. Tier 3 = zero note column; notes degrade to footnotes ambiently. `cover()` reads printer spine formulas. `bin/measure` reports cpl/lines per paper.

**Tech Stack:** Typst 0.15, marginalia 0.3.1, tiaoma, bash + mutool/pdfinfo.

**Spec:** `record/superpowers/specs/2026-08-17-print-sizes-design.md`

## Global Constraints

- All new papers land `status: "initial"`; only `lulu-crown-quarto` is `"proven"`.
- Existing names `crown-quarto`, `us-trade-6x9`, `us-letter` keep working (aliases). `us-trade-6x9` → lulu.
- Compat: `--input media=screen|print` keeps working (maps to built-in targets). `screen` is the no-flag default.
- Parity: `just snapshot before` at start; after everything, `just parity before` must show `matrix-book-print.pdf`, `matrix-book-screen.pdf`, `matrix-letter-*`, `matrix-handout-*`, `matrix-cover.pdf`, `matrix-template.pdf` **identical** (aliases → same geometry; screen unaffected).
- Lint (`tests/lint-hardcoded.sh`) stays clean — geometry literals live in `geometry.typ` (it is NOT excluded from lint, but its literals are `mm`/`in`, and the lint pattern only flags `size:/tracking:/above:/…: N(pt|em|mm)` — verify; if geometry keys collide, extend the lint's exclude to `src/geometry.typ` with a comment).
- No `git commit`; write `commit.txt` per task (Clay runs `gtxt`). Don't touch `typst.toml` versions.
- Typst gotchas: `set`/`show` inside `if{}` don't escape; state is readable only in `context`; `pagebreak` inside `context` — Task 0 probes it; `text(fill: auto)` invalid; imports file-scoped.

---

### Task 0: Snapshot + two probes

- [ ] `just test && just snapshot before`
- [ ] **Probe A — pagebreak inside context** (decides ambient `begin-chapters`):

```typ
// out/probe-pb.typ
#set page(width: 100mm, height: 100mm)
#let s = state("m", "print")
A
#context { if s.get() == "print" { pagebreak(to: "odd", weak: true) } }
#metadata(none) <mark>
B
#context assert(query(<mark>).first().location().page() == 3)
```
`typst compile out/probe-pb.typ out/x.pdf` → must compile (B lands on page 3). If it fails, ambient media for `begin-chapters` is off the table: keep `begin-chapters(media, doc)` explicit and make `resolve-media()` smarter (Task 5 has both branches).
- [ ] **Probe B — marginalia zero column** already done (compiles; body 25→120mm on 140mm page). Record in plan: tier 3 stays on marginalia.

---

### Task 1: `printers` table + bleed models + spine formulas (`geometry.typ`, `cover.typ`)

**Files:** `src/geometry.typ`, `src/cover.typ`, `src/lib.typ`, `tests/assert/geometry.typ`, `tests/assert/cover.typ`

**Produces:** `printers` (dict), `page-size(paper, media)` honoring `paper.bleed-model`, `marginalia-config(paper, media, page-count-range:, binding: "perfect")`, `spine-width(page-count, printer: "lulu", stock: auto)`, `cover-size(paper, page-count, stock: auto, binding: "perfect")`, `resolve-stock(printer, stock)`.

- [ ] **Failing tests** — append to `tests/assert/geometry.typ`:
```typ
#import "@local/tuftelike:0.1.0": printers, page-size, marginalia-config, resolve-paper
#assert(printers.lulu.bleed-model == "all-sides")
#assert(printers.kdp.bleed-model == "outer-only")
#assert(printers.kdp.gutter-table.at("151-300") == 13mm)
#assert(printers.lulu.coil.inside == 12.7mm)
// bleed models
#let lu = (trim: (w: 100mm, h: 200mm), bleed: 3mm, bleed-model: "all-sides", safety: 10mm, note-col: 20mm, note-gap: 2mm, top-extra: 5mm, bottom-extra: 5mm, gutter-table: ("0-60": 1mm), printer: "lulu")
#let kd = lu + (bleed-model: "outer-only", printer: "kdp")
#assert(page-size(lu, "print") == (width: 106mm, height: 206mm))
#assert(page-size(kd, "print") == (width: 103mm, height: 206mm))
#assert(page-size(kd, "screen") == (width: 100mm, height: 200mm))
#assert(marginalia-config(lu, "print", page-count-range: "0-60").inner.far == 3mm + 10mm + 1mm)
#assert(marginalia-config(kd, "print", page-count-range: "0-60").inner.far == 10mm + 1mm)   // no bleed on the bound edge
#assert(marginalia-config(lu, "print", binding: "coil").inner.far == 3mm + 12.7mm)          // coil ignores gutter table
```
and to `tests/assert/cover.typ`:
```typ
#import "@local/tuftelike:0.1.0": spine-width, cover-size, resolve-paper
#assert(calc.abs((spine-width(228, printer: "lulu", stock: "standard-bw") - 13.04mm).mm()) < 0.05)
#assert(calc.abs((spine-width(228, printer: "lulu", stock: "guide-formula") - 14.57mm).mm()) < 0.05)
#assert(calc.abs((spine-width(250, printer: "kdp", stock: "white") - 14.3mm).mm()) < 0.05)
#assert(spine-width(250, printer: "kdp") == spine-width(250, printer: "kdp", stock: "white"))  // per-printer default stock
#assert(spine-width(200, printer: "lulu", stock: "lulu-standard-bw") == spine-width(200, printer: "lulu", stock: "standard-bw")) // legacy name
#let cq = resolve-paper("crown-quarto")
#assert(cover-size(cq, 200, binding: "coil").width == 2 * cq.trim.w + 2 * cq.bleed)   // no spine
```
Keep every existing assertion in both files (update `spine-width(…, "lulu-standard-bw")` positional calls to the new keyword form).
- [ ] **Implement `printers`** exactly as spec §1 (Lulu spine `guide-formula` per-page = `1mm / 17.48`, plus `1.524mm`). Add `resolve-stock(printer, stock)`: `auto` → first key of that printer's spine table (`standard-bw` / `white`); legacy `lulu-standard-bw`/`kdp-white`/`kdp-cream` strip the printer prefix.
- [ ] **`page-size`**: `if media != "print" {trim} else if bleed-model == "outer-only" {(w + b, h + 2b)} else {(w + 2b, h + 2b)}`. Missing `bleed-model` → treat as `all-sides` (custom dicts).
- [ ] **`marginalia-config(paper, media, page-count-range: "151-400", binding: "perfect")`**: `let inner-bleed = if media == "print" and paper.at("bleed-model", default: "all-sides") == "all-sides" { b } else { 0mm }`; gutter = if binding == "coil" { `printers.at(paper.printer).coil.inside - paper.safety` … } — simpler: `inner far = if coil { b-inner + printers.<p>.coil.inside } else { b-inner + safety + gutter-table.at(range) }`. Assert coil supported: `printers.at(paper.printer).coil != none`.
- [ ] **cover.typ**: remove `stocks`; `spine-width(page-count, printer: "lulu", stock: auto)`, `cover-size(paper, page-count, stock: auto, binding: "perfect")` (spine 0 when coil), spine-text threshold from `printers.<p>.spine-text-min-pages` (replaces `page-count >= 80`), `cover(... stock: auto, binding: "perfect", ...)` derives printer from `paper.printer` (custom dicts without `printer` → assert asking for it, or accept `printer:` arg — add `printer: auto` arg to `cover()`).
- [ ] Run both assert files → PASS. `commit.txt`: `feat(geometry): printers table (lulu/kdp) with bleed models, gutter tables, coil, spine formulas`

---

### Task 2: `trims` × printers → `papers`; aliases; tier presets

**Files:** `src/geometry.typ`, `src/themes.typ`, `tests/assert/geometry.typ`, `tests/assert/theme.typ`

**Produces:** `papers` with every name in spec §2 (+ aliases), each dict carrying `printer, tier, status, bindings, bleed-model, gutter-table, trim, bleed, safety, note-col, note-gap, top-extra, bottom-extra, outer-extra (tier 3), theme-preset (tier 2/3), letter-margin/handout-margin (letter-sized only)`; `theme-presets.tier2/tier3` + per-paper aliases; `paper-names()` helper for error messages.

- [ ] **Failing tests** — geometry:
```typ
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
```
theme: `#assert(theme-presets.tier2.body.size == 10pt)`, `#assert(theme-presets.at("kdp-6x9") == theme-presets.tier2)`, `#assert(theme-presets.tier3.body.size == 10pt)`, `#assert(theme-presets.at("lulu-a5") == theme-presets.tier3)`.
- [ ] **Implement** `trims` as a list of dicts `(name, printer, w, h, tier, note-col, note-gap, top, bottom, status, coil, letter-margins, note)`, values from spec §2 tables; `papers` built with a `for` loop into a dict; tier 3 rows get `note-col: 0mm, note-gap: 0mm, outer-extra: 6mm`; tier 2/3 rows get `theme-preset: "tier2"/"tier3"`; letter-sized (us-letter, a4, 8.5x11) rows get `letter-margin`/`handout-margin` (a4: `(left: 25mm, right: 76mm, top: 38mm, bottom: 32mm)` letter, `(left: 25mm, right: 89mm, top: 38mm, bottom: 38mm)` handout). Aliases appended: `crown-quarto`, `us-trade-6x9`, `us-letter`. `resolve-paper(name)` asserts unknown names with `papers.keys()`. `outer-extra` (default 0mm) is added to `marginalia-config`'s outer far.
- [ ] **themes.typ**: `tier2 = (body: (size: 10pt), note: (size: 8.5pt), caption: (size: 8.5pt), table-body: (size: 8.5pt), index: (size: 8.5pt))`; `tier3 = (body: (size: 10pt), caption: (size: 8.5pt), table-body: (size: 8.5pt))`; alias every tier 2/3 paper name from `papers`. Note the import direction: `themes.typ` must not import `geometry.typ` if geometry imports themes — currently neither imports the other; themes may import geometry for the alias loop (`#import "geometry.typ": papers`). Keep it one-directional.
- [ ] Tests PASS. `commit.txt`: `feat(geometry): every mainstream lulu/kdp trim as <printer>-<trim> paper presets, tiered; tier2/tier3 type presets`

---

### Task 3: Build targets — `resolve-target`, class wiring, ambient media/paper

**Files:** `src/geometry.typ` (or new `src/targets.typ`), `src/classes/{book,letter,handout}.typ`, `src/cover.typ`, `src/mainmatter.typ`, `src/lib.typ`, `tests/assert/targets.typ`

**Produces:** `built-in-targets = (screen: (media: "screen"), print: (media: "print"))`; `resolve-target(target: auto, targets: (:), media: auto, paper:, binding:, theme-preset:, page-count-range:) -> (name, media, paper (resolved dict), binding, theme-preset, page-count-range)`; `current-target()`, `current-media()`, `current-paper()` (context accessors); `resolve-media(media: auto)` compat (media input > target input if it's a built-in name > screen); `begin-chapters(doc, media: auto)`, `chapters(srcs, …, media: auto)`, `appendices(…, media: auto)`, `chapter-break(media, split)` unchanged internal.

- [ ] **Failing test** `tests/assert/targets.typ`:
```typ
#import "@local/tuftelike:0.1.0": *
#let T = (kdp: (media: "print", paper: "kdp-8x10"), custom: (media: "print", paper: "lulu-us-letter", binding: "coil"))
#let r = resolve-target(target: "custom", targets: T, paper: "crown-quarto")
#assert(r.name == "custom" and r.media == "print" and r.binding == "coil" and r.paper.printer == "lulu")
#assert(resolve-target(targets: T, paper: "crown-quarto").name == "screen")            // no input, no arg
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9").paper.printer == "kdp")
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9").theme-preset == "tier2") // paper recommends
#assert(resolve-target(target: "print", targets: T, paper: "kdp-6x9", theme-preset: "trade").theme-preset == "trade") // arg wins
// ambient inside a class
#[
  #show: book.with(title: "T", paper: "kdp-7.5x9.25", targets: T, target: "kdp")
  #show: begin-chapters
  = One
  #context assert(current-target().name == "kdp")
  #context assert(current-media() == "print")
  #context assert(current-paper().trim.w == 203.2mm)
]
```
Also a compile-only fixture `tests/assert/targets-input.typ` run by the assert loop with `--input target=custom` is NOT possible (loop has no inputs) — instead Task 7's paper-matrix exercises `--input target=`.
- [ ] **Implement `resolve-target`** (in geometry.typ next to resolve-media): `all = built-in-targets + targets`; `name = target if != auto else sys.inputs.target if present else (if sys.inputs.media present: that name) else "screen"`; assert `name in all`; `t = all.at(name)`; `media = t.at("media", default: media-arg-or-"screen")`; `paper = resolve-paper(t.at("paper", default: paper-arg))`; `binding = t.at("binding", default: binding-arg)`; assert binding in paper.bindings (custom dicts w/o `bindings` → allow); `theme-preset = theme-preset-arg if != auto else sys.inputs.theme if present else t.at("theme-preset", default: paper.at("theme-preset", default: none))`; `page-count-range` likewise (t > arg). Return dict.
- [ ] **Classes**: `book(... media: auto, paper: "crown-quarto", binding: "perfect", target: auto, targets: (:), page-count-range: "151-400", theme-preset: auto ...)`: `let tg = resolve-target(...)`; `let media = tg.media; let paper = tg.paper; …`; theme resolves with `preset: tg.theme-preset` (note: pass a concrete value, `resolve-theme` still accepts `none`); `marginalia-config(paper, media, page-count-range: tg.page-count-range, binding: tg.binding)`; state gains `target: tg.name, binding: tg.binding` (media/paper already there). Same for letter/handout (they don't use page-count-range/binding but take `target/targets` for media+paper). `cover(... target: auto, targets: (:), binding: "perfect", stock: auto)`.
- [ ] **mainmatter.typ**: if Probe A passed — `begin-chapters(doc, media: auto)`: `context { let m = if media == auto { current-media() } else { media }; if m == "print" { pagebreak(to: "odd", weak: true) } }` then the marker/counter/set/doc as before (the `set heading(numbering)` must stay OUTSIDE context — keep it after the context block, in the function body). `chapters(..., media: auto)`: the break-md string needs media at build time (not in context) — resolve via `context` around the whole `md(...)` call? md output inside context is fine (content). But `chapters` returns a huge context block — acceptable. If Probe A FAILED: keep positional media, and `resolve-media()` becomes: media input > (target input in built-ins → its media; unknown target name → "print") > screen; document that custom screen-media targets must pass media explicitly.
- [ ] **`resolve-media(media: auto)`** compat implemented per above regardless (used by fixtures).
- [ ] Update `examples/book/main.typ`, `template/main.typ`, `tests/font-swap/book.typ`, `tests/assert/ambient*.typ`, `tests/visual/*.typ` call sites: `#show: begin-chapters` (no arg) where inside a class; fixtures that build pages by hand keep `resolve-media()`.
- [ ] `just test` PASS. `commit.txt`: `feat(targets): named build targets (media/paper/binding/theme-preset) via targets: + --input target=; media= kept as alias; ambient begin-chapters`

---

### Task 4: Tier 3 — notes degrade to footnotes; footnotes-as-sidenotes auto

**Files:** `src/notes.typ`, `src/classes/{book,letter,handout}.typ`, `tests/assert/tier3.typ`

- [ ] **Failing test**:
```typ
#import "@local/tuftelike:0.1.0": *
#show: book.with(title: "T3", paper: "lulu-digest", target: "print")
#show: begin-chapters
= One
#context assert(current-paper().note-col == 0mm)
Body#sidenote[becomes a footnote] and#marginnote[also a footnote] and real#footnote[stays a footnote].
// must NOT crash; the page must carry a footnote separator: query footnote entries
#context assert(query(footnote).len() == 3)
```
- [ ] **notes.typ**: `sidenote`/`marginnote` become `context { if current-paper().note-col == 0mm { footnote(body) /* marginnote: numbering: none? footnote has no unnumbered mode → use footnote(numbering: …) with a `set footnote(numbering: "*")`? Simplest honest: both become numbered footnotes; document */ } else { marginalia.note(...) } }` — but `marginalia.note` inside `context` was verified fine in Task 3 of the theme plan (note-body already is a context). Add `current-paper()` to geometry.typ (state read, default `papers.crown-quarto`… no: default `none` and treat as "has notes"). `notefigure`/`wideblock` in tier 3: assert with message "paper has no note column — use figure()/plain block".
- [ ] **Classes**: `footnotes-as-sidenotes: auto` → `false` when `paper.note-col == 0mm`, else `true`. When false, `footnote-transform` is not installed → real footnotes; and since sidenote→footnote in tier 3, no loop.
- [ ] Test PASS. `commit.txt`: `feat(tier3): zero-note-column papers render notes as footnotes; footnotes-as-sidenotes: auto`

---

### Task 5: `bin/measure` + `just measure`

**Files:** `bin/measure`, `tests/measure/page.typ`, `justfile`

- [ ] `tests/measure/page.typ`:
```typ
#import "@local/tuftelike:0.1.0": *
#let paper = sys.inputs.at("paper", default: "crown-quarto")
#show: book.with(title: "measure", paper: paper, target: "print")
#show: begin-chapters
= Measure
#lorem(400)#sidenote[#lorem(40)]
#lorem(400)
```
- [ ] `bin/measure <paper> [--all]`: compiles with `--root . --font-path fonts --input paper=<p>`, then from `mutool draw -F stext` of the first body page (page with the heading; find via text "Measure") computes: page size (pt→mm), body column left/right = min/max x over lines wider than 60% of the modal width, body width mm, cpl = mean `len(text)` of those lines, note column = lines whose left ≥ body right (min/max), lines per page. Prints one row: `paper  tier  status  page(mm)  body(mm)  cpl  note(mm)  ncpl  lines`. `--all` iterates `typst query`? No — iterate names from a static list generated by `typst eval`?: simplest: `typst compile` a tiny file that `#metadata(papers.keys())` + `typst query --field value` → names. Use `just measure-all` to table every paper into `out/measure.tsv` and print it. This table is what fills docs/papers.md.
- [ ] `justfile`: `measure paper: bin/measure {{paper}}` and `measure-all: bin/measure --all`.
- [ ] Run `just measure-all`; sanity: crown-quarto ≈ 109.6mm / 59 cpl (memory), kdp-7.5x9.25 ≈ 111mm, kdp-6x9 (tier2) ≈ 84mm/50cpl, lulu-digest (tier3) ≈ 95mm. Adjust spec-table `note-col`/`outer-extra` numbers ONLY if a paper lands outside 45–70 cpl; record what changed in commit.txt.
- [ ] `commit.txt`: `feat(measure): bin/measure + just measure[-all] report body/note width, cpl, lines per paper`

---

### Task 6: Covers per printer/binding + cover matrix

**Files:** `src/cover.typ`, `examples/cover/main.typ`, `tests/assert/cover.typ`, `tests/font-swap/cover.typ`

- [ ] `cover()` final signature: `cover(paper: "crown-quarto", page-count: 200, stock: auto, binding: "perfect", printer: auto, target: auto, targets: (:), background:, front:, spine:, back:, barcode:, theme:, presets:, theme-preset:, labels:)`. Printer = `paper.printer` else `printer:` arg else assert. Coil → `sw = 0mm`, no spine cell, grid is 2 columns. Spine text suppressed below `spine-text-min-pages`. Cover bleed all four sides for both printers (`cover-size` unchanged in that respect).
- [ ] Asserts: cover at `kdp-7.5x9.25` 250pp white → width `2×190.5 + 14.3 + 2×3.175`; coil at `lulu-us-letter` → no spine, width `2×215.9 + 6.35`.
- [ ] `examples/cover/main.typ` builds unchanged (crown-quarto default). Add `examples/cover/kdp.typ` (7.5×9.25, 250pp, cream) and `examples/cover/coil.typ` (lulu-us-letter coil, 120pp) — compiled by Task 7's matrix.
- [ ] `commit.txt`: `feat(cover): per-printer spine/stock, coil covers without spine, spine-text threshold from printer`

---

### Task 7: Paper matrix test + compat matrix + demo recipe

**Files:** `tests/paper-matrix.sh`, `tests/compile-matrix.sh`, `justfile`

- [ ] `tests/paper-matrix.sh`: names via `typst query` on a one-line file (`#import …: papers; #metadata(papers.keys()) <names>`) → for each name compile `template/main.typ` with `--input target=print --input paper=…`? The template doesn't read a paper input — instead compile `tests/measure/page.typ` (it does) with `--input paper=<name>` to `out/paper-<name>.pdf`. Plus: `--input target=custom` build of `examples/book/main.typ` after adding `targets: (kdp: …, coil: (media:"print", paper:"lulu-us-letter", binding:"coil"))` to that example; `examples/cover/kdp.typ`, `examples/cover/coil.typ`. Any compile failure → exit 1.
- [ ] `compile-matrix.sh`: keep the `--input media=` rows (compat coverage), add one `--input target=print` row.
- [ ] `justfile`: `demo target="book" variant="screen" theme=""` → passes `--input target={{variant}}` (built-ins screen/print + the example's own targets); wire `tests/paper-matrix.sh` into `test`.
- [ ] `just test` PASS; `just parity before` → the listed PDFs identical.
- [ ] `commit.txt`: `test(papers): compile every paper preset + target/coil/cover builds in just test`

---

### Task 8: Docs + downstream migration

**Files:** `docs/papers.md`, `README.md`, `record/handoffs/…` (append), `~/source/wiring-guides/src/setup.typ`, `~/source/claylo/failing-to-die/book.typ`, `~/source/claylo/failing-to-die/Justfile`

- [ ] `docs/papers.md`: tiers (why), the full table (from `out/measure.tsv`: paper, printer, trim, tier, status, body mm, cpl, note mm, lines), printer facts + sources (copy spec §Facts), bindings, targets how-to (the wiring-guide 3-output example), `proven`/`initial` and how to promote (proof + `just measure` + flip status + snapshot parity), custom paper dict shape. README: "Paper presets" and "Media" sections → short + link; targets replace the media paragraph (media kept as alias).
- [ ] **wiring-guides** `setup.typ`: drop `chilton`; `book.with(paper: "kdp-8x10", targets: (kdp: (media:"print", paper:"kdp-8x10"), custom: (media:"print", paper:"lulu-us-letter", binding:"coil")))`; note-col was 42 → kdp-8x10 preset is 42 ✓. Justfile builds: `--input target=kdp` / `custom`. Rebuild both; font inventory unchanged.
- [ ] **failing-to-die** `book.typ`: `paper: "kdp-7.5x9.25", page-count-range: "151-300"`, `targets: (kdp: (media: "print", paper: "kdp-7.5x9.25"))`; Justfile `build-print` → `--input target=kdp`. Rebuild; check page count and that the TOC/opener look unchanged vs the 6×9 build except measure.
- [ ] Handoff append: what's `initial`, the measure table, the proof-promotion checklist, the 8×10.5 note.
- [ ] `commit.txt`: `docs(papers): paper/tier/printer/target reference; migrate wiring-guides + failing-to-die to printer-keyed papers`

---

## Self-review

- Spec coverage: §1 printers (T1), §2 trims/papers/tier presets (T2), §3 bindings (T1 marginalia-config coil + T3 target binding + T6 cover), §4 tier 3 (T4), §5 measure (T5), §6 covers (T6), §7 tests (T1/2/3/4/7), §8 docs + wiring/failing-to-die (T8), §9 targets (T3), §10 spine (T1). Squares/hardcover out of scope as spec says.
- Consistency: `resolve-target` returns `(name, media, paper, binding, theme-preset, page-count-range)`; `current-target()/current-media()/current-paper()` names used in T3/T4/T5 fixtures; `spine-width(page-count, printer:, stock:)` used in T1/T6; `begin-chapters(doc, media: auto)` used in T3/T4/T5 fixtures (`#show: begin-chapters`).
- Risk: Probe A decides ambient begin-chapters; both branches written in T3.
