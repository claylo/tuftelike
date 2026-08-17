# Tufte book-style matrix

Working document for tuftelike's `style:` presets. Each column becomes a
named preset in `themes.typ` once filled. **Cells marked `SHELF-CHECK` need
verification against the physical books** — print specifics (accent inks,
opener anatomy, measures) are exactly what secondary sources get wrong.
Pre-filled cells are working assumptions, not gospel: correct freely.

The `beautiful-evidence` column describes the shipped defaults (inherited
from the print-proven prototype book, which was modeled on it) — it's the
baseline the others diff against.

| Attribute | beautiful-evidence (default) | vdqi | envisioning-information | visual-explanations | fresh-eyes |
|---|---|---|---|---|---|
| Body face | ETbb (Bembo lineage) | ETbb — SHELF-CHECK weight/size feel | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Body size / leading | 11pt / 0.8em leading, 1.4em par spacing | SHELF-CHECK (measure denser?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Accent color | none (ink only, luma(30)) | red — SHELF-CHECK exact shade + WHERE used (chapter numerals? rules? plot marks only?) | SHELF-CHECK (any accent at all?) | red + blue? SHELF-CHECK | SHELF-CHECK |
| Chapter opener | small sans CHAPTER label + number over italic serif title, 2.5em drop | SHELF-CHECK (large numeral? no label word?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Section heads | italic serif, sizes 18/16pt, gray sans number above (H2) | SHELF-CHECK (run-in newthought instead of display heads?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Newthought usage | available, not default | SHELF-CHECK (primary sectioning device?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Running heads | verso: pagenum + CHAPTER; recto: SECTION + pagenum, 8pt tracked serif, outer-edge | SHELF-CHECK (present at all? format?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Margin notes | unnumbered sans 9pt workhorse; numbered only when anchored | SHELF-CHECK (serif notes? size?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Captions | sans, "Figure N." sticky line over body, outer-edge on verso | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Tables | header-only rules, 10/9pt ragged cells, margin-width | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| TOC | whitespace fill, italic serif entries, tracked part dividers | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Title page | sans tracked caps author/title, italic subtitle, publisher bottom | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Epigraphs | tufte-quote, right-aligned em-dash attribution | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Rules/ornaments | none beyond table rules | SHELF-CHECK (red rules?) | SHELF-CHECK | SHELF-CHECK | SHELF-CHECK |
| Anything else distinctive | — | | | | |

## How a completed column becomes a preset

1. Data-only differences (faces, sizes, accent, leading) → keys in the
   style's theme overlay dict.
2. Structural differences (opener anatomy, head treatment) → a variant
   enum key + a branch in the relevant show rule (chapter.typ,
   typography.typ). Add enums only when a column actually demands one.
3. Preset lands in `themes.typ` as `styles.<name>`; `style: "<name>"`
   resolves through the standard chain. No preset ships with unverified
   cells.
