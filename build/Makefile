
.PHONY: all clean

all: stormcows-fork.xpi

SDIR = ..

SUBDIR = chrome components modules

XPISRC = \
	$(wildcard $(SDIR)/chrome/content/*.xul) \
	$(wildcard $(SDIR)/chrome/content/*.js) \
	$(wildcard $(SDIR)/components/*.js) \
	$(wildcard $(SDIR)/components/*.manifest) \
	$(wildcard $(SDIR)/modules/*.jsm) \
	$(SDIR)/chrome.manifest \
	$(SDIR)/install.rdf \
	$(SDIR)/README

stormcows-fork.xpi: $(XPISRC)
	(cd $(SDIR); zip build/stormcows-fork.xpi $(XPISRC:$(SDIR)/%=%))

clean:
	find $(SDIR) -name '*~' -delete
