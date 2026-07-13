#import "@preview/marginalia:0.3.1" as marginalia

// Tufte convention is arabic superscript numerals, not marginalia's default
// symbol cycle (note-markers-alternating: ● ○ ◆ ◇ …). `numbering:` on
// marginalia.note() drives BOTH the margin marker and the in-text anchor —
// anchor-numbering defaults to auto, which falls back to numbering
// (marginalia/lib.typ note(), ~L618-624). This is the package's own
// documented override for "superscript numbers" (lib.typ ~L611-612).
#let arabic-note-numbering = (..i) => super(numbering("1", ..i))

// Numbered Tufte sidenote. dy stays as an ESCAPE HATCH; marginalia positions
// and collision-avoids automatically.
#let sidenote(dy: 0pt, theme: (:), body) = marginalia.note(dy: dy,
  numbering: arabic-note-numbering,
  text(size: theme.at("note-size", default: 9pt),
       font: theme.at("sans", default: ("Gill Sans MT", "Fira Sans", "Helvetica Neue")),
       // block + set par, NOT par(..)[..]: wrapping in par() silently DROPS
       // block-level content (headings/lists in note bodies) and triggers
       // "parbreak ignored" warnings on markdown-rendered footnotes
       block({
         set par(leading: theme.at("note-leading", default: 0.5em))
         body
       })))

// Unnumbered floating margin commentary.
#let marginnote(dy: 0pt, theme: (:), body) = marginalia.note(counter: none, dy: dy,
  text(size: theme.at("note-size", default: 9pt),
       font: theme.at("sans", default: ("Gill Sans MT", "Fira Sans", "Helvetica Neue")), body))

// Margin figure with caption.
// Note: body wrapped in parens because Typst 0.15.0 rejects a bare trailing
// `=` at end-of-line with the expression starting on the next line — the
// plan's original one-liner-across-two-lines form is a parse error.
#let notefigure(content, caption: none, dy: 0pt) = (
  marginalia.notefigure(content, caption: caption, dy: dy)
)

// Full citation in the margin, numbered anchor in the text.
// Requires a bibliography somewhere in the document (classes accept `bib:`).
#let sidecite(key, supplement: none, theme: (:)) = sidenote(theme: theme,
  cite(key, form: "full", supplement: supplement))

#let wideblock = marginalia.wideblock

// Class-level footnote→sidenote transform. MUST be installed before any
// marginalia note call fires (spike finding c: `show footnote.entry: none`
// is ordering-sensitive) — classes apply it in their early style chain.
// Never install this locally inside md().
#let footnote-transform(theme, doc) = {
  show footnote: it => sidenote(theme: theme, it.body)
  show footnote.entry: none
  set footnote.entry(separator: none)   // entry show-rule alone leaves the separator line (spike round 2)
  doc
}
