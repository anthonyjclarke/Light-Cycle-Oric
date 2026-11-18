# Light Cycle — recipes. The C64 build itself is the Makefile (make, make d64, make run, make smoke, make oric).

default:
    @just --list

# Build the C64 .prg.
build:
    make

# Run the C64 build in VICE.
run:
    make run

# Regenerate and verify the Oric disassembly from CYCLE.TAP.
oric:
    make oric

# --- Documentation (docs/html_documentation.md). The figure tool needs Pillow: DOCS_PYTHON, else python3.14 (Homebrew), else python3.
docs_py := `echo "${DOCS_PYTHON:-$(command -v python3.14 || echo python3)}"`

# Everything: disassemble, build, capture the screens, decode the figures, generate docs/LIGHT_CYCLE.html.
docs: oric build
    {{docs_py}} docs/tools/capture_screens.py
    {{docs_py}} docs/tools/render_graphics.py
    {{docs_py}} docs/tools/render_oric.py
    node docs/tools/build_docs.mjs

# Regenerate docs/LIGHT_CYCLE.html from the Markdown and the current images only.
docs-html:
    node docs/tools/build_docs.mjs

# Fail if a chapter names a missing label or the saved handbook is stale.
docs-check: docs-names
    node docs/tools/build_docs.mjs --check

# Regenerate the handbook whenever a source changes.
docs-watch:
    node docs/tools/build_docs.mjs --watch

# Re-capture the VICE screenshots of the C64 build.
docs-screens: build
    {{docs_py}} docs/tools/capture_screens.py

# Re-render the figures decoded from the Oric tape (deterministic).
docs-graphics:
    {{docs_py}} docs/tools/render_graphics.py
    {{docs_py}} docs/tools/render_oric.py

# Fail if a chapter names a label that is not in the source.
docs-names:
    python3 docs/tools/doc_names.py
