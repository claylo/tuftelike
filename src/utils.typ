// Recursively flatten content to a plain string (used by runners + lead-smallcaps).
#let plain-text(it) = {
  if type(it) == str { it }
  else if it == [ ] { " " }
  else if it.has("children") {
    // join() on an empty array returns none, not "" — guard the contract
    let kids = it.children.map(plain-text)
    if kids.len() == 0 { "" } else { kids.join("") }
  }
  else if it.has("text") { plain-text(it.text) }
  else if it.has("body") { plain-text(it.body) }
  else { "" }
}

// Split for Tufte lead-in small caps: up to first comma or third space.
// Tracks BYTE offsets while iterating clusters — position()/slice() are
// byte-based; mixing in cluster counts corrupts multibyte text ("Café …").
#let lead-split(s) = {
  let comma = s.position(",")
  let spaces = ()
  let pos = 0
  for ch in s.clusters() {
    if ch == " " { spaces.push(pos) }
    pos += ch.len()
  }
  let third = if spaces.len() >= 3 { spaces.at(2) } else { s.len() }
  let stop = calc.min(if comma == none { s.len() } else { comma }, third)
  (s.slice(0, stop), s.slice(stop))
}
