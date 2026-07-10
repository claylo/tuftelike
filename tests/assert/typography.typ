#import "@local/tuftelike:0.1.0": plain-text, lead-split
#assert(plain-text([Hello *world*]) == "Hello world")
// lead-split: head = up to first comma OR third space, whichever first
#assert(lead-split("One two three four") == ("One two three", " four"))
#assert(lead-split("Once, upon a time") == ("Once", ", upon a time"))
#assert(lead-split("Hi") == ("Hi", ""))
// realistic heading constructs runners.typ will feed plain-text
#assert(plain-text(smallcaps[Chapter Title]) == "Chapter Title")
#assert(plain-text(link("https://example.com")[Click here]) == "Click here")
#assert(plain-text([]) == "")
// boundary inputs
#assert(lead-split("") == ("", ""))
#assert(lead-split(",abc") == ("", ",abc"))
// unicode regression locks (byte-vs-cluster corruption)
#assert(lead-split("Café one two three") == ("Café one two", " three"))
#assert(lead-split("日本語のテスト, comma after multibyte") == ("日本語のテスト", ", comma after multibyte"))
