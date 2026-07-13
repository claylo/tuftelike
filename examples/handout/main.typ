#import "@local/tuftelike:0.1.0": *

#show: handout.with(
  paper: "us-letter",
  title: "Field Notes on Margin Width",
  subtitle: "A Technical Note for the Design Review",
  authors: (
    (name: "A. Demo Author", role: "Lead Editor", affiliation: "Example Press",
      email: "author@example.org"),
    (name: "J. Query", role: "Reviewing Typographer", affiliation: "Example Press",
      email: "jquery@example.org"),
  ),
  abstract: [This note summarizes the measured effect of note-column width
    on reading speed across three trial layouts, and recommends a default
    for the "Margins of Error" production run.],
  document-number: "TN-001",
  distribution: "Design Review, Production",
  footer-content: (
    [DRAFT — internal circulation only],
    context [Field Notes on Margin Width · TN-001 #h(1fr) #counter(page).display()],
  ),
  bib: bibliography("refs.bib"),
)

We tested three note-column widths against the same eleven-page excerpt
of the manuscript: twenty-two, twenty-six, and thirty-two
millimeters.#sidenote[The twenty-six millimeter default already used
throughout the "Margins of Error" trade layout was the middle trial, not
a baseline chosen after the fact — worth stating plainly since it's easy
to assume the default was reverse-engineered from these results.] Reading
speed was measured by time-to-completion across five volunteer readers
per width, with margin notes present on roughly a third of pages in each
trial.

The twenty-six millimeter column produced the fastest completion times
overall, though the gap against thirty-two millimeters was small enough
that either would be defensible in production. The twenty-two millimeter
column measured noticeably worse, consistent with prior work on
minimum comfortable line length for
sans-serif marginalia#sidecite(<marginratio2019>).

#pagebreak()

Given those results, this note recommends keeping the twenty-six
millimeter default for the six-by-nine trade layout rather than widening
it for the sake of the thirty-two millimeter trial's marginal gain — the
wider column costs more body-text width than its reading-speed benefit
justifies at this trim size.

This page exists chiefly to confirm the footer changes here: the first
page carries a draft notice, and every page after it carries the running
title, document number, and a live page number instead.
