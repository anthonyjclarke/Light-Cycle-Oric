# Light Cycle — C64 port build
#
#   make          build c64/build/lightcycle.prg
#   make d64      disk image
#   make run      launch in VICE
#   make smoke    headless boot in VICE, screenshots to c64/build/
#   make oric     regenerate + verify the Oric disassembly from CYCLE.TAP
#   make tap      assemble the Oric source into build/CYCLE.TAP
#   make verify   build/CYCLE.TAP, checked byte for byte against the original CYCLE.TAP
#   make oric-run build/CYCLE.TAP in the Auric emulator, Oric-1 mode (AURIC_DIR)
#   make intro    redraw the intro picture (c64/src/intro.rle)
#   make tables   re-export the Oric data tables (c64/src/oric_tables.inc)

AS      := ca65
LD      := ld65
VICE    := x64sc
C1541   := c1541

SRC_DIR := c64/src
BUILD   := c64/build
CFG     := c64/cfg/c64.cfg

# basic_stub must link first so main's CODE starts at $080D (SYS 2061)
SOURCES := basic_stub.s main.s intro.s game.s player.s ai.s arena.s explosion.s bonus.s score.s hud.s oric_tables.s \
           platform.s video.s plot.s timing.s input.s sound.s zp.s
OBJECTS := $(addprefix $(BUILD)/,$(SOURCES:.s=.o))
INCLUDES := $(wildcard $(SRC_DIR)/*.inc)

PRG     := $(BUILD)/lightcycle.prg
D64     := $(BUILD)/lightcycle.d64
MAP     := $(BUILD)/lightcycle.map
LABELS  := $(BUILD)/lightcycle.lbl

.PHONY: all prg d64 run smoke oric tap verify oric-run intro tables clean

all: prg
prg: $(PRG)

$(BUILD):
	mkdir -p $@

$(BUILD)/intro.o: $(SRC_DIR)/intro.rle

$(BUILD)/%.o: $(SRC_DIR)/%.s $(INCLUDES) | $(BUILD)
	$(AS) -I $(SRC_DIR) --bin-include-dir $(SRC_DIR) -g -o $@ $<

$(PRG): $(OBJECTS) $(CFG)
	$(LD) -C $(CFG) -m $(MAP) -Ln $(LABELS) -o $@ $(OBJECTS)

d64: $(D64)
$(D64): $(PRG)
	$(C1541) -format "light cycle,lc" d64 $@ -write $(PRG) "light cycle" >/dev/null

run: $(PRG)
	$(VICE) -moncommands $(LABELS) -autostart $(PRG)

# Boots the .prg headless in VICE and saves each capture (docs/tools/capture_screens.py) to c64/build/.
smoke: $(PRG)
	python3 docs/tools/capture_screens.py --out $(BUILD)

oric:
	python3 tools/tap_extract.py CYCLE.TAP oric
	python3 tools/build_disasm.py

# The Oric original, assembled from oric/loader.s and oric/game.s
TAP       := build/CYCLE.TAP
AURIC_DIR ?= $(HOME)/PlatformIO/Projects/Auric

tap: $(TAP)
$(TAP): oric/loader.s oric/game.s tools/build_tap.py
	python3 tools/build_tap.py $@

verify: $(TAP)
	@cmp $(TAP) CYCLE.TAP && echo "OK: $(TAP) is byte-identical to CYCLE.TAP"

# Auric reads auric.yaml and ROMS/ from its working directory
oric-run: $(TAP)
	cd "$(AURIC_DIR)" && ./build/src/auric --oric1 --tape "$(abspath $(TAP))"

DOCS_PY ?= $(shell command -v python3.14 || echo python3)

intro:
	$(DOCS_PY) tools/make_intro.py

tables:
	python3 tools/export_tables.py

clean:
	rm -rf $(BUILD) build
