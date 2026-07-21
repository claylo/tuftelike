// Resolution chain everywhere: explicit theme: dict > selected preset
// overlay > these defaults. Preset SELECTION resolves preset: arg >
// --input theme=<name> > none (same pattern as media).
#let default-theme = (
  serif: ("ETbb", "ETBembo", "Palatino", "Georgia"),
  sans: ("Gill Sans MT", "Fira Sans", "Helvetica Neue", "Arial"),
  mono: ("Consolas", "Menlo", "Monaco"),
  body-size: 11pt, note-size: 9pt, folio-size: 8pt,
  body-leading: 0.8em, par-spacing: 1.4em,   // prototype book's print-proven metrics
  h1-size: 20pt, h2-size: 18pt, h3-size: 16pt, h4-size: 14pt, h5-size: 12pt,
  text-fill: luma(30),
  screen-bg: rgb("FFFFF8"),
  note-leading: 0.5em,
  // TOC folio placement: "ragged" = page number follows the title after a
  // fixed gap (prototype-proven Tufte contents); "flush" = pushed to the
  // right edge of the entry line
  toc-pagenums: "ragged",
  draft: false,
)
// Named preset overlays, applied between default-theme and the user dict.
// The defaults ARE beautiful-evidence, so its overlay is empty — selecting
// it by name is always valid and always means "the Tufte defaults". Shelf-
// matrix presets (v0.2) land here as sibling overlays.
#let theme-presets = ("beautiful-evidence": (:))

// user: unconditional overrides — they apply under EVERY preset.
// presets: caller-defined named overlays merged over the built-ins, so a
//   book can declare its own variants and flip them at compile time
//   (--input theme=<name>) without editing source.
// preset: auto reads --input theme=<name>; a string forces; none disables.
// Shallow merge, right side wins. Arrays REPLACE wholesale: overriding serif
// with ("MyFont",) drops the fallbacks — pass the full stack you want.
#let resolve-theme(user, presets: (:), preset: auto) = {
  let all = theme-presets + presets
  let name = if preset == auto { sys.inputs.at("theme", default: none) } else { preset }
  let overlay = if name == none { (:) } else {
    assert(name in all, message: "unknown theme \"" + name
      + "\" — available: " + all.keys().join(", "))
    all.at(name)
  }
  default-theme + overlay + user
}
