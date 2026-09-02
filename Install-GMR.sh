#!/usr/bin/env bash
# Runs the GetMeReady installer appropriate for macOS or Linux.
set -euo pipefail

raw_base_url='https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master'

case "$(uname -s)" in
    Darwin) installer_url="$raw_base_url/GetMyMacReady/Install-GMR.sh" ;;
    Linux) installer_url="$raw_base_url/GetMyNixReady/Install-GMR.sh" ;;
    *)
        printf '%s\n' 'GetMeReady does not support this operating system.' >&2
        exit 1
        ;;
esac

curl -fsSL "$installer_url" | bash
