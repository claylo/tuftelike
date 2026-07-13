# Finding the Thread

A margin note earns its keep the moment a reader can decide, without
breaking stride, whether it's worth a detour. <note>That's the whole
design brief, really: a note should be answerable faster than the reader
can get annoyed at having glanced at it.</note> Anything longer than a
few sentences belongs in the body, not the edge.

This is harder to enforce than it sounds. Writers reach for the margin
when they're avoiding a decision — "I'm not sure this belongs here, so
I'll footnote it" — and the result is a column full of half-formed asides
competing for the same six inches of vertical space. The fix isn't a
style rule. It's asking, for every candidate note, whether the main
argument would survive its removal. If the argument doesn't wobble
without it, the note can stay in the margin. If it wobbles, it belongs in
the paragraph.

A short cheat-sheet, worth keeping nearby while drafting:

<!--raw-typst
#table(
  columns: 3,
  [*Unit*], [*Answerable in*], [*Belongs in*],
  [Definition], [one clause], [the margin],
  [Worked example], [one paragraph], [the body],
  [Digression], [as long as it takes], [an appendix],
)
-->

Not every aside fits a note column, though, and pretending otherwise just
produces a note nobody can read at nine points. When a passage needs more
room than either channel offers on its own, it can borrow the whole
measure instead:

<wide>A wideblock escapes the text column entirely, spanning past the
margin as well — useful for a table, a diagram, or a quotation too long
to sit comfortably in twenty-six millimeters.</wide>

<!--raw-typst #notefigure(image("../../_assets/icon-info.svg", width: 8mm), caption: [A margin figure, captioned where it lives.]) -->

Margin figures follow the same rule as margin notes: if the argument
survives without it, it can live in the margin.

Everything past this point assumes you've internalized that cheat-sheet:
margin for definitions, body for the argument, appendix for the parts
only a few readers will ever need.
