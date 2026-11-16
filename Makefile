# Light Cycle — C64 port build
#
#   make          build c64/build/lightcycle.prg
#   make d64      disk image
#   make run      launch in VICE
#   make smoke    headless boot in VICE, screenshot to c64/build/smoke.png
#   make oric     regenerate + verify the Oric disassembly from CYCLE.TAP

AS      := ca65
LD      := ld65
VICE    := x64sc
C1541   := c1541

SRC_DIR := c64/src
BUILD   := c64/build
CFG     := c64/cfg/c64.cfg

# basic_stub must link first so main's CODE starts at $080D (SYS 2061)
SOURCES := basic_stub.s main.s
OBJECTS := $(addprefix $(BUILD)/,$(SOURCES:.s=.o))
INCLUDES := $(wildcard $(SRC_DIR)/*.inc)

PRG     := $(BUILD)/lightcycle.prg
D64     := $(BUILD)/lightcycle.d64
MAP     := $(BUILD)/lightcycle.map
LABELS  := $(BUILD)/lightcycle.lbl

SMOKE_CYCLES := 4000000

.PHONY: all prg d64 run smoke oric clean

all: prg
prg: $(PRG)

$(BUILD):
	mkdir -p $@

$(BUILD)/%.o: $(SRC_DIR)/%.s $(INCLUDES) | $(BUILD)
	$(AS) -I $(SRC_DIR) -g -o $@ $<

$(PRG): $(OBJECTS) $(CFG)
	$(LD) -C $(CFG) -m $(MAP) -Ln $(LABELS) -o $@ $(OBJECTS)

d64: $(D64)
$(D64): $(PRG)
	$(C1541) -format "light cycle,lc" d64 $@ -write $(PRG) "light cycle" >/dev/null

run: $(PRG)
	$(VICE) -moncommands $(LABELS) -autostart $(PRG)

# Boots the .prg with no UI and writes a screenshot after SMOKE_CYCLES cycles.
smoke: $(PRG)
	$(VICE) -default -console -warp -sounddev dummy \
	  -limitcycles $(SMOKE_CYCLES) -exitscreenshot $(BUILD)/smoke.png \
	  -autostartprgmode 1 -autostart $(PRG) >$(BUILD)/smoke.log 2>&1 || true
	@test -f $(BUILD)/smoke.png && echo "smoke: $(BUILD)/smoke.png" || (echo "smoke: no screenshot"; exit 1)

oric:
	python3 tools/tap_extract.py CYCLE.TAP oric
	python3 tools/build_disasm.py

clean:
	rm -rf $(BUILD)
