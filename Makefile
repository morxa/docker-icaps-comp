#
# Makefile
# Till Hofmann, Fri 09 Jun 2017 15:21:53 CEST 15:21
#

BASENAME?=fawkes-robotino
GITREMOTE?=git@git.fawkesrobotics.org:fawkes-robotino.git
GITCOMMIT?=9f10367fee2a82cd12b7eb40d89923416a4e161c
GITDIR?=$(BASENAME)-$(GITCOMMIT)
TARBALL?=$(GITDIR).tar
IMAGE?=$(BASENAME):$(GITCOMMIT)

image: build
	cd build && \
	docker build -t $(IMAGE) .

build: $(TARBALL) fawkes-pre.rosinstall Dockerfile run-component setup.bash localize-robot
	mkdir -p build
	cp -p $(TARBALL) build/$(BASENAME).tar
	cp -p fawkes-pre.rosinstall build/
	cp -p Dockerfile build/
	cp -p run-component build/
	cp -p setup.bash build/
	cp -p localize-robot build/


git-archive-all.sh:
	curl -o git-archive-all.sh https://raw.githubusercontent.com/meitar/git-archive-all.sh/af81ea772abd0fb281641af19354c9ec741593ad/git-archive-all.sh
	chmod +x git-archive-all.sh

GITDEPS=
ifeq ($(wildcard $(GITDIR)),)
  GITDEPS=git-clone
else
  CURRENTREMOTE=$(shell cd $(GITDIR) && git remote get-url origin)
  ifneq ($(GITREMOTE),$(CURRENTREMOTE))
    GITDEPS=git-set-remote
  endif
endif


git-clone:
	git clone --recursive $(GITREMOTE) $(GITDIR)

git-set-remote:
	cd $(GITDIR) && \
	git remote set-url origin $(GITREMOTE)

.PHONY: git-clone git-set-remote

$(GITDIR): $(GITDEPS)
	cd $(GITDIR) && \
	git fetch && \
	git checkout $(GITCOMMIT) && \
	git submodule update --recursive

$(TARBALL): git-archive-all.sh $(GITDIR)
	cd $(GITDIR) && \
	../git-archive-all.sh --prefix $(BASENAME)/ ../$(TARBALL)


# vim:ft=make
#
