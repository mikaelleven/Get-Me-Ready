#!/usr/bin/env bash
set -euo pipefail

case "$(uname -m)" in
    x86_64) platform='x64' ;;
    aarch64|arm64) platform='arm' ;;
    *)
        printf 'Unsupported Linux architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

url="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.12.2-6298742303883264/linux-${platform}/Antigravity.tar.gz"
install_root="${XDG_DATA_HOME:-$HOME/.local/share}/antigravity"
temporary_path="$(mktemp -d)"
trap 'rm -rf "$temporary_path"' EXIT

archive_path="$temporary_path/Antigravity.tar.gz"
curl -fsSL "$url" -o "$archive_path"
tar -xzf "$archive_path" -C "$temporary_path"
application_path="$(find "$temporary_path" -mindepth 1 -maxdepth 1 -type d -name 'Antigravity-*' -print -quit)"

if [[ -z "$application_path" || ! -f "$application_path/antigravity" ]]; then
    printf '%s\n' 'The Antigravity archive did not contain the expected application.' >&2
    exit 1
fi

rm -rf "$install_root"
mkdir -p "$(dirname "$install_root")" "$HOME/.local/bin"
mv "$application_path" "$install_root"
chmod +x "$install_root/antigravity"
ln -sfn "$install_root/antigravity" "$HOME/.local/bin/antigravity"
printf 'Antigravity 2.0 was installed to %s\n' "$install_root"
printf '%s\n' 'Ensure ~/.local/bin is on PATH before running antigravity from a terminal.'
