#!/usr/bin/env bash
# Downloads the Linux GetMeReady registry without requiring Git.
set -euo pipefail

repository_archive_url='https://github.com/mikaelleven/Get-Me-Ready/archive/refs/heads/master.tar.gz'
install_path="${XDG_DATA_HOME:-${HOME}/.local/share}/GetMeReady"

if [[ "$(uname -s)" != 'Linux' ]]; then
    printf '%s\n' 'This installer supports Linux only.' >&2
    exit 1
fi

if [[ -e "$install_path" ]]; then
    printf 'Installation path already exists: %s\n' "$install_path" >&2
    printf '%s\n' 'Move it first, or use a different installation path after downloading this script.' >&2
    exit 1
fi

temporary_path="$(mktemp -d "${TMPDIR:-/tmp}/GetMeReady.XXXXXX")"
trap 'rm -rf "$temporary_path"' EXIT

archive_path="$temporary_path/GetMeReady.tar.gz"
expanded_path="$temporary_path/expanded"
mkdir -p "$expanded_path"

curl -fsSL "$repository_archive_url" -o "$archive_path"
tar -xzf "$archive_path" -C "$expanded_path"

archive_root="$(find "$expanded_path" -mindepth 1 -maxdepth 1 -type d -print -quit)"
source_path="$archive_root/GetMyNixReady"

if [[ -z "$archive_root" || ! -d "$source_path" ]]; then
    printf '%s\n' 'The downloaded archive did not contain the Linux registry.' >&2
    exit 1
fi

mkdir -p "$(dirname "$install_path")"
cp -R "$source_path" "$install_path"
printf 'GetMeReady Linux registry was installed to %s\n' "$install_path"
printf '%s\n' 'A Linux GMR runner is not available yet, so no setup actions were executed.'
