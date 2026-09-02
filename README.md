# Get Me Ready (GMR)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Downloads](https://img.shields.io/github/downloads/mikaelleven/Get-Me-Ready/total?label=downloads)](https://github.com/mikaelleven/Get-Me-Ready/releases)
[![Windows: beta](https://img.shields.io/badge/Windows-beta-blue)](GetMyWinReady/README.md)
[![macOS: pre-alpha](https://img.shields.io/badge/macOS-pre--alpha-lightgrey)](GetMyMacReady/README.md)
[![Linux: WIP](https://img.shields.io/badge/Linux-WIP-orange)](GetMyNixReady/README.md)

GetMeReady (GMR) is a collection of platform-specific bootstrappers and
registries for setting up a new computer repeatably. Select the software,
tools, and follow-up actions you need, then let the platform agent apply that
configuration with minimal interaction. It reduces the work of remembering,
finding, and manually reinstalling the components of a standard fresh-machine
setup; selected installers may still require credentials or confirmation.

Package installation uses the native package manager for the selected
platform. GMR modules can also run local scripts or commands and open URLs,
which supports configuration steps that a package manager cannot express.
Review every selected action before running it, especially entries that download
and execute remote code.

## Platform status and documentation

| Platform | Status | Registry and guide |
| --- | --- | --- |
| Windows | Beta | [GetMyWinReady](GetMyWinReady/README.md) — PowerShell and WinGet |
| macOS | Pre-alpha | [GetMyMacReady](GetMyMacReady/README.md) — Bash and Homebrew |
| Linux | Work in progress | [GetMyNixReady](GetMyNixReady/README.md) — Bash and the distribution package manager |

Each registry is platform-specific. The common GMR format makes module
structure consistent; it does **not** make commands portable. Use only the
registry and agent intended for your operating system.

## Quick start

Run the online installer from an interactive terminal. Use the command native
to your platform:

- **Windows (PowerShell 5.1+ or PowerShell 7):**

  ```powershell
  irm https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/Install-GMR.ps1 | iex
  ```

- **macOS or Linux (Bash):**

  ```bash
  curl -fsSL https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/Install-GMR.sh | bash
  ```

Both installers detect the operating system and start its platform-specific
installer. The PowerShell command can also run on macOS or Linux when
PowerShell 7 (`pwsh`) is installed, but Bash is the native and recommended
option on those platforms. Both commands download and execute remote code, so
inspect the linked installer before running it if you do not trust the source.

- **Windows:** follow the [GetMyWinReady guide](GetMyWinReady/README.md). Its
  current beta entry point is `GMR.ps1`; it discovers the descriptors beside
  it and presents an interactive selection menu.
- **macOS:** follow the [GetMyMacReady guide](GetMyMacReady/README.md),
  including its Homebrew requirement.
- **Linux:** follow the [GetMyNixReady guide](GetMyNixReady/README.md),
  including the supported distribution and package-manager requirements.

Do not execute a Windows descriptor on macOS or Linux, or a macOS/Linux module
with the Windows agent.

## GMR modules

Platform registries contain `.gmr` modules. A module describes package entries
and actions for one selectable setup category. The shared syntax supports
metadata such as a display name, ordering, default selection, required entries,
and inclusion of another module. Entries can be optional or required, can have
a display title, and use `$>` for shell commands and local scripts.

The full, authoritative shared format is in [RULES.md](RULES.md). Platform
package-manager conventions, supported action types, examples, and operational
details are documented in each platform README:

- [Windows module and `.gmrs` action syntax](GetMyWinReady/README.md#gmrs-syntax)
- [macOS modules and entries](GetMyMacReady/README.md#modules-and-entries)
- [Linux modules and entries](GetMyNixReady/README.md#modules-and-entries)

Keep scripts alongside the registry that invokes them. Relative script paths
are resolved from the module directory.

## Project layout

```text
GetMeReady/
├── GetMyWinReady/   Windows registry, PowerShell runner, and WinGet modules
├── GetMyMacReady/   macOS registry and Homebrew-oriented modules
├── GetMyNixReady/   Linux registry and distribution-specific modules
├── RULES.md         Shared GMR module contract
├── Release.ps1      Builds and publishes GitHub release archives
└── UpdateProgramCatalog.ps1
```

Each platform has its own generated `ProgramCatalog.md`. It is both the
catalog of programs available through that registry and a browsable reference
for discovering tools to install manually. Update the relevant catalog after
adding, removing, or renaming programs; see the platform guide for its catalog
workflow.

## Creating releases

`Release.ps1` creates a versioned `all` archive and separate Windows, macOS,
and Linux archives in `artifacts/`. It reads the four-part version in `VERSION`
and, when publishing, bumps the minor component by default. Use `-Patch` or
`-Major` to choose another increment, or `-NoBump` to release the current
version unchanged:

```powershell
.\Release.ps1
.\Release.ps1 -Patch
.\Release.ps1 -Major
.\Release.ps1 -NoBump
```

Publishing requires a clean parent repository, Git, and an authenticated
[GitHub CLI](https://cli.github.com/) session (`gh auth login`). Unless
`-NoBump` is used, the script commits and pushes the new `VERSION`, then creates
the matching GitHub tag and release with all four archives. Use `-PackageOnly`
to produce the selected-version archives locally without modifying Git or
GitHub.

## Contributing

Keep changes scoped to the target platform registry and preserve the shared
module contract. Validate commands, paths, scripts, and package names on their
target platform only. For module changes, use the validation checklist in
[RULES.md](RULES.md#validation-checklist) and the development guidance in the
corresponding platform README.

## License

GetMeReady is licensed under the [MIT License](LICENSE).
