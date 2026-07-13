# Spike Findings: marginalia × cmarker integration

Evidence gathered by compiling `tests/spike/spike.typ` (Typst 0.15.0, `marginalia:0.3.1`,
`cmarker:0.1.10`) to both PDF and PNG in `screen` and `print` media, and reading the
rendered pages. A supplementary isolated probe (not committed; built and run in scratch
space, see (b)) was used to test cross-file `reader` behavior that the main spike file
cannot exercise on its own.

## (a) Exact marginalia param names

Confirmed against the cached package source
(`~/Library/Caches/typst/packages/preview/marginalia/0.3.1/{README.md,lib.typ}`) — no
corrections needed vs. the plan's code, all of it compiled and rendered on the first try:

- `marginalia.setup.with(inner:, outer:, top:, bottom:, book:, clearance:)` — `inner`/`outer`
  are dicts `(far:, width:, sep:)`. Exactly as used in the spike.
- `marginalia.note(counter: none)[...]` is the documented, correct way to disable a note's
  marker. Verified: the "Unnumbered probe" note rendered in the margin with no glyph prefix,
  while every other note got one. No param rename needed.
- Default marker style is **not** numeric. `note()`'s `numbering` parameter defaults to
  `note-numbering`, which cycles through `note-markers-alternating = ("●", "○", "◆", "◇",
  "■", "□", "▲", "△", "♥", "♡")`, rendered small/bold/blue (Inter 5pt) via the counter
  `marginalia.notecounter`. In the spike's 4 default-numbered notes, markers came out
  `●` (native call), `○` (footnote), `◆` (html tag), `◇` (regex) — i.e. exactly
  `note-markers-alternating` in counter order. This is **not a bug** and needs no override:
  the plan's own `notes.typ` draft (Task 6) never sets `numbering:` either, so it already
  targets this default look. Worth flagging only because the Task 2 checklist phrase
  "numbered margin note with superscript anchor" reads as literal Arabic numerals — it
  isn't; "numbered" = "has a counter-driven marker," and the marker sits in a raised
  (superscript-like) position but is a symbol, not a digit. If a future task wants literal
  numerals, the documented override is `numbering: (..i) => super(numbering("1", ..i))`
  (from the package README) — not needed for anything currently planned.
- `marginalia.wideblock[...]` renders correctly for a single-page block (spike's `#rect`
  probe). Did not test a block spanning a pagebreak — see (e) for the related caveat.

## (b) Reader closure vs. bare `read`

**The closure form is required, not stylistic.** `read()`'s relative-path resolution in
Typst is pinned to the source file containing the literal `read(...)` call expression —
not to the file where a function *value* happens to be invoked from. Proven with an
isolated 3-file probe outside the main spike (a `main.typ` + `sub/lib.typ`, where
`lib.typ` receives a `reader` argument and calls `reader("marker.txt")`, and
`marker.txt` exists only next to `main.typ`, not next to `lib.typ`):

- `#let reader = (p, ..a) => read(p, ..a.named())` defined in `main.typ`, passed into
  `lib.typ`'s function → **compiles successfully**, file found relative to `main.typ`.
- `#let reader = read` (bare alias) defined in `main.typ`, passed the same way →
  **fails**: `error: file not found (searched at .../sub/marker.txt)` — Typst resolved
  the path relative to `lib.typ`'s directory (where the `reader(...)` call
  syntactically appears once you inline the alias), not `main.typ`'s.

This is exactly the shape of Task 7's `md()`: the user writes `reader` in their own file
and it gets invoked from inside `src/markdown.typ`. A bare `reader: read` shorthand will
silently break any relative path (images, `<note src="...">`) the moment `md()` lives in
a different file than the caller — which it always will. **Keep the closure form**
`(p, ..a) => read(p, ..a.named())` as mandatory boilerplate; do not offer `read` as a
shorthand in docs or examples.

