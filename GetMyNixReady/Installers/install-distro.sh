#!/usr/bin/env bash

# Reusable distro-aware package installer for GMR program installers.
# Usage: install <distro> <package> [package-manager]
# Distro values: default, ubuntu, debian, fedora, arch, or a derivative ID.

set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
    printf 'This installer must be run with Bash.\n' >&2
    return 1 2>/dev/null || exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Cannot detect the Linux distribution: /etc/os-release is missing.\n' >&2
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
detected_id="${ID,,}"
detected_like="${ID_LIKE:-}"

install() {
    local requested_distro="${1:?Missing requested distro}"
    local package_name="${2:?Missing package name}"
    local manager="${3:-}"

    case "$requested_distro" in
        default)
            [[ "$detected_id" == ubuntu || "$detected_id" == debian ]] || return 0
            manager="apt-get"
            ;;
        ubuntu)
            [[ "$detected_id" == ubuntu || "$detected_like" == *ubuntu* ]] || return 0
            manager="apt-get"
            ;;
        debian)
            [[ "$detected_id" == debian || "$detected_like" == *debian* ]] || return 0
            manager="apt-get"
            ;;
        fedora)
            [[ "$detected_id" == fedora || "$detected_like" == *fedora* ]] || return 0
            manager="dnf"
            ;;
        arch)
            [[ "$detected_id" == arch || "$detected_like" == *arch* ]] || return 0
            manager="pacman"
            ;;
        *)
            [[ "$detected_id" == "$requested_distro" ]] || return 0
            ;;
    esac

    if [[ -z "$manager" ]]; then
        printf 'No package manager mapping exists for distro "%s".\n' "$requested_distro" >&2
        return 1
    fi
    command -v "$manager" >/dev/null 2>&1 || {
        printf 'Required package manager is unavailable: %s\n' "$manager" >&2
        return 1
    }

    case "$manager" in
        apt-get|dnf) sudo "$manager" install -y "$package_name" ;;
        pacman) sudo "$manager" -S --needed --noconfirm "$package_name" ;;
        *) printf 'Unsupported package manager: %s\n' "$manager" >&2; return 1 ;;
    esac
}
