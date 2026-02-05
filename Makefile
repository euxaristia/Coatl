.PHONY: install uninstall local-install local-uninstall

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PROGRAM ?= mee
TARGET ?= $(BINDIR)/$(PROGRAM)
LOCAL_PREFIX ?= $(HOME)/.local

install:
	install -d "$(BINDIR)"
	install -m 0755 "$(PROGRAM)" "$(TARGET)"
	@echo "Installed $(PROGRAM) to $(TARGET)"

uninstall:
	rm -f "$(TARGET)"
	@echo "Removed $(TARGET)"

local-install:
	$(MAKE) install PREFIX="$(LOCAL_PREFIX)"

local-uninstall:
	$(MAKE) uninstall PREFIX="$(LOCAL_PREFIX)"
