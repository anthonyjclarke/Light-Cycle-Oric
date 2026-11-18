# Light Cycle – Maintaining the Documentation

## Source of Truth

The [HTML handbook](LIGHT_CYCLE.html) gathers the chapters in `docs/`, the changelog, the decoded figures and the VICE
screenshots into one offline page. Images, styling, the reader's controls and the Mermaid renderer are all embedded, so
it opens in a browser with no network access.

**Edit the Markdown, never the generated HTML.** Each chapter links to its Markdown source, and links between included
documents become links within the page. Links to other repository files stay relative, so they work only when the
checkout sits next to the HTML. The handbook has a contents sidebar, chapter search, image enlargement and print
support.

### The C64 Font Option

The sidebar's **Switch to the C64 font** button sets the page in Style's [C64
TrueType](https://style64.org/c64-truetype) fonts. Their [licence](https://style64.org/c64-truetype/license) allows
embedding them unmodified with `@font-face` but not offering the files for download, so `docs/tools/fonts/` ignores
everything but its own `.gitignore`. To include the option, copy `C64_Pro-STYLE.woff2` and `C64_Pro_Mono-STYLE.woff2`
from the package's `fonts/` folder, unmodified, into `docs/tools/fonts/`. Without them the button is left out and `just
docs-check` reports the handbook stale, because the committed handbook is generated with them. The paths and labels are
`retroFont` in `docs/handbook.json`.

---

## Regeneration

Run from the repository root, in this order. The figure tool needs Pillow: on this Mac use Homebrew's
`/opt/homebrew/bin/python3.14`.

| Step                          | Command                                  | Needs          | Writes                          |
|:------------------------------|:-----------------------------------------|:---------------|:--------------------------------|
| Split the tape, disassemble   | `make oric`                              | cc65           | `oric/*.bin`, `oric/*.s`        |
| Build the C64 port            | `make`                                   | cc65           | `c64/build/lightcycle.prg`      |
| Capture the screens           | `python3 docs/tools/capture_screens.py`  | VICE (`x64sc`) | `docs/images/screens/`          |
| Decode the Oric figures       | `python3 docs/tools/render_graphics.py`  | Pillow, VICE   | `docs/images/graphics/`         |
| Draw the appendix figures     | `python3 docs/tools/render_oric.py`      | Pillow         | `docs/images/graphics/oric-*`   |
| Generate the HTML             | `node docs/tools/build_docs.mjs`         | Node.js 20+    | `docs/LIGHT_CYCLE.html`         |
| Check the HTML is current     | `node docs/tools/build_docs.mjs --check` | Node.js 20+    | –                               |

The `just` recipes wrap them:

```bash
just docs
```

`just docs` runs every step. `just docs-html` only regenerates the HTML from the current Markdown and images, `just
docs-check` fails if a chapter names a label that is not in the source or the saved HTML is stale, and `just docs-watch`
regenerates it whenever a source changes. `just docs-graphics` and `just docs-screens` run one step. The recipes use
`DOCS_PYTHON`, else Homebrew's `python3.14`, else `python3`.

---

## How the Pictures Are Made

- **Screenshots.** `capture_screens.py` boots the build in a fresh headless `x64sc` (default settings, warp, no sound)
  for each capture and saves the screen after a fixed number of CPU cycles, with VICE's random autostart delay turned
  off. The attract cycle takes no input and demo mode starts from a fixed random seed, so the captures repeat exactly.
- **Oric figures.** `render_graphics.py` reads the tape blocks extracted by `make oric` and finds every table by its
  label in `tools/symbols.py`. It draws glyphs 6 pixels wide, as the Oric does, and decodes the title logo's serial
  attributes for its colours. The Oric screen replica runs the game's own round set-up and first frames on
  `tools/cpu6502.py` and renders the memory with the Oric's attributes, borrowing VICE's C64 font for letters (the
  Oric ROM font is not on the tape); the status comparison crops the C64 side from the demo capture, so run it after
  the screen captures. The figures are deterministic.
- **Oric appendix figures.** `render_oric.py` draws the palette, a HIRES line of serial attributes and the AY's
  envelope shapes for `oric_specs.md`. It reads nothing from the game, so the file is the same in every Oric reconstruction.
- **Oric appendix screenshot.** `oric-basic-hires.png` is a capture of `oric_specs.md`'s HIRES BASIC example running in the
  Auric emulator on the Atmos ROM; it is not generated, so re-render it by hand if the example changes.

---

## Chapter Selection and Presentation

`docs/handbook.json` sets the title, the reading order and the groups. A new Markdown file appears only once it is
listed there. `docs/tools/build_docs.mjs` does the conversion: it namespaces the headings by document, rewrites the
links, embeds local images as data URIs, and fails on a broken link, a missing section or a remote image. Raw HTML in
the Markdown is escaped. The layout and controls are `docs/tools/handbook/handbook.html`, `handbook.css` and
`handbook.js`. Mermaid code blocks render in the browser, with the diagram's source under each one.

Generation is deterministic and has no timestamp. The "source revision" is the first 12 hex digits of a SHA-256 over the
hashes of every input file, listed in the page's `source-provenance` block.

`docs/tools/doc_names.py` (`just docs-names`) fails if a chapter's code span names a label that is in neither the Oric
disassembly nor the C64 source. Placeholders that only look like labels go in `docs/tools/doc_names_ignore.txt`.

---

## Third-Party Renderers

The generator uses [Marked](https://marked.js.org/) 17.0.5 to convert the Markdown, and the page embeds
[Mermaid](https://mermaid.js.org/) 10.9.3 for the diagrams. Both are pinned and vendored in `docs/tools/vendor/` with
their licences, which are also reproduced in the handbook. The generator and the page templates are carried over
unchanged from the *Frak!* and *Thing On A Spring* documentation.
