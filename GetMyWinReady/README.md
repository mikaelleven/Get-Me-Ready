# GetMeReady

## Vad är GetMeReady?

GetMeReady (GMR) is a PowerShell-based bootstrapper for a new Windows computer. It collects the software, tools and follow-up actions you want, then performs the selected base installation with as little interaction as possible.

Package lists are installed through WinGet. Other actions—such as running a PowerShell script, a batch file, an executable, or opening a URL—are described in separate GMR files. This keeps a standard setup repeatable while still allowing machine-specific choices.

## Installation

### Online install

Run this in an interactive PowerShell session to download GMR to
`$HOME\GetMeReady` and start the installer:

```powershell
irm https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/GetMyWinReady/Install-GMR.ps1 | iex
```

The command downloads and executes remote code. Review
[Install-GMR.ps1](Install-GMR.ps1) before running it if you do not trust the
source. It refuses to overwrite an existing installation; download the script
locally to choose another path or use its `-Force` option.

Requirements:

- Windows PowerShell 5.1 or later
- [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) for `.gmr` package installations
- An interactive PowerShell session
- Administrator PowerShell only if you choose to create a restore point

Clone the repository and start it from its root:

```powershell
git clone https://github.com/w33zl/GetMeReady.git
Set-Location .\GetMeReady
```

If script execution is blocked on a newly installed computer, allow it only for the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Kom igång

### Primärt PowerShell-kommando

```powershell
.\GMR.ps1
```

GMR discovers all `.gmr` and `.gmrs` files beside `GMR.ps1`. It presents every group before it begins processing, asks whether to create a restore point, shows a summary, and asks for one final confirmation. Once confirmed, it processes the selected items without further GMR prompts. `GMR.ps1` is the current stable beta version.

Example of the standard menu:

```text
Found 3 setup descriptor(s) in D:\GetMeReady

Select package: Core
  [0] None
  [1] Core
  [2] Core (Lite)
Choose 0-2: 1

Select package: Developer mode
  [0] None
  [1] Developer mode
Choose 0-1: 1

Create a Windows system restore point before execution?
  [0] No
  [1] Yes
Choose 0-1: 1
```

`# cn:` groups alternatives under one menu choice. In the example, **Core** and **Core (Lite)** are mutually exclusive variants. Use `-Verbose` to display each group's entries in the menu.

### Återställningspunkt

Choose **Yes** when you want Windows to create a restore point before any selected package or action is processed. This requires an elevated PowerShell session; if creation fails, GMR aborts before making the selected changes.

You can skip the prompt explicitly:

```powershell
.\GMR.ps1 -CreateRestorePoint:$false
```

Or require a restore point (run PowerShell as Administrator):

```powershell
.\GMR.ps1 -CreateRestorePoint
```

### Anpassad installation

Preview the selected installation without making any changes:

```powershell
.\GMR.ps1 -DryRun
```

Show the contents of each selectable group:

```powershell
.\GMR.ps1 -Verbose
```

Select only the groups you need during the menu. Selecting `None` skips a group.

## Anpassning

Se [ProgramCatalog.md](ProgramCatalog.md) för en hierarkisk förteckning över alla program som kan installeras med GMR. Katalogen genereras deterministiskt från programnycklar och skriptvägar i deskriptorerna, med undantag i `tools\ProgramNameExceptions.json`, och ska uppdateras med `.\tools\Update-ProgramCatalog.ps1` när program läggs till, tas bort eller byter namn.

Kontrollera befintliga programnamn med `.\tools\Repair-ProgramNames.ps1`. Scriptet listar avvikelser som `auto` eller `manual`, frågar innan auto-förslag registreras och uppdaterar därefter katalogen. Använd `-ListOnly` för en läsanalys. Använd projektskillen `/find-name` när manuella namnförslag uttryckligen efterfrågas.

Keep your personal `.gmr` and `.gmrs` files beside `GMR.ps1`. They are automatically discovered the next time GMR starts. Give files clear names, for example `Workstation.gmr` or `MyTweaks.gmrs`.

### Lägg till egna rader

Use a `.gmr` file for WinGet packages—one package specification per line:

```text
# name: Development tools
# cn: Development

Microsoft.VisualStudioCode
"Flow Launcher"
Microsoft.PowerToys --source winget
Google.Chrome fuzzy
```

Use a `.gmrs` file for commands and post-install actions—one action per line:

```text
# name: My configuration

.\Configure-Explorer.ps1
profile.cmd --workstation
www.example.com
reg.exe add "HKCU\Software\Example" /v Enabled /t REG_DWORD /d 1 /f
```

Relative paths resolve from the descriptor file's directory. Quote paths that contain spaces. Review any command before running it: `.gmrs` entries are executable actions, not merely configuration data.

### Helper scripts

