.PHONY: setup install-deps vagrant-up

# Detect OS
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)
ifeq ($(UNAME_S),Linux)
    OS := linux
else ifeq ($(UNAME_S),Darwin)
    OS := mac
else
    OS := windows
endif

setup: install-deps vagrant-up

install-deps:
ifeq ($(OS),windows)
	@echo "Detecting Windows environment..."
	@powershell -Command "if (!(Get-Command vagrant -ErrorAction SilentlyContinue)) { Write-Host 'Installing Vagrant...'; choco install vagrant -y } else { Write-Host 'Vagrant already installed' }"
	@powershell -Command "if (!(Get-Command VBoxManage -ErrorAction SilentlyContinue)) { Write-Host 'Installing VirtualBox...'; choco install virtualbox -y } else { Write-Host 'VirtualBox already installed' }"
else ifeq ($(OS),linux)
	@echo "Detecting Linux environment..."
	@which vagrant > /dev/null || (echo "Installing Vagrant..." && sudo apt update && sudo apt install -y vagrant)
	@which VBoxManage > /dev/null || (echo "Installing VirtualBox..." && sudo apt install -y virtualbox)
else
	@echo "Detecting macOS environment..."
	@which vagrant > /dev/null || (echo "Installing Vagrant..." && brew install vagrant)
	@which VBoxManage > /dev/null || (echo "Installing VirtualBox..." && brew install --cask virtualbox)
endif

vagrant-up:
	@echo "Starting Vagrant..."
	vagrant up