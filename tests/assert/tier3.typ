// Tier-3 papers (no note column): sidenote/marginnote become footnotes,
// footnotes-as-sidenotes: auto resolves to false, nothing crashes.
#import "@local/tuftelike:0.1.0": *
#show: book.with(title: "T3", paper: "lulu-digest", target: "print")
#show: begin-chapters
= One
#context assert(current-paper().note-col == 0mm)
#context assert(current-theme().body.size == 10pt)   // tier3 preset recommended
Body#sidenote[becomes a footnote] and#marginnote[also a footnote] and real#footnote[stays a footnote].
#context assert(query(footnote).len() == 3, message: "expected 3 footnotes, got " + str(query(footnote).len()))
