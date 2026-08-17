#import "@local/tuftelike:0.1.0": default-labels, resolve-labels, default-theme, resolve-theme, deep-merge, role, role-args, styled, text-keys, theme-presets
#assert(default-labels.chapter == "Chapter")
#assert(resolve-labels((chapter: "Kapitel")).chapter == "Kapitel")
#assert(resolve-labels((chapter: "Kapitel")).appendix == "Appendix") // merge keeps defaults
#assert(default-labels.appendices == "Appendices")
#assert(default-labels.about-author == "About the Author")
#assert(default-labels.colophon == "Colophon")

// schema shape
#assert(default-theme.fonts.serif.first() == "ETbb")
#assert(default-theme.body.size == 11pt)
#assert(default-theme.heading.h1.size == 20pt)
#assert(default-theme.justify == false)
#assert(default-theme.toc-pagenums == "ragged") // prototype-proven default
#assert(default-theme.draft == false)

// every role carries the six text keys (values may be auto)
#let is-role(d) = type(d) == dictionary and "font" in d
#let check(d, path) = {
  if is-role(d) {
    for k in text-keys { assert(k in d, message: path + " missing " + k) }
  } else if type(d) == dictionary {
    for (k, v) in d { check(v, path + "." + k) }
  }
}
#check(default-theme, "theme")
#assert(is-role(default-theme.note))
#assert(is-role(default-theme.toc.group))
#assert(is-role(default-theme.cover.title))

// deep merge: partial nested overlay, arrays replace wholesale
#let t = resolve-theme((heading: (h2: (weight: "bold")), fonts: (serif: ("Override",))))
#assert(t.heading.h2.weight == "bold")
#assert(t.heading.h2.size == 18pt)          // sibling key preserved
#assert(t.heading.h1.size == 20pt)          // sibling role preserved
#assert(t.fonts.serif == ("Override",))     // arrays replace
#assert(t.fonts.sans.first() == "Gill Sans MT")
#assert(deep-merge((a: (b: 1, c: 2)), (a: (b: 9))) == (a: (b: 9, c: 2)))

// role access + alias resolution
#assert(role(default-theme, "heading.h1").style == "italic")
#let ra = role-args(t, "body")
#assert(ra.font == ("Override",))           // alias "serif" resolved through overridden fonts
#assert(ra.size == 11pt)
#assert(role-args(default-theme, "note").font.first() == "Gill Sans MT")
#assert("fill" not in role-args(default-theme, "note"))   // auto keys dropped
#assert(role-args(resolve-theme((note: (font: ("Zzz",)))), "note").font == ("Zzz",))  // explicit stack passes through
#assert(styled(default-theme, "body", [x]) != none)

// preset chain: user > preset > defaults (nested keys)
#let variants = ("trade": (body: (size: 10pt), toc-pagenums: "flush"))
#let t5 = resolve-theme((note: (size: 8pt)), presets: variants, preset: "trade")
#assert(t5.body.size == 10pt)        // preset overlay applied
#assert(t5.toc-pagenums == "flush")
#assert(t5.note.size == 8pt)         // user dict rides along
#assert(t5.fonts.serif.first() == "ETbb")  // untouched keys fall through
#assert(resolve-theme((body: (size: 12pt)), presets: variants, preset: "trade").body.size == 12pt) // user beats preset
#assert(resolve-theme((:), presets: variants).body.size == 11pt) // no selection -> defaults
#assert(resolve-theme((:), preset: "beautiful-evidence").body.size == 11pt) // built-in identity overlay
#assert("beautiful-evidence" in theme-presets)
// tier presets + per-paper aliases
#assert(theme-presets.tier2.body.size == 10pt and theme-presets.tier2.note.size == 8.5pt)
#assert(theme-presets.at("kdp-6x9") == theme-presets.tier2)
#assert(theme-presets.tier3.body.size == 10pt)
#assert(theme-presets.at("lulu-a5") == theme-presets.tier3)
#assert("kdp-7.5x9.25" not in theme-presets)   // tier 1 needs no type preset
