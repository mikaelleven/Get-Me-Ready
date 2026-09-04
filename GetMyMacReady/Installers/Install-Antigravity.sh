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

url="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.12.2-6298742303883264/${platform}/Antigravity.dmg"
temporary_path="$(mktemp -d)"
mount_point=''
cleanup() {
    if [[ -n "$mount_point" ]]; then
        hdiutil detach "$mount_point" -quiet || true
    fi
    rm -rf "$temporary_path"
}
trap cleanup EXIT

archive_path="$temporary_path/Antigravity.dmg"
curl -fsSL "$url" -o "$archive_path"
mount_point="$(hdiutil attach -nobrowse -readonly "$archive_path" | awk '/\/Volumes\// { print substr($0, index($0, "/Volumes/")); exit }')"

if [[ -z "$mount_point" ]]; then
    printf '%s\n' 'Unable to mount the Antigravity disk image.' >&2
    exit 1
fi

application_path="$(find "$mount_point" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [[ -z "$application_path" ]]; then
    printf '%s\n' 'The Antigravity disk image did not contain an application bundle.' >&2
    exit 1
fi

ditto "$application_path" '/Applications/Antigravity.app'
printf '%s\n' 'Antigravity 2.0 was installed to /Applications/Antigravity.app.'
