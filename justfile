typst := "typst"
pkgdir := env_var('HOME') / "Library/Application Support/typst/packages/local/tuftelike"

# symlink this repo as @local/tuftelike:0.1.0
install:
    mkdir -p "{{pkgdir}}"
    ln -sfn "$(pwd)" "{{pkgdir}}/0.1.0"

# wipe build output (out/ is throwaway; every recipe recreates what it needs)
clean:
    rm -rf out

# lint + compile-time asserts + compile matrix + font-swap render test + role coverage
test: clean install
    mkdir -p out
    tests/lint-hardcoded.sh
    for f in tests/assert/*.typ; do echo "== $f"; {{typst}} compile --root . --font-path fonts "$f" "out/assert-$(basename "$f" .typ).pdf" || exit 1; done
    if [ -x tests/compile-matrix.sh ]; then tests/compile-matrix.sh; fi
    tests/font-swap.sh
    tests/role-coverage.sh
    tests/paper-matrix.sh

# build an example at a build target: just demo book print — targets are the
# built-ins (screen, print) plus the example's own (book: kdp, coil); an
# optional theme flips a named preset: just demo book print trade
demo example variant="screen" theme="": install
    mkdir -p out
    {{typst}} compile --root . --font-path fonts --input "target={{variant}}" {{ if theme != "" { "--input theme=" + theme } else { "" } }} "examples/{{example}}/main.typ" "out/{{example}}-{{variant}}{{ if theme != "" { "-" + theme } else { "" } }}.pdf"

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

# list @preview package pins vs Typst Universe (exit 1 if any are behind)
outdated:
    bin/typst-deps outdated

# bump @preview pins to latest (optionally only the named packages), then test
update *pkgs:
    bin/typst-deps update {{pkgs}}
    just test

# keep the current out/ as a named baseline: snapshots/<label> (default = timestamp)
snapshot label=`TZ=America/New_York date +%Y-%m-%d-%H%M`:
    mkdir -p snapshots && rm -rf "snapshots/{{label}}" && cp -R out "snapshots/{{label}}"
    @echo "snapshot: snapshots/{{label}}"

# geometry-diff every PDF in out/ against a snapshot (line bboxes + font/size)
parity label:
    tests/parity.sh "snapshots/{{label}}" out

# body/note width, chars per line, lines per page for one paper preset
measure paper:
    bin/measure {{paper}}

# same, for every paper preset (also writes out/measure.tsv)
measure-all:
    bin/measure --all
