// Shared by every font-swap fixture: every alias points at a font Typst
// EMBEDS (portable, no --font-path), so any glyph set in a default-stack
// family (ETbb, Gill Sans, Consolas, Fira, Palatino, …) is a leak.
#let swap-fonts = (
  serif: ("Libertinus Serif",),
  sans: ("New Computer Modern",),
  mono: ("DejaVu Sans Mono",),
)
#let swap-theme = (fonts: swap-fonts, draft: true)
