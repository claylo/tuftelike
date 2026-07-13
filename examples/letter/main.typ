#import "@local/tuftelike:0.1.0": *
#let reader = (p, ..a) => read(p, ..a.named())

#show: letter.with(
  paper: "us-letter",
  from: (name: "J. Query", title: "Reviewing Editor", org: "Example Press",
    address: "500 Folio Street, Springfield", email: "jquery@example.org"),
  to: [A. Demo Author \ c/o Example Press],
  re: "Manuscript notes — Margins of Error",
  salutation: [Dear A.,],
  closing: "Warmly,",
  signature: "J. Query",
  enclosures: ("Marked-up chapter 2 excerpt",),
)

#md(reader("body.md"), reader: reader)
