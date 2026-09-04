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

url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-${platform}/Antigravity%20IDE.tar.gz"
install_root="${XDG_DATA_HOME:-$HOME/.local/share}/antigravity-ide"
temporary_path="$(mktemp -d)"
trap 'rm -rf "$temporary_path"' EXIT

archive_path="$temporary_path/AntigravityIDE.tar.gz"
curl -fsSL "$url" -o "$archive_path"
tar -xzf "$archive_path" -C "$temporary_path"
application_path="$temporary_path/Antigravity IDE"

if [[ ! -f "$application_path/antigravity-ide" ]]; then
    printf '%s\n' 'The Antigravity IDE archive did not contain the expected application.' >&2
    exit 1
fi

rm -rf "$install_root"
mkdir -p "$(dirname "$install_root")" "$HOME/.local/bin"
mv "$application_path" "$install_root"
chmod +x "$install_root/antigravity-ide"
ln -sfn "$install_root/antigravity-ide" "$HOME/.local/bin/antigravity-ide"
printf 'Antigravity IDE was installed to %s\n' "$install_root"
printf '%s\n' 'Ensure ~/.local/bin is on PATH before running antigravity-ide from a terminal.'
