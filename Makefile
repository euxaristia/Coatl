.PHONY: all install uninstall test check clean

all:

test:
	./tests/run_ir_smoke.sh

check: test

clean:
	rm -f *.wat *.s *.ir *.bin *.log *.asm *.dump
	rm -f examples/*.wat examples/*.s examples/*.ir examples/*.asm examples/*.bin examples/*.log examples/*.dump
	rm -f examples/hello examples/hello_arm examples/test_fd examples/debug_hello
	rm -f tools/ir_to_aarch64_asm

PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
PROGRAM ?= coatl
SHAREDIR ?= $(PREFIX)/share/$(PROGRAM)
TARGET ?= $(BINDIR)/$(PROGRAM)
MAN1_TARGET ?= $(MANDIR)/man1/$(PROGRAM).1

install:
	install -d "$(BINDIR)"
	install -m 0755 "$(PROGRAM)" "$(TARGET)"
	install -d "$(MANDIR)/man1"
	install -m 0644 "man/$(PROGRAM).1" "$(MAN1_TARGET)"
	install -d "$(SHAREDIR)"
	cp -a "tools" "$(SHAREDIR)/"
	cp -a "selfhost" "$(SHAREDIR)/"
	install -d "$(SHAREDIR)/tests"
	install -m 0644 "tests/intrinsics.s" "$(SHAREDIR)/tests/intrinsics.s"
	@echo "Installed $(PROGRAM) to $(TARGET)"
	@echo "Installed man page to $(MAN1_TARGET)"
	@echo "Installed runtime assets to $(SHAREDIR)"

uninstall:
	rm -f "$(TARGET)"
	rm -f "$(MAN1_TARGET)"
	rm -rf "$(SHAREDIR)"
	@echo "Removed $(TARGET)"
	@echo "Removed $(MAN1_TARGET)"
	@echo "Removed $(SHAREDIR)"
