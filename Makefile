SHELL=/bin/bash
DISTRO=trixie

REPOROOT=/usr/local/repo/web
WEBPUBLIC=$(REPOROOT)/public/debian
PUBKEY=$(WEBPUBLIC)/quadpbx.gpg.key

SRCKEY=secret/quadpbx.signing.key

INCOMING ?= $(shell pwd)/incoming
ARCHIVE ?= $(shell pwd)/archive

DNAME=reprepro

DPARAMS=-e DISTRO=$(DISTRO) -v $(shell pwd):/depot -v $(INCOMING):/incoming -v $(WEBPUBLIC):/debian -v $(ARCHIVE):/archive-$(DISTRO) --rm $(DNAME)

MKDIRS=$(INCOMING) $(ARCHIVE) $(WEBPUBLIC) $(REPOROOT)

export DISTRO INCOMING

.PHONY: docker shell
docker: .dockerimg

.PHONY: shell
shell: .dockerimg
	docker run -it -w /depot $(DPARAMS) bash

.PHONY: repo
repo: .dockerimg $(WEBROOTPUBKEY) $(WEBPUBLIC)/conf/distributions $(WEBPUBLIC)/quadpbx.sources $(WEBPUBLIC)/quadpbx-$(DISTRO).apt.source $(WEBPUBLIC)/quadpbx.apt.source $(WEBPUBLIC)/conf/override | $(MKDIRS)
	DEBS="$(wildcard $(INCOMING)/*deb)"; if [ "$$DEBS" ]; then \
		echo "Processing '$$DEBS'"; \
		docker run -it -w /depot $(DPARAMS) ./import.sh; \
	else \
		echo "No debs to import"; \
	fi

.dockerimg: docker/repo-signing-key-fingerprint docker/repo-signing-key $(wildcard docker/*) | $(MKDIRS)
	docker build -t $(DNAME) docker && touch .dockerimg

$(MKDIRS):
	mkdir -p $@

# These are gitignored
docker/repo-signing-key: $(SRCKEY)
	@cp $< $@

docker/repo-signing-key-fingerprint: $(SRCKEY)
	@gpg --list-packets $< | awk '/hashed subpkt 33/ { print $$9; exit }' | tr -d ')' > $@

$(SRCKEY):
	@echo "Package signing key missing, can't continue" && exit 99

$(WEBPUBLIC)/conf/distributions: templates/distributions.template docker/repo-signing-key-fingerprint
	@mkdir -p $(@D)
	@sed -e 's/__SIGNINGKEY__/$(shell cat docker/repo-signing-key-fingerprint)/' -e 's/__DISTRO__/$(DISTRO)/' < templates/distributions.template > $@

$(WEBPUBLIC)/conf/override: override
	@cp $< $@

$(WEBROOTPUBKEY) $(PUBKEY): docker/repo-signing-key-fingerprint | $(MKDIRS)
	gpg --export -a --export-options export-minimal $(shell cat $<) > $@

$(WEBPUBLIC)/quadpbx.sources: templates/quadpbx.sources.template $(PUBKEY) | $(MKDIRS)
	@sed -e 's/__DISTRO__/$(DISTRO)/' < templates/quadpbx.sources.template > $@

$(WEBPUBLIC)/quadpbx-$(DISTRO).apt.source $(WEBPUBLIC)/quadpbx.apt.source: templates/quadpbx.aptsource.template $(PUBKEY) | $(MKDIRS)
	@sed -e 's/__DISTRO__/$(DISTRO)/' < templates/quadpbx.aptsource.template > $@
	

