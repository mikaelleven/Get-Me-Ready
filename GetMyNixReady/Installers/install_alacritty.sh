#!/usr/bin/env bash

set -euo pipefail
script_directory="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck disable=SC1091
source "$script_directory/install-distro.sh"

# The default package is used only on Ubuntu/Debian. Other supported
# distributions select their native package explicitly.
install default alacritty
install fedora alacritty
install arch alacritty
# Proxmox is Debian-based, but remains an explicit extension point for a
# future Proxmox-specific package name or installation rule.
install proxmox alacritty
