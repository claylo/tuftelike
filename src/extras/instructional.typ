// Optional extension set for instructional books: prompt/response dialogue
// tags + an H3 icon keyword map. Not part of the core pipeline — opt in by
// importing from the package root (re-exported by lib.typ, same as every
// other public symbol) and forwarding into a class/md() call:
//   #import "@local/tuftelike:0.1.0": instructional-extensions, instructional-icons
//   #chapters(paths, reader: reader, extensions: instructional-extensions(theme))

// html tag handlers for <prompt>…</prompt> / <response>…</response>.
// Merge target for md()'s `extensions:` param (which itself merges over the
// built-in note/margin/wide handlers — see markdown.typ).
#let instructional-extensions(theme) = (
  prompt: (attrs, body) => block(inset: (left: 1em))[
    #text(font: theme.at("mono", default: ("Consolas", "Menlo")), weight: "bold", size: 10pt, body)],
  response: (attrs, body) => block(inset: (left: 1em, right: 1em))[
    #text(font: theme.at("serif", default: ("ETbb", "Palatino")), body)],
)

// keyword -> icon content map for chapter.typ's H3 icon registry (the
// `icons:` param on book()). Callers supply their own SVGs; nothing ships
// in the package — `assets` is the path prefix to the caller's icon dir.
#let instructional-icons(assets: "") = (
  "Quick Try": image(assets + "/icon-flask.svg"),
  "Checkpoint": image(assets + "/icon-info.svg"),
)
