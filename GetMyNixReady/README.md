# GetMeReady

## What is GetMeReady?

GetMeReady (GMR) is a bootstrapper for a new Linux computer. It collects the
software, tools, and follow-up actions you want, then applies the selected
configuration with as little interaction as possible.

Package lists use the Linux distribution's package manager. Other actions—
such as running a shell script, executing a program, or opening a URL—are
described in GMR files. This keeps a standard setup repeatable while allowing
machine-specific choices.

## Online install

Run this in an interactive terminal to download the Linux registry to
`${XDG_DATA_HOME:-$HOME/.local/share}/GetMeReady`:

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/GetMyNixReady/Install-GMR.sh | bash
```

The command downloads and executes remote code. Review
[Install-GMR.sh](Install-GMR.sh) before running it if you do not trust the
source. The installer does not overwrite an existing installation. A Linux GMR
runner is not available yet, so it installs the registry but cannot execute
setup actions.

## Requirements

- A supported Linux distribution with its package manager;
- Bash and an interactive terminal session;
- Permission to install the selected software.

## Registry layout

The Linux registry consists of `.gmr` modules beside this README. It uses the
shared GMR format described in the repository-root [RULES.md](../RULES.md),
but commands must be valid Linux commands. Do not execute this registry with
the Windows or macOS agent.

## Modules and entries

Use a `.gmr` file for Linux packages or actions—one entry per line. The package
manager and package names must match the target distribution:

```text
# name: Terminal Tools & Tweaks
# sortindex: 145

"Example tool" : $> <package-manager> install <package-name>
```

The `$>` operator is required for every script or shell command. `PS>` is
obsolete and must not be used. Script technology is implicit: Linux uses Bash
for `.sh` scripts and shell commands.

Relative script paths resolve from the module directory. Review remote
installer commands before execution; they download and execute code.

## Program catalog

See [ProgramCatalog.md](ProgramCatalog.md) for the programs represented by the
Linux modules. Regenerate it from the repository root with:

```powershell
..\UpdateProgramCatalog.ps1 GetMyNixReady
```

The Windows, macOS, and Linux registries share the same catalog generator, but
each registry has its own generated `ProgramCatalog.md`.

## Development

Keep module names descriptive and preserve the common GMR metadata rules. Use
an application-specific `.sh` script for multi-step installation or
configuration and reference it from the module with `$> <script filename>`.

Before handoff, validate module syntax, confirm that every path and command is
Linux-specific, and run the catalog generator to verify the resulting program
list.
