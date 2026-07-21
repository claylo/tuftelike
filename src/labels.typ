#let default-labels = (
  chapter: "Chapter", appendix: "Appendix", appendices: "Appendices",
  part: "Part", contents: "Contents",
  index: "Index", about-author: "About the Author", colophon: "Colophon",
  figure: "Figure", table: "Table", code: "Code",
  draft: "DRAFT", version: "Version",
  enclosures: "Enclosures", cc: "cc", review-copy: "REVIEW COPY\nNOT FOR RESALE",
  distribution: "Distribution",
)
#let resolve-labels(user) = default-labels + user
