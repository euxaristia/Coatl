.PHONY: install uninstall local-install local-uninstall

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
PROGRAM ?= coatl
TARGET ?= $(BINDIR)/$(PROGRAM)
MAN1_TARGET ?= $(MANDIR)/man1/$(PROGRAM).1
LOCAL_PREFIX ?= $(HOME)/.local

install:
	install -d "$(BINDIR)"
	install -m 0755 "$(PROGRAM)" "$(TARGET)"
	install -d "$(MANDIR)/man1"
	install -m 0644 "man/$(PROGRAM).1" "$(MAN1_TARGET)"
	@echo "Installed $(PROGRAM) to $(TARGET)"
	@echo "Installed man page to $(MAN1_TARGET)"

uninstall:
	rm -f "$(TARGET)"
	rm -f "$(MAN1_TARGET)"
	@echo "Removed $(TARGET)"
	@echo "Removed $(MAN1_TARGET)"

local-install:
	$(MAKE) install PREFIX="$(LOCAL_PREFIX)"

local-uninstall:
	$(MAKE) uninstall PREFIX="$(LOCAL_PREFIX)"