Download a resource and expand environment-variable paths such as `%APPDATA%`:

```powershell
.\tools\Get-UrlResource.ps1 'https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/onehalf.minimal.omp.json' '%APPDATA%\oh-my-posh\onehalf.minimal.omp.json'
```

Download an Oh My Posh theme to its theme directory. Add `-Activate` to persist the theme in the current PowerShell profile; open a new terminal afterwards.

```powershell
.\tools\Install-OhMyPoshTheme.ps1 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/patriksvensson.omp.json' -Activate
```

Append a text block to a file (the file and parent directory are created when needed):

```powershell
.\tools\Add-TextBlock.ps1 '.\notes.txt' 'A new line'
```

For JSON, `-Inject` takes a slash-separated path. Array indexes are one-based:

```powershell
.\tools\Add-TextBlock.ps1 '.\settings.json' -Inject '/schemas[1]/myitem' '{"title":"Abc123","index":11}'
```

For XML, the path identifies the parent and new final element; the text block is its XML content:

```powershell
.\tools\Add-TextBlock.ps1 '.\settings.xml' -Inject '/schemas[1]/myitem' '<value>Abc123</value>'
```

### GMR-syntax

| Syntax | Meaning |
| --- | --- |
| `# name: Friendly name` | Replaces the filename in the menu. |
| `# cn: Group name` | Makes files with the same canonical name mutually exclusive variants. |
| `# include: Other.gmr` | Includes another `.gmr` file. Relative paths resolve from the including file. Includes may be nested; circular includes are rejected. |
| `# comment` or blank line | Ignored. |
| `# required: true` | In the beta interface, marks the next entry as required while its module is selected. |
| `.gmr` entry | One command per line: `[{prefix}[>]] {command}`. Without `>` it is a standard WinGet command. `?` starts disabled, `!` is required, `^` requires UAC elevation, and `"title" :` replaces the generated title. |
| WinGet prefixes | `fuzzy` or `exact` controls `--exact` (default: `exact`); `id` or `name` selects the package field (a quoted command implies `name`); `winget` or `msstore` selects `--source`. |
| PowerShell `.gmr` entry | `$> command` runs a PowerShell command or `.ps1` file. `PS>` is accepted for existing descriptors but obsolete. |
| `.gmrs` entry | A PowerShell one-liner, `.ps1`, `.cmd`, `.bat`, `.exe`, or `https://`/`www.` URL. |

`# include:` is valid only in `.gmr` files. The repository's [Examples.gmrs.example](Examples.gmrs.example) contains additional `.gmrs` examples.

For example, `?> Microsoft.Edge`, `!> Vivaldi.Vivaldi`, `^> Microsoft.Sysinternals`, `"Write Hello" : $> Write-Host 'Hello'`, and `fuzzy name msstore> "Google Chrome"` are valid `.gmr` entries. When at least one selected entry has `^`, GMR requests UAC elevation once and runs all selected installations in that elevated process.

## Vidareutveckling

The current stable beta entry point is [GMR.ps1](GMR.ps1). Keep changes compatible with Windows PowerShell 5.1, add or update descriptors to cover new setup behavior, and use a dry run before executing a changed configuration:

```powershell
.\GMR.ps1 -DryRun -Verbose
```

Validate PowerShell syntax after code changes:

```powershell
$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path .\GMR.ps1), [ref]$tokens, [ref]$errors)
$errors
```

`GMR-legacy.ps1` is obsolete and retained for reference only. The current stable beta implementation is `GMR.ps1`; its Pester tests are located in [tests/GMR-Beta.Tests.ps1](tests/GMR-Beta.Tests.ps1).

## FAQ och felsökning

**GMR says `winget.exe was not found`.** Install or update App Installer/WinGet, restart PowerShell, and run the command again.

**PowerShell blocks the script.** Use the process-scoped `Set-ExecutionPolicy` command shown above, or follow your organisation's execution-policy rules.

**Restore point creation fails.** Start PowerShell as Administrator, verify that System Protection is enabled for the system drive, then retry. GMR intentionally stops before package installation if the requested restore point cannot be created.

**A `.gmrs` action cannot find a file.** Check the path. Relative `.ps1`, `.cmd`, `.bat` and `.exe` paths are resolved from the descriptor's folder.

**I cannot use the menu through a pipe or automation host.** Run `GMR.ps1` in an interactive PowerShell console. Use `-DryRun` to inspect the actions safely before execution.

**Why is an expected group missing?** Ensure that its file ends in `.gmr` or `.gmrs` and is placed beside `GMR.ps1`; files with other extensions are ignored.

## Licens

GetMeReady is licensed under the [MIT License](LICENSE).

---

Created by Mikael Levén · GetMeReady v0.8 · Copyright © 2026 Mikael Levén
