.PHONY: all install uninstall test check clean build

PROGRAM = coatl
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
MAN_SRC ?= coatl.1
SHAREDIR ?= $(PREFIX)/share/$(PROGRAM)
TARGET ?= $(BINDIR)/$(PROGRAM)
MAN1_TARGET ?= $(MANDIR)/man1/$(MAN_SRC)
VERSION ?= $(shell git describe --always --dirty --tags 2>/dev/null || echo dev)

all: build

build:
	cargo build --release

test: build
	cargo test

check: test

clean:
	cargo clean
	rm -f examples/hello examples/hello_arm examples/test_fd examples/debug_hello
	rm -f tools/ir_to_aarch64_asm

install: build
	install -d "$(BINDIR)"
	install -m 0755 "target/release/$(PROGRAM)" "$(TARGET)"
	install -d "$(MANDIR)/man1"
	install -m 0644 "man/$(MAN_SRC)" "$(MAN1_TARGET)"
	install -d "$(SHAREDIR)"
	cp -a "tools" "$(SHAREDIR)/"
	install -d "$(SHAREDIR)/runtime"
	install -m 0644 "runtime/intrinsics.s" "$(SHAREDIR)/runtime/intrinsics.s"
	install -m 0644 "runtime/intrinsics_aarch64.s" "$(SHAREDIR)/runtime/intrinsics_aarch64.s"
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
