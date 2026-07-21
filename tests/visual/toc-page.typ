// TOC layout fixture — exercises every contents behavior at prototype scale:
// three parts, twelve chapters (2-digit numbers must right-align against
// single digits), double-digit SECTION numbers (9.10, 9.11, 12.10 — bodies
// stay aligned, prefixes left-flush like the prototype's 8.9/8.13), overlong
// titles at both levels (must wrap with a hanging indent, folio glued to the
// last line — never stranded alone), appendix group header with suppressed
// second tier, suppressed sub-heads under unnumbered sections, the
// backmatter separator gap above About the Author, and sticky group
// headers/chapter rows (no widowed PART header, no chapter title stranded
// from its first section across a page break). First TOC = ragged folios
// (default), second = the same contents with toc-pagenums: "flush".
#import "@local/tuftelike:0.1.0": frontmatter-page, toc, resolve-theme, resolve-labels, resolve-paper, resolve-media, page-size, about-author, colophon, base-style

#let media = resolve-media()
#let paper = resolve-paper("crown-quarto")
#let ps = page-size(paper, media)
#let theme = resolve-theme((:))
#let labels = resolve-labels((:))

#set page(width: ps.width, height: ps.height,
  fill: if media == "screen" { rgb("FFFFF8") } else { none })
// base-style matters here: TOC row rhythm inherits the book's ambient
// par spacing (1.4em) — without it the level-2 pitch runs tight
#show: base-style.with(theme, labels, 0mm, media: media)

#let parts = (
  (title: "Part I: First Movement", first-chapter: 1),
  (title: "Part II: Second Movement", first-chapter: 5),
  (title: "Part III: Third Movement", first-chapter: 11),
)

#frontmatter-page(paper, media, toc(theme, labels, parts: parts))
#frontmatter-page(paper, media,
  toc(resolve-theme((toc-pagenums: "flush")), labels, parts: parts))

// --- targets ---------------------------------------------------------------
// Front section: unnumbered, its sub-head must stay out of the contents.
#heading(level: 1, numbering: none)[Introduction]
#heading(level: 2, numbering: none)[Hidden Front Sub-Head]
A front section body.

#set heading(numbering: "1.1.1")
#counter(heading).update(0)
// (title, section-count): Theta wraps at level 1; Iota runs to 9.11 and Mu
// to 12.10 for the double-digit section-number column; Iota's second
// section wraps at level 2 (print page is trim + bleed = 553.8pt wide —
// a wrap-test title must clear the BLEED-inclusive text edge, not trim's)
#let chapter-plan = (
  ("Chapter Alpha", 2), ("Chapter Beta", 2), ("Chapter Gamma", 2),
  ("Chapter Delta", 2), ("Chapter Epsilon", 2), ("Chapter Zeta", 2),
  ("Chapter Eta", 2),
  ("Chapter Theta Carries a Deliberately Overlong Title to Prove That Level-One Entries Wrap With a Hanging Indent", 2),
  ("Chapter Iota", 11), ("Chapter Kappa", 2), ("Chapter Lambda", 2),
  ("Chapter Mu", 10),
)
#let long-section = "A Deliberately Overlong Section Title to Check That Wrapping Behavior in the Contents Holds on the Full Print Page"
#for (title, sections) in chapter-plan [
  #heading(level: 1)[#title]
  #for s in range(sections) [
    #heading(level: 2)[#if title == "Chapter Iota" and s == 1 [#long-section] else [Numbered Section #(s + 1)]]
    Body copy.
  ]
]

#counter(heading).update(0)
#set heading(numbering: "A.1")
#heading(level: 1)[Tooling Notes]
#heading(level: 2)[Hidden Appendix Detail]
Appendix body.
#heading(level: 1)[Further Reading]
Second appendix body.

#about-author(theme)[A biography paragraph for the gap check.]
#colophon(theme)[Set with the toc fixture.]
