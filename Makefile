os_name?=
# make file used as base template
# dor go projects

# OS specific part
# -----------------
ifeq ($(OS),Windows_NT)
    os_name = windows
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
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        os_name=LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        os_name=OSX
    endif
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
nullstring :=
space := $(nullstring) 
PSEP = $(strip $(SEP))
PWD ?= $(shell pwd)

# Recursive wildcard 
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

VERSION   ?= $(shell git describe --tags)
REVISION  ?= $(shell git rev-parse HEAD)
BRANCH    ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILDUSER ?= $(shell id -un)
BUILDTIME ?= $(shell date '+%Y%m%d-%H:%M:%S')

MAKEFILE_LIST=Makefile
THIS_FILE := $(lastword $(MAKEFILE_LIST))
PSEP = $(strip $(SEP))
# # subdir where main functions that use these packages are 
# # stored . every directory under cmd is seen as a target
# TARGET = $(notdir $(patsubst %/,%,$(dir $(wildcard ./cmd/*/.))))
CHDIR_SHELL := $(SHELL)
CONTAINER_IMAGE=alpine:latest
# set the following to false if you want to use
# local binaries
DOCKER_ENV = false
CMD_ARGUMENTS ?= $(cmd)
# startup script that runs at container start
STARTUP_SCRIPT ?= $(startup)
# intializing docker container or in case of local
# build, making sure dependancies are insistalled
ifeq ($(DOCKER_ENV),true)
    ifeq ($(shell ${WHICH} docker 2>${DEVNUL}),)
        $(error "docker is not in your system PATH. Please install docker to continue or set DOCKER_ENV = false in make file ")
    endif
    DOCKER_IMAGE ?= $(docker_image)
    DOCKER_CONTAINER_NAME ?=$(container_name)
    DOCKER_CONTAINER_MOUNT_POINT?=$(mount_point)
    ifneq ($(DOCKER_CONTAINER_NAME),)
        CONTAINER_RUNNING := $(shell docker inspect -f '{{.State.Running}}' ${DOCKER_CONTAINER_NAME})
    endif
    ifneq ($(DOCKER_CONTAINER_NAME),)
        DOCKER_IMAGE_EXISTS := $(shell docker images -q ${DOCKER_IMAGE} 2> /dev/null)
    endif
else
    ifeq ($(shell ${WHICH} bash 2>${DEVNUL}),)
        $(error "bash is not in your system PATH. use an os with debian or set DOCKER_ENV = true in make file and use docker build pipeline ")
    endif

endif

.PHONY: all shell clean dep shellcheck install-docker
.SILENT: all shell clean dep

# ex usage to execute a general command : make cmd="ls -lah"
# eg ...
#  make cmd="bin/network --help"
shell:
ifneq ($(DOCKER_ENV),)
ifeq ($(DOCKER_ENV),true)
    ifeq ($(DOCKER_IMAGE_EXISTS),)
	- @docker pull ${DOCKER_IMAGE}
    endif
    ifneq ($(CONTAINER_RUNNING),true)
	- @docker run --entrypoint "/bin/bash" -v ${CnetworkIR}:${DOCKER_CONTAINER_MOUNT_POINT} --name ${DOCKER_CONTAINER_NAME} --rm -d -i -t ${DOCKER_IMAGE} -c tail -f /dev/null
    ifneq ($(STARTUP_SCRIPT),)
	- @docker exec  --workdir ${DOCKER_CONTAINER_MOUNT_POINT} ${DOCKER_CONTAINER_NAME} /bin/bash -c "${STARTUP_SCRIPT}"
    endif
    endif
endif
endif
ifneq ($(CMD_ARGUMENTS),)
    ifeq ($(DOCKER_ENV),true)
        ifneq ($(DOCKER_ENV),)
	- @docker exec  --workdir ${DOCKER_CONTAINER_MOUNT_POINT} ${DOCKER_CONTAINER_NAME} /bin/bash -c "$(CMD_ARGUMENTS)"
        endif
    else
    ifeq ($(shell ${WHICH} shellcheck 2>${DEVNUL}),)
        $(error "shellcheck is not in your system PATH. use an os with debian or set DOCKER_ENV = true in make file and use docker build pipeline ")
    endif
	- @/bin/bash -c "$(CMD_ARGUMENTS)"
    endif
endif
define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

dep: 
	- $(CLEAR)
ifeq ($(shell ${WHICH} shellcheck 2>${DEVNUL}),)
ifeq ($(OS),Windows_NT)
	- $(error this makefile cannot install dependancies on windows.)
else
ifeq ($(shell ${WHICH} wget 2>${DEVNUL}),)
	- $(error wget is not in your system PATH.Please install wget to continue.)
endif	
	- $(info shellcheck is not in your system PATH. installing shellcheck ...)
	- @/bin/bash -c "wget "https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz""
	- @/bin/bash -c "tar -xvf ./shellcheck-stable.linux.x86_64.tar.xz"
	- @/bin/bash -c "sudo cp shellcheck-stable/shellcheck /usr/local/bin/"
	- @/bin/bash -c "rm -rf shellcheck-stable"
endif
else
	- $(info all dependancies have already been installed)
endif
os ?= $(shell lsb_release -cs)	
shellcheck:
	- $(info $(os))

install-docker:
    ifeq ($(shell ${WHICH} apt 2>${DEVNUL}),)
        $(error "apt is not in your system PATH. cannot proceed forward.")
    endif
    ifeq ($(shell ${WHICH} curl 2>${DEVNUL}),)
        $(error "curl is not in your system PATH. cannot proceed forward.")
    endif
	- $(info installing docker)
	- @/bin/bash -c "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - && echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" | sudo tee /etc/apt/sources.list.d/docker.list"
	- @/bin/bash -c "sudo apt update"
	- @/bin/bash -c "sudo apt install -y docker-ce docker-ce-cli containerd.io"
	- @/bin/bash -c "mkdir -p $$HOME/.docker"
	- @/bin/bash -c "sudo usermod -aG docker $$USER"
	- @/bin/bash -c "newgrp docker"
	- @/bin/bash -c "sudo chown "$$USER":"$$USER" $$HOME/.docker -R"
	- @/bin/bash -c "sudo chmod g+rwx "$HOME/.docker" -R"
	- @/bin/bash -c "sudo systemctl enable docker"