# env -u shields against the mis-escaped global TYPST_PACKAGE_PATH (see .envrc);
# harmless no-op once that's fixed in the shell profile
typst := "env -u TYPST_PACKAGE_PATH typst"
pkgdir := env_var('HOME') / "Library/Application Support/typst/packages/local/tuftelike"

# symlink this repo as @local/tuftelike:0.1.0
install:
    mkdir -p "{{pkgdir}}"
    ln -sfn "$(pwd)" "{{pkgdir}}/0.1.0"

# compile-time assertion tests + compile matrix
test: install
    mkdir -p out
    for f in tests/assert/*.typ; do echo "== $f"; {{typst}} compile --root . --font-path fonts "$f" "out/assert-$(basename "$f" .typ).pdf" || exit 1; done
    if [ -x tests/compile-matrix.sh ]; then tests/compile-matrix.sh; fi

# build an example: just demo book print
demo target media="screen": install
    mkdir -p out
    {{typst}} compile --root . --font-path fonts --input "media={{media}}" "examples/{{target}}/main.typ" "out/{{target}}-{{media}}.pdf"

# build the wrap-cover example (no media toggle — cover is a single compile target)
cover: install
    mkdir -p out
    {{typst}} compile --root . --font-path fonts examples/cover/main.typ out/cover.pdf

# parity build against the prototype book (local only; needs PROTO_BOOK_DIR
# from .envrc.local — direnv exports it into the shell before just runs)
proto-check: install
    [ -n "${PROTO_BOOK_DIR:-}" ] || { echo "PROTO_BOOK_DIR not set (see .envrc.local)" >&2; exit 1; }
    mkdir -p tests/fixtures/proto out
    ln -sfn "$PROTO_BOOK_DIR/content" tests/fixtures/proto/content
    {{typst}} compile --root . --font-path fonts --input media=print tests/fixtures/proto/main.typ out/proto-print.pdf

# confirm the print-proven fonts are on the font path
fonts-check:
    {{typst}} fonts --font-path fonts | grep -iE 'ETbb|Gill Sans|Consolas' || echo "expected fonts missing — see README fonts section"
