include vars.mk
define rwildcard
$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))
endef
ifeq ($(OS),Windows_NT)
    CLEAR = cls
    LS = dir
    TOUCH =>> 
    RM = del /F /Q
    CPF = copy /y
    RMDIR = -RMDIR /S /Q
    MKDIR = -mkdir
    ERRIGNORE = 2>NUL || (exit 0)
    SEP=\\
else
    CLEAR = clear
    LS = ls
    TOUCH = touch
    CPF = cp -f
    RM = rm -rf 
    RMDIR = rm -rf 
    MKDIR = mkdir -p
    ERRIGNORE = 2>/dev/null
    SEP=/
endif
ifeq ($(findstring cmd.exe,$(SHELL)),cmd.exe)
DEVNUL := NUL
WHICH := where
else
DEVNUL := /dev/null
WHICH := which
endif
null :=
space := ${null} ${null}
P_OP :=(
P_CL :=)
PSEP = $(strip $(SEP))
PROJECT_NAME := $(notdir $(CURDIR))
PWD ?= $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
# ${ } is a space
${space} := ${space}
SHELL := /bin/bash

THIS_FILE := $(lastword $(MAKEFILE_LIST))
SELF_DIR := $(dir $(THIS_FILE))

VERSION   ?= $(shell git describe --tags)
REVISION  ?= $(shell git rev-parse HEAD)
BRANCH    ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILDUSER ?= $(shell id -un)
BUILDTIME ?= $(shell date '+%Y%m%d-%H:%M:%S')
MAJORVERSION ?= $(shell git describe --tags --abbrev=0 | sed s/v// |  awk -F. '{print $$1+1".0.0"}')
MINORVERSION ?= $(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2+1".0"}')
PATCHVERSION ?= $(shell git describe --tags --abbrev=0 | sed s/v// | awk -F. '{print $$1"."$$2"."$$3+1}')



YMLS:= $(sort $(call rwildcard,$(SCENES_ROOT)/,*.yml))
CASTS:=$(sort $(call rwildcard,$(CASTS_ROOT)/,*.cast))
MARKDOWNS:=$(sort $(call rwildcard,$(DOCS_ROOT)/,*.md))


SCENES_TARGETS :=$(sort $(subst /,_,$(patsubst $(SCENES_ROOT)/%.yml,%,$(YMLS))))
CASTS_TARGETS :=$(sort $(subst /,_,$(patsubst $(CASTS_ROOT)/%.cast,cast_%,$(CASTS))))
PDF_TARGETS :=$(sort $(subst /,_,$(patsubst $(DOCS_ROOT)/%.md,pdf_%,$(MARKDOWNS))))

SNAP := $(shell command -v snap 2> /dev/null)
SSH_PASS := $(shell command -v sshpass 2> /dev/null)
JQ := $(shell command -v jq 2> /dev/null)
LXC := $(shell command -v lxc 2> /dev/null)

all:
# ifndef LXC
# ifndef SNAP
#     $(error "'snap' is not available. please install snap package manager before continuing.")
# endif
# endif
ifndef SSH_PASS
    $(error "'sshpass' is not available. please install sshpass before continuing.")
endif
ifndef JQ
    $(error "'jq' is not available. please install jq before continuing.")
endif
.PHONY:init
.SILENT:init
init:	
	- chmod +x contrib/scripts/env-init
ifndef LXC
	- contrib/scripts/env-init --lxd-init
endif
	- contrib/scripts/env-init --container-init '$(CONTAINER_NAME)'
	- contrib/scripts/env-init --recording-init '$(CONTAINER_NAME)'
.PHONY: git 
.SILENT:git 
git:
	- $(info VERSION = $(VERSION))
	- $(info REVISION = $(REVISION))
	- $(info BRANCH = $(BRANCH))
	- $(info BUILDUSER = $(BUILDUSER))
	- $(info BUILDTIME = $(BUILDTIME))
	- $(info MAJORVERSION = $(MAJORVERSION))
	- $(info MINORVERSION = $(MINORVERSION))
	- $(info PATCHVERSION = $(PATCHVERSION))
.PHONY: release-major
.SILENT: release-major
release-major:
	- git checkout master
	- git pull
	- git tag -a v$(MAJORVERSION) -m 'release $(MAJORVERSION)'
	- git push origin --tags
.PHONY: release-minor
.SILENT: release-minor
release-minor:
	- git checkout master
	- git pull
	- git tag -a v$(MINORVERSION) -m 'release $(MINORVERSION)'
	- git push origin --tags
.PHONY :release-patch
.SILENT :release-patch
release-patch:
	- git checkout master
	- git pull
	- git tag -a v$(PATCHVERSION) -m 'release $(PATCHVERSION)'
	- git push origin --tags
.PHONY: build-image
.SILENT: build-image
build-image: 
	- $(info building screencasts docker image)
	- docker build -t screencasts:latest contrib/screencasts
.PHONY: record
.SILENT: record
record: 
	- @$(MAKE) --no-print-directory -f $(THIS_FILE) $(SCENES_RECORD_TARGETS)
.PHONY: clean
.SILENT: clean
clean: 
	- @$(MAKE) --no-print-directory -f $(THIS_FILE) $(SCENES_CLEAN_TARGETS)
.PHONY: upload
.SILENT: upload
upload: 
	- @$(MAKE) --no-print-directory -f $(THIS_FILE) $(UPLOAD_TARGETS)
.PHONY: pdf
.SILENT: pdf
pdf: 
	- @$(MAKE) --no-print-directory -f $(THIS_FILE) $(PDF_TARGETS)

.PHONY: $(PDF_TARGETS)
.SILENT: $(PDF_TARGETS)
$(PDF_TARGETS):  
	- $(eval path=$(subst _,/,$(@:pdf_%=%)))
	- pandoc $(PWD)/docs/$(path).md -o $(PWD)/docs/$(path).pdf
UPLOAD_TARGETS:= $(CASTS_TARGETS:%=upload_%)
.PHONY: $(UPLOAD_TARGETS)
.SILENT: $(UPLOAD_TARGETS)
$(UPLOAD_TARGETS):  
	- $(eval path=$(subst _,/,$(@:upload_cast_%=%)))
	- $(eval cast=$(PWD)/$(CASTS_ROOT)/$(path).cast)
	- echo "$(path)" >> screen-casts.list && \
	asciinema upload '$(cast)' | grep 'asciinema' >> screen-casts.list

SCENES_RECORD_TARGETS:= $(SCENES_TARGETS:%=record_%)
.PHONY: $(SCENES_RECORD_TARGETS)
.SILENT: $(SCENES_RECORD_TARGETS)
$(SCENES_RECORD_TARGETS):  record_%:directory_%
	- $(eval path=$(subst _,/,$(@:record_%=%)))
	- $(eval script=$(PWD)/$(SCENES_ROOT)/$(path).yml)
	- $(eval output=$(PWD)/$(CASTS_ROOT)/$(path).cast)
	- spielbash -v record --script='$(script)' -o '$(output)'

SCENES_DIRECTORY_TARGETS:=$(SCENES_TARGETS:%=directory_%)
$(SCENES_DIRECTORY_TARGETS): directory_%:clean_%
	- $(eval path=$(subst _,/,$(@:directory_%=%)))
	- $(eval directory=$(PWD)/$(CASTS_ROOT)/$(dir $(path)))
	- $(info $(directory))
	- $(MKDIR) $(directory)
SCENES_CLEAN_TARGETS:=$(SCENES_TARGETS:%=clean_%)
$(SCENES_CLEAN_TARGETS): 
	- $(eval path=$(subst _,/,$(@:clean_%=%)))
	- $(eval clean=$(PWD)/$(CASTS_ROOT)/$(path).cast)
	- $(RM) $(clean)
.PHONY: list-targets
.SILENT: list-targets
list-targets: 
	- $(info record targets >> )
	- $(foreach O,\
			$(SCENES_RECORD_TARGETS),\
			$(info  make -j$$(nproc) $O)\
		)
	- $(info upload targets >> )
	- $(foreach O,\
			$(UPLOAD_TARGETS),\
			$(info  make -j$$(nproc) $O)\
		)
	- $(info pdf targets >> )
	- $(foreach O,\
			$(PDF_TARGETS),\
			$(info  make -j$$(nproc) $O)\
		)