.PHONY: install uninstall

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PROGRAM ?= mee
TARGET ?= $(BINDIR)/$(PROGRAM)

install:
	install -d "$(BINDIR)"
	install -m 0755 "$(PROGRAM)" "$(TARGET)"
	@echo "Installed $(PROGRAM) to $(TARGET)"

uninstall:
	rm -f "$(TARGET)"
	@echo "Removed $(TARGET)"
