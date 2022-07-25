TARGETDIR := ./bin/
TARGETFILE := Universal.img
SOURCEDIR := ./src/

TARGETPATH := $(TARGETDIR)$(TARGETFILE)

all: $(TARGETPATH)

clear:
	rm $(TARGETDIR)*.*

rebuild: clear all

$(TARGETDIR)boot.bin: $(SOURCEDIR)boot/boot.asm
	nasm $^ -f bin -o $@

$(TARGETPATH): $(TARGETDIR)boot.bin
	cat $^ > $@