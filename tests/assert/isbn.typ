#import "@local/tuftelike:0.1.0": isbn-lines
#assert(isbn-lines(none) == ())
#assert(isbn-lines("978-1-0000-0000-1") == ("ISBN 978-1-0000-0000-1",))
#assert(isbn-lines((paperback: "978-1-0000-0000-1", ebook: "978-1-0000-0000-2"))
  == ("ISBN 978-1-0000-0000-1 (paperback)", "ISBN 978-1-0000-0000-2 (ebook)"))
