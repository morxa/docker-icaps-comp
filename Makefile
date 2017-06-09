#
# Makefile
# Till Hofmann, Fri 09 Jun 2017 15:21:53 CEST 15:21
#

GITDIR?=fawkes-robotino
GITREMOTE?=git@git.fawkesrobotics.org:fawkes-robotino.git
GITCOMMIT?=ef797883be3e95a5d96ad880ae603c543928b2e4

all: tarball

git-archive-all.sh:
	curl -o git-archive-all.sh https://raw.githubusercontent.com/meitar/git-archive-all.sh/af81ea772abd0fb281641af19354c9ec741593ad/git-archive-all.sh
	chmod +x git-archive-all.sh

ifeq ($(wildcard $(GITDIR)),)
git: git-clone
else
git: git-set-remote
endif


git-clone:
	git clone --recursive $(GITREMOTE) $(GITDIR)

git-set-remote:
	cd $(GITDIR) && \
	git remote set-url origin $(GITREMOTE)

git:
	cd $(GITDIR) && \
	echo $$PWD && \
	git checkout $(GITCOMMIT) && \
	git submodule update --recursive

tarball: git git-archive-all.sh
	cd $(GITDIR) && \
	../git-archive-all.sh --prefix $(GITDIR)/ ../$(GITDIR).tar



# vim:ft=make
#
