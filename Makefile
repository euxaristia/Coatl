.PHONY: install uninstall local-install local-uninstall

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
PROGRAM ?= coatl
SHAREDIR ?= $(PREFIX)/share/$(PROGRAM)
TARGET ?= $(BINDIR)/$(PROGRAM)
MAN1_TARGET ?= $(MANDIR)/man1/$(PROGRAM).1
LOCAL_PREFIX ?= $(HOME)/.local

install:
	install -d "$(BINDIR)"
	install -m 0755 "$(PROGRAM)" "$(TARGET)"
	install -d "$(MANDIR)/man1"
	install -m 0644 "man/$(PROGRAM).1" "$(MAN1_TARGET)"
	install -d "$(SHAREDIR)"
	cp -a "tools" "$(SHAREDIR)/"
	cp -a "selfhost" "$(SHAREDIR)/"
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

local-install:
	$(MAKE) install PREFIX="$(LOCAL_PREFIX)"

local-uninstall:
	$(MAKE) uninstall PREFIX="$(LOCAL_PREFIX)"
