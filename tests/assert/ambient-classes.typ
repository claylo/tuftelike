// letter, handout, and cover must publish their theme/labels to the ambient
// state exactly like book does — helpers called without theme: see them
#import "@local/tuftelike:0.1.0": *
#let probe = context {
  assert(current-theme().fonts.sans.first() == "Fira Sans", message: "ambient theme not published")
  assert(current-labels().cc == "copies", message: "ambient labels not published")
}
#let th = (fonts: (sans: ("Fira Sans", "Gill Sans MT")))
#let lb = (cc: "copies")
#[
  #show: letter.with(from: (name: "A"), theme: th, labels: lb)
  #probe Body#sidenote[side] #newthought[lead]
]
#pagebreak()
#[
  #show: handout.with(title: "H", theme: th, labels: lb)
  #probe Body#marginnote[margin]
]
