// A book with a custom sans; helpers called WITHOUT theme must see it.
#import "@local/tuftelike:0.1.0": *
#show: book.with(title: "Ambient", theme: (fonts: (sans: ("Fira Sans", "Gill Sans MT"))))
#show: begin-chapters
= One
#context assert(current-theme().fonts.sans.first() == "Fira Sans")
#context assert(current-labels().chapter == "Chapter")
Body#sidenote[side] and#marginnote[margin] and #newthought[lead] then
#tufte-quote[q]
#md("Para with a note.<note>n</note>\n\n<prompt>p</prompt>", extensions: instructional-extensions())
