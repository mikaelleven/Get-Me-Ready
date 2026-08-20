# GMR module rules

This document defines the shared interpretation rules for GetMeReady (GMR)
modules. The same file format and naming conventions are used by the Mac,
Windows, and Linux registries. Commands remain platform-specific and must only
be executed by the registry for which they were written.

## Module files

- A module is a `.gmr` file in the platform registry directory.
- The file name is the stable technical module name. Use a descriptive
  PascalCase name, with `.gmr` as the extension.
- `# name: <text>` is the user-facing module name. If omitted, the file name
  is used.
- `# sortindex: <integer>` controls module ordering. Lower values appear
  first; equal values are ordered by file name.
- `# selected: true|false` controls whether the module is initially selected.
- `# required: true|false` keeps the module enabled and prevents deselection.
- `# include: <file.gmr>` includes another `.gmr` file relative to the module.
  Circular includes are invalid.
- Blank lines and lines beginning with `#` are metadata or comments.

Boolean metadata accepts `true`, `false`, `yes`, and `no`.

## Entry format

Each non-comment entry contains one command. Optional prefixes appear before
the command, which is separated with `>` for actions:

```text
[prefixes] > command
```

Without `>` an entry is a package entry. The Windows implementation uses
WinGet; other platform agents use their native package manager.

### Selection and requirement prefixes

| Prefix | Meaning |
| --- | --- |
| `?` | Disabled by default. |
| `!` | Required entry; it remains selected when its module is enabled. |
| `# default: true` / `# default: false` | Explicitly sets initial selection. |
| `"Title" :` | Sets an explicit display title before the command. |

Examples:

```text
?> Microsoft.Edge
!> Ollama.Ollama
? "Qwen 3" : $> ollama pull 'qwen3:8b'
```

An explicit title takes precedence over a generated program or script name.

### Command operators

| Operator | Meaning |
| --- | --- |
| no operator | Install a package using the platform registry's package manager. |
| `$>` | Run a shell-style command or local script. This is required for every script, regardless of whether the script is PowerShell, Bash, or another platform shell. |
| `>` | Run an action using the platform agent's action handler. |

`PS>` is obsolete and must not be used in new or updated modules. Replace
`PS>` with `$>`; the script technology is inferred from the target operating
system and, for local files, from the file extension. A Windows `.ps1` file is
handled as PowerShell, while a macOS or Linux `.sh` file is handled as a shell
script. Do not encode the script technology in the GMR operator.

Local script paths are resolved relative to the module file unless absolute.
A referenced script must exist before execution and should remain alongside
the registry that invokes it.

## Package entries

An unadorned entry is interpreted as a package identifier. The Windows agent
uses the first token as the WinGet package ID and installs it with an exact ID
match by default:

```text
Git.Git
```

Windows package-selection prefixes are:

- `id` or `exact`: use an exact package ID match (the default).
- `name`: use the package name instead of the ID.
- `fuzzy`: allow a non-exact match.
- `winget` or `msstore`: select the package source.

Examples:

```text
exact id winget: Git.Git
name fuzzy: "Visual Studio Code"
msstore: 9NZVDKPMR9RD
```

Quoted package names must remain quoted when the platform parser tokenizes
the command.

## Script and command entries

Use a local script for multi-step installation or configuration:

```text
$> .\Installers\Install-Example.ps1
$> ./Installers/install-example.sh
```

The `$>` operator is mandatory in both examples. The script must be
executable from a terminal and own its complete application-specific
workflow. On Windows, `.ps1`, `.cmd`, and `.bat` files are interpreted using
Windows command conventions. On macOS and Linux, `.sh` files are interpreted
using the platform shell conventions.

Migration example:

```text
# Obsolete:
PS> .\Installers\Install-NodeJs.ps1

# Correct:
$> .\Installers\Install-NodeJs.ps1
```

The migration changes only the GMR operator. It must not change the script
path or the script's contents.

## Remote one-liner installers

Remote scripts use a recognizable download-and-run pattern. Do not store an
ambiguous `iex (irm ...)` expression when a URL can use the normalized form.

### Windows PowerShell scripts

For a `.ps1` URL, normalize the entry to:

```text
$> irm <url> | iex
```

For example, both `iex (irm https://hermes-agent.nousresearch.com/install.ps1)`
and the bare URL `https://herdr.dev/install.ps1` become:

```text
$> irm https://hermes-agent.nousresearch.com/install.ps1 | iex
$> irm https://herdr.dev/install.ps1 | iex
```

A URL entry is executable code, not a package declaration; review it before
execution.

### macOS shell scripts

For a `.sh` URL, normalize the entry to:

```text
$> curl -fsSL <url> | bash
```

Example:

```text
$> curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

The Mac agent must not execute a PowerShell `.ps1` installer, and the Windows
agent must not execute a shell `.sh` installer. Linux entries must use the
shell and package-manager conventions defined by the Linux registry.

## Existing module categories

The current Windows registry demonstrates these standard categories:

- Base
- Web Browsers
- Graphics & Media
- Power User
- Developer
- AI Tools
- Ollama LLM Models by GPU tier (`4G`, `6G`, and `8G`)
- Tweaks
- Post Install

Use an existing category when the program has the same installation purpose.
Create a new module only when no existing category is a good fit, with a
unique descriptive file name, display name, and sort index.

## Validation checklist

Before accepting a module change:

1. Confirm the file name, metadata, prefixes, quoting, and operator follow
   these rules.
2. Confirm every script entry uses `$>` and contains no obsolete `PS>`
   operator.
3. Confirm every local script path resolves from the module directory.
4. Confirm the command is valid for the target platform and registry.
5. Compare the module with nearby modules in the same category.
6. Run the platform parser in dry-run mode where available; it must show the
   intended action without making changes.
7. For GMR beta execution, test from an interactive terminal; parser-only
   validation does not prove menu execution.

The current `.gmr` files follow the documented metadata, selection, include,
package, local-script, and command-entry patterns. `DeveloperMode.gmrs` is a
legacy action descriptor and is not parsed by the GMR beta `.gmr` loader; it
must not be used as evidence that a `.gmr` rule has been validated.