Within the spike itself (single file, so this particular hazard isn't triggered),
the closure form worked for both call shapes it needs to support:
`reader("spike-content.md")` (text) and `reader(path, encoding: none)` (bytes, for the
image scope handler) — confirmed by the image rendering correctly in all four PNGs.

## (c) Footnote → sidenote viability

**Viable, but the plan's one-line version double-marks, and the fix has two parts, one
of them order-sensitive.** `show footnote: it => sidenote(it.body)` alone does *not*
suppress Typst's native bottom-of-page footnote rendering — it only changes what happens
at the anchor. Result before any fix: the footnote correctly produced a marginalia note
(`○ I should render as a numbered margin note.`) **and** a redundant numbered entry at
the page bottom (`¹I should render as a numbered margin note.` under a horizontal rule).
Confirmed visually in the first compile pass.

**This report went through two rounds — the first "fixed" claim was false and was
caught in review by reading the spike's own generated PNG, not by re-deriving it
independently.** Recording both rounds here because the second issue (the separator
line) would have shipped silently otherwise:

**Round 1 (added `show footnote.entry: none` at its original position, after the
`note-match`/reader setup, i.e. after the first `#sidenote[...]` call earlier in the
document).** This did *not* work — the numbered bottom entry was still present in both
`screen` and `print` PNGs. It was reported as fixed anyway, incorrectly; the person
reviewing this spike caught the contradiction by opening `out/spike-screen-1.png` and
seeing the entry still there, and bisected the actual cause: **`show footnote.entry:
none` fails to suppress the entry if any `marginalia.note()` call (including the
`#sidenote[...]` wrapper) already happened earlier in the document than the show-rule
declaration** — even though normal Typst show-rule scoping says a rule applies to
everything typeset after it, regardless of what ran before. The fix for this part:
declare both footnote show rules immediately after `#set page(...)`, before the very
first note call anywhere in the document (the spike's original structure called
`#sidenote[...]` for "Native note." before declaring the transform).

**Round 2 (after hoisting, re-verified by re-reading the regenerated PNGs myself before
reporting again).** Hoisting fixed the duplicate *text* — "numbered margin note" now
appears exactly once per PDF (confirmed both visually and via `pdftotext | grep -c`,
not just by eye). But a stray *empty* horizontal separator line remained at the page
bottom in both media — the footnote text was gone, the rule above where it used to sit
was not. Fetched Typst's `footnote.entry` reference: it has a separate `separator`
parameter (default `line(length: 30% + 0pt, stroke: 0.05em)`) that is not implied by
`show footnote.entry: none` in this ordering. Fix: also add
`#set footnote.entry(separator: none)`. Verified by cropping the page-bottom band at
400 ppi before and after — line present pre-fix, band fully blank post-fix — and by a
full page-by-page re-read of all four PNGs (screen/print × page 1/2).

Working recipe, in this order, before any note call:

```typ
#show footnote: it => sidenote(it.body)
#show footnote.entry: none
#set footnote.entry(separator: none)
```

**Action needed downstream:** Task 7's `markdown.typ` draft (plan lines 616–619) applies
the footnote show rule *inside* `md()`, conditionally, at whatever point `md()` happens
to be called:
```typ
if footnotes-as-sidenotes {
  show footnote: it => sidenote(theme: theme, it.body)
  out
} else { out }
```
Given the ordering sensitivity above, this placement is unreliable in a real document —
any sidenote fired before `md()` runs (e.g. in frontmatter, an epigraph, a chapter
opener) would put a `marginalia.note()` call ahead of the show-rule declaration and
silently break the suppression again, the same way the original spike did. **The
transform should move out of `md()` and into the class-level style chain** — applied
once, early, before any content (including non-markdown sidenotes) is typeset — with
`md()` keeping only the `footnotes-as-sidenotes` flag for classes to read and act on.
Verdict for the checkpoint: **(c) passed**, footnote→sidenote ships default-ON, but Task
7/8 need the relocation above, not just the two extra lines.

Anchor placement and pagination looked correct throughout: the anchor glyph sits
immediately after "footnote." on the same line as the source text, and the margin note
is vertically adjacent to that line, not shifted to a different paragraph.

## (d) Bleed folding into `far` values

Confirmed working as written: `far: bleed + 12.7mm + …` in both `inner` and `outer`,
plus `top`/`bottom` built the same way, plus `page(width: 189mm + 2 * bleed, height:
246mm + 2 * bleed, …)`. Both media compiled with the same source. Screen (`bleed =
0mm`) produced a 189×246mm page; print (`bleed = 3.18mm`) produced a
195.36×252.36mm page (trim + 2×bleed) with the note column, text column, and top/bottom
margins visually offset outward by the same 3.18mm relative to the trim edge — i.e. the
content sits at the same position relative to the *trim* line in both media, which is
the point of folding bleed into `far` rather than into the page size alone. No separate
bleed-vs-margin arithmetic needed elsewhere.

## (e) `marginalia.header()` vs `page(header:)`/`page(foreground:)` for runners

**Decision: do not use `marginalia.header()`; build runners with plain `page(header:)`
sized to the text column.** Tested by wiring `marginalia.header()` directly into
`page(header: …)`:

```typ
header: marginalia.header(
  text(size: 8pt)[RUNNER-INNER], [],
  text(size: 8pt)[RUNNER-OUTER #context here().page()],
)
```

It does work mechanically: no crash, re-evaluates per page (page number updated
correctly on page 2), and its `(inner, center, outer)` positional args correctly swap
sides between recto/verso in `book: true` mode — verified by reading page 1 vs. page 2 of
the print PNGs (`RUNNER-INNER` left / `RUNNER-OUTER` right on page 1 (odd/recto), swapped
to `RUNNER-OUTER` left / `RUNNER-INNER` right on page 2 (even/verso), matching the note
column's own swap).

Two problems rule it out as the mechanism for this design specifically:

1. `header()` is implemented as a `wideblock` internally, and its column widths are
   hard-pinned to the *same* `inner.width`/`outer.width` used for the note columns. This
   spike's margin config sets `inner: (width: 0mm, …)` (no inner note column by design).
   Feeding that same 0mm width to a header column forced `RUNNER-INNER` to wrap
   character-by-character into two cramped lines instead of laying out on one line —
   visible in every PNG. Any book layout that (like this one) keeps the inner margin
   note-column-free will hit this.
2. The target runner format (Task 10 / prototype parity) is a two-part line — `pagenum
   CHAPTER` (verso) / `SECTION pagenum` (recto) — sized to the *text column* width, not a
   three-part inner-margin/body/outer-margin split. `header()`'s layout model is the
   latter; it has no mode that produces the former without fighting its own box-width
   logic.

The README's own wideblock caveat ("do not handle pagebreaks well, especially in `book:
true` documents") turned out not to be the deciding factor here — a one-line header
re-invoked fresh per page via `page(header:)` never spans a pagebreak itself, so that
specific failure mode wasn't triggered in this probe. The column-width coupling and
shape mismatch above are the real reasons.

Net: Task 10 should build runners with a plain `page(header:)` (or `page(foreground:)`)
closure that positions content relative to the text column — using `marginalia.get-left()`
/ `marginalia.get-right()` if margin geometry is needed, but not `marginalia.header()`
itself.

## Corrections made vs. the plan's spike.typ

- Added `header: marginalia.header(...)` to the `#set page(...)` call (was a bare comment
  in the plan) to actually probe (e) instead of only gesturing at it.
- Added a `#sidenote[...]` call on page 2 (the plan's page 2 had body text only, no note
  call) — without it, the checklist item "page 2 of print PDF has notes on the LEFT" was
  unverifiable since no note existed on that page. Now verified directly.
- Footnote suppression, final state: `show footnote: it => sidenote(it.body)`,
  `show footnote.entry: none`, and `set footnote.entry(separator: none)` are all
  declared together immediately after `#set page(...)`, before the first note call in
  the document (originally the "Native note." `#sidenote[...]`, which had to move below
  the show rules). See (c) for why both the ordering and the `separator` line matter —
  this file went through a false "fixed" report before landing here; both problems are
  documented in (c) rather than silently corrected.
- No marginalia/cmarker param names needed correction — the plan's names were exact.

## Eyeball checklist (read from PNGs, both media, 150 ppi)

- **Footnote as numbered margin note with anchor:** yes. Anchor glyph `○` appears
  immediately after "footnote." in body text; matching margin note "I should render as a
  numbered margin note." appears at the same vertical position. (Anchor is a marker
  symbol, not an Arabic numeral — see (a).) Page bottom is fully clean in the final
  spike.typ — no duplicate text, no stray separator rule — verified by re-reading all
  four PNGs (screen/print × page 1/2) plus a 400 ppi crop of the page-bottom band plus
  `pdftotext | grep -c "numbered margin note"` returning `1` for both PDFs. See (c) for
  the two-round history of getting here.
