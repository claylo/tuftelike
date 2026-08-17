// Named theme variants for this book — the shareable-library pattern.
// Keep a file like this in one place and `ln -s` it into each book
// project; main.typ imports it and passes `presets:`. Flip variants at
// compile time with --input theme=<name> (no --input = Tufte defaults).
// Because this is a normal module (not data), it can hold helpers,
// shared font stacks, and its own imports — a theme-file input never
// could (eval'd files can't import).
#let trade-serif = ("ETbb", "Palatino", "Georgia")

#let book-presets = (
  // 10pt body is the 6x9-friendly measure; flush folios de-Tufte the TOC
  trade: (body: (size: 10pt), note: (size: 8.5pt), toc-pagenums: "flush",
    fonts: (serif: trade-serif)),
)
