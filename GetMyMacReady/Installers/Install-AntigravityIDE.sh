#!/usr/bin/env bash
set -euo pipefail

case "$(uname -m)" in
    arm64) platform='darwin-arm' ;;
    x86_64) platform='darwin-x64' ;;
    *)
        printf 'Unsupported macOS architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/${platform}/Antigravity%20IDE.dmg"
temporary_path="$(mktemp -d)"
mount_point=''
cleanup() {
    if [[ -n "$mount_point" ]]; then
        hdiutil detach "$mount_point" -quiet || true
    fi
    rm -rf "$temporary_path"
}
trap cleanup EXIT

archive_path="$temporary_path/AntigravityIDE.dmg"
curl -fsSL "$url" -o "$archive_path"
mount_point="$(hdiutil attach -nobrowse -readonly "$archive_path" | awk '/\/Volumes\// { print substr($0, index($0, "/Volumes/")); exit }')"

if [[ -z "$mount_point" ]]; then
    printf '%s\n' 'Unable to mount the Antigravity IDE disk image.' >&2
    exit 1
fi

application_path="$(find "$mount_point" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [[ -z "$application_path" ]]; then
    printf '%s\n' 'The Antigravity IDE disk image did not contain an application bundle.' >&2
    exit 1
fi

ditto "$application_path" '/Applications/Antigravity IDE.app'
printf '%s\n' 'Antigravity IDE was installed to /Applications/Antigravity IDE.app.'