- **html `<note>` and regex `#note[…]` both in margin:** yes, both present and correctly
  extracted — `◆ via html mapping` and `◇ via regex`, each with matching in-body anchors
  (`♦`/`◇`) at "A tag note" and "regex note" respectively.
- **Image renders (bytes path works):** yes, the circle SVG renders in both media at the
  expected position under "An image:".
- **Print page 2 notes in the OUTER margin (verso = LEFT):** yes, confirmed after adding
  a note to page 2 — margin note appears on the left edge of the print PDF's page 2,
  opposite the screen PDF (which keeps notes on the right on every page, since
  `book: false` there means outer always = right).
- **No overlapping notes:** confirmed on both PDFs — 4 notes cluster on page 1 without
  colliding, spaced by marginalia's automatic collision avoidance.
- **Unnumbered probe:** "no marker on me" renders in the margin with no marker glyph and
  no in-body anchor, confirming `counter: none` fully suppresses both.
- **Wideblock probe:** the rect spans from text column into the margin on both media,
  no errors, no overlap with adjacent notes.
- **Runner probe (added):** `RUNNER-INNER` / `RUNNER-OUTER {page}` present on every page
  in both media, correctly swapping sides in print/book mode; inner-side text wraps
  awkwardly at 0mm inner width (see (e) — this is why header() isn't the pick).

Both PDFs compile with exit code 0 and zero warnings (missing ETbb/Gill Sans MT fonts —
not installed in this environment — fell back silently; no warning text emitted by this
Typst build, confirmed by explicit exit-code checks, not just absence of stderr text).

## Parity

Evidence gathered by running `just proto-check` (via `direnv exec .` so the untracked
`.envrc.local`'s `PROTO_BOOK_DIR` loads) against a local, gitignored fixture
(`tests/fixtures/proto/main.typ` — never committed, per `.gitignore`) that renders four
real chapter files from a private manuscript through `book.with(paper: "crown-quarto",
…)` and `chapters(reader: …)`, using the continuity (legacy `#note[...]`) tier
exclusively — confirmed by inspection that the sampled chapters use no markdown
footnotes, no HTML `<note>` tags, and no images; every margin note in the fixture comes
from `#note[...]` or its file-transclusion form `#note[path/to/file.md]`.

**What compiled:** both media (`screen`, `print`) compile at exit 0 with zero warnings,
48 pages in print media — a minimal front-matter sequence (no copyright dict passed, so
that page is correctly skipped per Task 13's `if copyright != (:) or publisher != none`
guard), one part divider, four numbered chapters of real prose, running heads throughout,
and several dozen legacy-tier margin notes, all via `just proto-check`'s own recipe
end-to-end (not just a raw `typst compile`).

**Note-tier behavior vs. prototype:** every `#note[...]` / `#note[path.md]` call
rendered as an auto-positioned, collision-avoided margin note with no manual `dy:`
anywhere in the fixture — confirmed by eyeball on multiple pages carrying 2+ notes in
close vertical proximity (no overlaps, no manual nudging needed anywhere). This is the
expected improvement over a manual-positioning approach: marginalia's own collision
avoidance handled every case in real content, not just the synthetic `examples/`
prose.

**Heading-label resolution:** cmarker's `heading-labels: "github"` correctly auto-slugged
every heading across the four chosen chapters, including at least two containing `&`
and one containing `+` — confirmed via a clean TOC render showing correct chapter
numbers, full titles with special characters and punctuation intact, and page numbers
for all 4 chapters and their subsections (20 heading-derived TOC entries total, zero
label errors in the final compile, zero `link_id`-style hacks anywhere in the fixture).

Getting there took one iteration, worth recording because the failure mode is
instructive: the first four-chapter selection (picked without checking cross-references)
failed to compile with three "label `<...>` does not exist" errors. Each traced back to
a real in-content cross-reference — either a `[text][@slug]` form or a plain
`[text](#slug)` form — pointing at a heading in a *fifth* chapter that wasn't part of
the compiled subset. This is correct, expected Typst behavior: a label genuinely doesn't
exist if the heading that would define it isn't in the document. It is not a tuftelike
defect. Re-picking the four chapters so every in-set cross-reference's target heading was
also in the set made the errors disappear with zero code changes. Net: zero real
label-resolution bugs found — the mechanism works correctly on real, heavily
cross-referenced content; it just (correctly) requires referenced targets to be part of
the compile, same as it would in any Typst document.

**Icon registry against real content:** `icons:` was keyed on a short phrase that
recurs verbatim as an H3 prefix across the source material's exercise-style sections
(structurally identical to the `examples/book/` icon demo, just matched against real
headings instead of synthetic ones). It matched and rendered inline exactly as designed
— confirmed by eyeball.

**Tables:** one native CommonMark table (in one of the four chapters) rendered correctly
as a full body-width table with header row and numbered caption, via cmarker's built-in
table support and tuftelike's `figure.caption` show rule. No margin-routed table was
present in the sampled content, so margin-table behavior specifically remains untested
by this fixture — noted as a coverage gap, not a failure.

**What drifted acceptably:** one inert artifact, a single occurrence (across all four
chapters) of a prototype-specific inline helper call — shaped like a Typst function call
but not one of tuftelike's tiers (not `#note[...]`, not a recognized HTML tag, not a
`<!--raw-typst -->` escape) — rendered as literal plain text in the output instead of
resolving to anything, with no error, warning, or crash. This is expected: tuftelike's
markdown pipeline only special-cases its documented tiers; arbitrary custom
Typst-looking syntax sitting in prose is inert by design rather than silently
mis-evaluated or silently dropped. Cosmetic only, affecting a single occurrence in one
chapter.

**Template fixes required:** none. No file under `src/` changed as a result of this
fixture. Every rendering gap traced back either to fixture composition (the
cross-reference selection issue above, resolved by choosing a self-contained chapter
set — a fixture-authoring fix, not a template fix) or to prototype-specific tooling
outside tuftelike's documented scope (the inert helper-call artifact above). The
template itself — geometry, notes, markdown pipeline, chapter openers, icons, TOC,
runners — held up unmodified against real, messy, heavily cross-referenced content.

### Parity round 2 — side-by-side against the prototype's print PDF

Round 1 verified compiles-clean only; a true page-against-page comparison
with the prototype's final print PDF surfaced three fidelity gaps, all
fixed and re-verified by re-rendering the same spread from both PDFs:

- **Tables had never been ported** — they rendered with Typst defaults
  (full grid, body width). Now faithful: caption on top as a two-line
  sticky split ("Table N." over the caption body, sans, note-size),
  header-only strokes (1pt top / 0.3pt below header; authors close with
  a table.hline), 10pt header / 9pt body cells, left-aligned ragged-right
  cells, full width extending into the note column, flush to the outer
  edge on print versos, unbreakable in print.
- **Body metrics**: paragraph leading 0.8em / spacing 1.4em (the
  print-proven values; we had 0.65em), list body-indent 1em / spacing
  1.2em with unjustified list items — all now theme keys.
- **Note numbering**: the prototype's notes are all unnumbered. Numbering
  now follows ANCHORING: markdown footnotes render numbered (the typed
  reference is an anchor), `<note>` and the legacy `#note[…]`/fence tiers
  render unnumbered, `<note numbered>` opts in.

Comparison anchor: the same table-bearing verso spread rendered from both
PDFs matches on caption structure, rules, cell typography, margin
extension, outer-edge alignment, unnumbered margin notes, H2 treatment,
folio placement, and body leading. Remaining deltas are structural to the
excerpt (table/page numbering offsets from rendering 4 of the book's
chapters) and acceptable.
