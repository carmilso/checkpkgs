PKG := checkpkgs
VERSION := 1.0

SHELL := /bin/bash

LOCALE_DIR ?= /usr/share/locale
LOCAL_LOCALE_DIR := ./locale

PO_FILES := $(wildcard $(LOCAL_LOCALE_DIR)/*.po)

define mo-files
	$(shell	\
		lc="$$(basename $1)";	\
		lng="$${lc/.*}";	\
		mkdir -p $(DESTDIR)$(LOCALE_DIR)/"$$lng"/LC_MESSAGES;	\
		msgfmt -v $1 -o $(DESTDIR)$(LOCALE_DIR)/"$$lng"/LC_MESSAGES/$(PKG).mo	\
	)
endef

all:	mofiles

potfile:	$(PKG).sh
	$(shell	\
		xgettext \
		--package-name=$(PKG)	\
		--package-version=$(VERSION)	\
		--from-code=UTF-8	\
		-L shell	\
		--package-name=$(PKG)	\
		-o $(DESTDIR)$(LOCALE_DIR)/$(PKG).pot ./$(PKG).sh	\
	)

mofiles:	$(PO_FILES)
	$(foreach PO_FILE, $(PO_FILES), $(call mo-files, $(PO_FILE)))

msginit:
	$(shell	\
		echo -n "Locale to be created: " 1>&2;	\
		read -r lang;	\
		msginit -i $(LOCAL_LOCALE_DIR)/$(PKG).pot -l "$$lang" -o $(LOCAL_LOCALE_DIR)/"$$lang".po	\
	)

man:
	$(shell \
		pandoc -s -t man $(PKG).8.md -o $(PKG).8	\
	)

install: mofiles man
	install -Dm755 $(PKG).sh $(DESTDIR)/usr/bin/$(PKG)
	install -Dm644 completion/bash $(DESTDIR)/usr/share/bash-completion/completions/$(PKG)
	install -Dm644 completion/zsh $(DESTDIR)/usr/share/zsh/site-functions/_$(PKG)
	install -Dm644 $(PKG).8 $(DESTDIR)/usr/share/man/man8/$(PKG).8

uninstall:
	$(RM) $(DESTDIR)/usr/bin/$(PKG)
	$(RM) $(DESTDIR)/usr/share/bash-completion/completions/$(PKG)
	$(RM) $(DESTDIR)/usr/share/zsh/site-functions/_$(PKG)
	$(RM) $(DESTDIR)/usr/share/man/man8/$(PKG).8
