# GetMeReady TUI implementation specification

Status: implementation specification for the macOS and Linux TUI ports.

This document specifies the observable behavior of the Windows TUI in
`GetMyWinReady/GMR-beta.ps1`. The macOS and Linux implementations MUST expose
the same menus, key behavior, state transitions, ordering, labels, dry-run
flow, error behavior, and `.gmr` interpretation. Only the platform execution
adapter is allowed to change how a package or shell command is executed.

The words **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

## 1. Source of truth and scope

The implementation was reverse-engineered from these project-local sources:

- `GetMyWinReady/GMR-beta.ps1` and `GetMyWinReady/tests/GMR-Beta.Tests.ps1`;
- `GetMyWinReady/external/ConsoleTUI/README.md`;
- `GetMyWinReady/external/ConsoleTUI/src/ConsoleTui/ConsoleTui.psm1` and its tests;
- the root `RULES.md`;
- `GetMyWinReady/README.md`, `GetMyMacReady/README.md`, and
  `GetMyNixReady/README.md`.

The Windows stable launcher, `GetMyWinReady/GMR.ps1`, is useful for legacy
behavior and execution terminology but is not the TUI contract. Where the
stable launcher, `RULES.md`, and the beta implementation differ, this document
records the current beta behavior so that all TUI ports remain interoperable.

### 1.1 In scope

- A keyboard-driven, interactive TUI for selecting modules and entries.
- Discovery, parsing, display-name generation, and selection of `.gmr` files.
- Nested module menus, execution options, confirmation dialogs, and dry-run.
- Platform-specific package and shell-command execution.
- Console layout, navigation, restoration, and failure behavior.

### 1.2 Out of scope

- The legacy `.gmrs` execution model.
- Canonical-name (`# cn:`) variant grouping in the TUI.
- Configuration persistence. The visible `Save configuration` item remains a
  deliberate no-op until a separate feature is specified.
- A new GMR syntax or a platform-specific parser fork.

The TUI discovers `.gmr` files only. `.gmrs` files are not displayed and MUST
NOT be executed by the TUI, even though the stable launcher supports them.

## 2. Design goals

The port is one application with a common domain model and UI state machine,
plus a small platform adapter:

```text
registry directory
        |
        v
descriptor discovery -> common .gmr parser -> module/entry model
                                                     |
                                                     v
                                      common selection state machine
                                                     |
                         +---------------------------+--------------------+
                         |                                                |
                         v                                                v
                 common TUI renderer                              execution plan
                                                                          |
                                                                          v
                                                        platform execution adapter
```

The parser and selection model MUST NOT know whether the target is Windows,
macOS, or Linux. The adapter is responsible for:

- the package manager command and its arguments;
- the shell used for `$>` commands;
- native local-script invocation;
- platform capability checks such as a recovery checkpoint.

The TUI MAY be implemented in different host languages or terminal libraries
on each platform. The observable contract below remains fixed.

## 3. Runtime and application boundaries

### 3.1 Launcher root

Each platform launcher determines its own registry directory from the launcher
location, not from the caller's current directory. Descriptor paths are
resolved relative to the descriptor that contains the entry.

The launcher MUST:

1. determine the registry directory;
2. reject redirected input or output;
3. discover `.gmr` files directly in that directory;
4. parse all descriptors before showing the main menu;
5. build the menus without executing any command;
6. execute only after the user confirms the final action.

The TUI requires a real interactive terminal with direct keyboard input and
output. A pipe, redirected stdin, or redirected stdout MUST produce a clear
error before the menu is rendered.

### 3.2 No execution during parsing or selection

Parsing, display-name generation, menu construction, Space toggles, and menu
navigation MUST have no installation side effects. In particular, a package
manager MUST NOT be queried merely to create a label.

The only external operations before final confirmation are file reads and
platform capability validation that is required to construct a safe execution
plan.

## 4. Common domain model

The concrete representation may be language-specific. The following logical
properties are required.

### 4.1 Entry

Each parsed entry contains:

| Property | Meaning |
| --- | --- |
| `RawLine` | Original non-comment line, retained for diagnostics. |
| `Command` | Command text after the operator/title prefix. |
| `Operator` | `None`, `>`, `$>`, or legacy `PS>`. |
| `Kind` | `Package` or `ShellCommand`. |
| `Title` | Explicit title, or empty. |
| `DisplayName` | Text shown in the module menu. |
| `DefaultEnabled` | Initial selection when the module is enabled. |
| `Mandatory` | Whether the entry cannot be deselected. |
| `PackageSelector` | `id` or `name`; defaults as described below. |
| `PackageSource` | `winget` or `msstore` in the Windows grammar; `winget` by default. |
| `PackageExact` | Exact matching is true by default. |
| `Enabled` | Runtime selection state. |
| `ResolvedPath` | Absolute local path when the command is a local script. |
| `Arguments` | Parsed arguments for a recognized local script. |

`PackageSource`, `PackageSelector`, and `PackageExact` are retained by the
common parser even when a non-Windows adapter cannot apply them directly.

### 4.2 Module

Each discovered `.gmr` file becomes one module containing:

| Property | Meaning |
| --- | --- |
| `FilePath` | Absolute descriptor path. |
| `FileName` | Descriptor file name. |
| `DisplayName` | `# name:` value, otherwise the file name including `.gmr`. |
| `SortIndex` | `# sortindex:` value, otherwise the maximum integer. |
| `Required` | Module-level `# required:` value; false by default. |
| `Selected` | Module-level `# selected:` value; false by default. |
| `Entries` | Parsed entries, including recursively included entries. |
| `Enabled` | Runtime module state. |
| `MenuItem` | Reference to the main-menu item, if the UI toolkit needs one. |
| `Menu` | Reference to the module submenu. |

`# cn:` is not used by the current TUI. Two files with the same `# cn:` value
remain two independent modules. Do not add variant grouping to a macOS/Linux
port unless the Windows beta and its tests are changed first.

## 5. Descriptor discovery and ordering

1. List regular files directly beside the platform launcher.
2. Keep only files whose extension is `.gmr`, case-insensitively.
3. Parse every file before displaying the main menu.
4. Sort modules by ascending `SortIndex`.
5. Break equal sort indexes by ascending descriptor file name.

Discovery is not recursive. Included files are parsed as entry sources, not as
additional top-level modules.

An empty registry produces a warning and exits without rendering an empty
menu. A descriptor parse error aborts startup and MUST identify the descriptor
and, where possible, the offending line.

## 6. Common `.gmr` parser

### 6.1 Encoding and line handling

Descriptors SHOULD be written as UTF-8, with or without a BOM. The parser MUST
preserve Unicode text in titles, commands, and diagnostics. It MUST process the
file line by line and trim surrounding whitespace before interpreting a line.

Blank lines and lines whose first non-whitespace character is `#` are ignored,
except for the recognized metadata forms below.

Boolean metadata accepts `true`, `false`, `yes`, and `no`, case-insensitively.

### 6.2 Module metadata

The following metadata is recognized while reading a top-level descriptor:

```text
# name: Developer tools
# sortindex: 130
# required: true
# selected: true
```

- `# name:` replaces the module display name.
- `# sortindex:` controls module ordering.
- `# required: true` makes the module permanently enabled.
- `# selected: true` initially enables the module using its default and
  mandatory entries.

If a recognized module metadata key appears more than once, the last valid
value is used, matching the current beta implementation.

Unknown metadata is ignored as a comment. `# cn:` therefore has no effect in
the TUI.

### 6.3 Includes

```text
# include: Other.gmr
```

Include rules:

- The include is valid only in a `.gmr` descriptor.
- Environment variables in the include path are expanded by the platform.
- A relative include path is resolved relative to the including file.
- An absolute include path is used as written after expansion.
- The included file MUST exist and have the `.gmr` extension.
- Included entries are inserted at the position of the include directive.
- Includes may be nested.
- A circular include MUST be rejected with the complete include chain.
- Metadata in the included file does not create another module; its entry
  lines are imported into the parent module.

An include is expanded before entry selection and before display names are
generated. Local command paths from included entries are resolved against the
top-level descriptor currently being displayed. This matches the current
Windows beta, whose normalized entry records do not retain the included file as
a separate path context.

### 6.4 Entry defaults and requirement metadata

The following forms set entry selection state:

```text
# default: false
Some.Package

Some.Other.Package # default: no

!> Required.Package
?> Optional.By.Default
```

`# default:` on its own applies to the next entry. The inline form applies to
the same entry and wins over the pending default. After an entry is parsed,
the pending default returns to `true`.

- Default enabled is true unless explicitly set to false.
- `?` sets default enabled to false.
- `!` sets `Mandatory` to true and makes the entry impossible to turn off.
- A mandatory entry is enabled whenever its module is enabled, regardless of
  its default value.

No generic inline-comment syntax is supported. The only inline suffix with
special meaning is the exact `# default: true|false|yes|no` form.

### 6.5 Operators and entry kinds

The current Windows TUI interprets entries as follows:

| Form | Common kind | Windows meaning |
| --- | --- | --- |
| `Package.Id` | `Package` | WinGet package entry. |
| `> Package.Id` | `Package` | WinGet package entry. |
| `$> command` | `ShellCommand` | PowerShell command or local PowerShell script. |
| `PS> command` | `ShellCommand` | Legacy alias for `$>`; accepted for compatibility. |

The `PS>` spelling is obsolete for new files, but the TUI parser MUST accept it
so existing Windows descriptors continue to work. New cross-platform files
SHOULD use `$>` and let the target platform determine the shell technology.

The `>` operator is a package operator in the TUI contract. It is not a
second, arbitrary-action type. This is important because the stable launcher
and the broader shared rules also describe legacy action forms differently.

Examples:

```text
Git.Git
> Git.Git
"Git" : > git
$> ./Installers/install-tool.sh
"Install tool" : $> curl -fsSL https://example.invalid/install.sh | bash
```

### 6.6 Titles and prefixes

An explicit quoted title is metadata for display only. It MUST never become
part of the executed command.

Accepted title forms include:

```text
"Google Chrome" : Chrome
? : "Google Chrome" > Chrome
"Install Ollama" : $> ollama pull qwen3:8b
```

The colon is optional when the title is immediately followed by an operator.
Text before the operator is parsed as title/prefix metadata; text after the
operator is the command.

When an entry has no operator, the first colon outside quotes is treated as a
title separator. Therefore a bare package/reference containing a colon MUST
be quoted or use the explicit `>` package operator. For example, use
`> qwen3:8b` or `"qwen3:8b"`, not a bare `qwen3:8b` line.

The parser accepts these case-insensitive package prefixes:

| Prefix | Effect |
| --- | --- |
| `?` | Default disabled. |
| `!` | Mandatory. |
| `fuzzy` | Disable exact package matching. |
| `exact` | Enable exact package matching. |
| `id` | Select package ID. |
| `name` | Select package name. |
| `winget` | Use the `winget` package source. |
| `msstore` | Use the `msstore` package source. |

Unknown prefixes MUST produce a parse error. The last occurrence of a
repeated selector, source, or match-mode prefix wins.

The default package selector is `id`. If the command begins with a quoted
token, the selector defaults to `name`; an explicit `id` or `name` prefix
overrides that inference.

### 6.7 Tokenization

The Windows parser uses a small command-line tokenizer for package metadata,
prefixes, and recognized local-script arguments:

- whitespace separates tokens outside quotes;
- single and double quotes group text and are removed from the resulting token;
- an unterminated quote is an error;
- no shell expansion is performed during tokenization;
- the command text for `$>` remains command text and is interpreted only by the
  platform shell executor.

The package specification uses the first token as the package reference. The
current beta implementation does not forward additional package tokens as
custom package-manager arguments. Ports MUST preserve this behavior for TUI
parity; platform-specific package options belong in an explicit `$>` command.

### 6.8 Display-name generation

Display-name precedence is:

1. explicit quoted title;
2. a platform registry's shared program-name exception;
3. deterministic generated name.

For a package, the generated name is based on the package reference. If it has
two dot-separated components, the second component is used unless both
components are equal ignoring case. Hyphens become spaces.

For a local script, use the file name without its extension, then replace
hyphens and underscores with spaces. A shared exception table MAY provide a
human-friendly override, but the same exception key and result MUST be used
on every platform.

For an arbitrary shell/PowerShell command, use the command text as the display
name. Display-name generation MUST NOT execute the command.

## 7. Selection model and state transitions

### 7.1 Initial state

Every entry starts with `Enabled = false`.

If a module has `Selected = true` or `Required = true`, initialize it as
enabled using:

```text
entry.Enabled = module.Enabled AND (entry.DefaultEnabled OR entry.Mandatory)
```

For an ordinary module with neither flag, even entries whose default is true
remain disabled until the module is selected in the main menu.

`Required = true` is stronger than any user toggle: the module remains enabled
and mandatory entries remain enabled.

### 7.2 Module labels

For a module with `n` entries and `k` selected entries:

| State | Indicator |
| --- | --- |
| `k = 0` and module is not required | `[ ]` |
| `0 < k < n` | `[*]` |
| `k = n` | `[x]` |

The main-menu label is:

```text
[indicator] DisplayName [k/n][ required suffix when applicable]
```

The required suffix is exactly ` [required]`.

### 7.3 Entry labels

The module-menu label is:

```text
[x] DisplayName
[ ] DisplayName
```

Mandatory entries append exactly ` [required]`. A mandatory entry is always
shown checked and its Space action MUST have no effect.

### 7.4 Space on a main-menu module

Space cycles the module using the current selection count:

1. If the module is required, or no entry is currently selected, select every
   default-enabled and mandatory entry.
2. Otherwise, if the module is partially selected, select every entry.
3. Otherwise, deselect every non-mandatory entry; mandatory entries remain
   selected.

After each transition, update every entry label, the module label, and the
   runtime `Enabled` property. Set the global `SelectionTouched` flag.

For an ordinary module this produces the tested cycle:

```text
None -> default selection -> all -> none
```

### 7.5 Space on a module entry

Space toggles the selected entry unless it is mandatory. When the first entry
is manually enabled in an otherwise empty module, all mandatory entries are
also enabled. Mandatory entries are reasserted after every toggle.

The module becomes enabled when it has at least one selected entry, or when it
is required. Labels and the global `SelectionTouched` flag are updated.

### 7.6 Execution-option selection

The execution menu starts with `Create restore point` enabled. Space toggles
it and updates the label between:

```text
[x] Create restore point
[ ] Create restore point
```

Space also sets `SelectionTouched`. `Save configuration (not implemented)` is
visible but has no effect. The initial selected item is
`Save configuration (not implemented)`, not the restore-point item.

## 8. TUI menus and visible behavior

### 8.1 Main menu

The main menu contains, in this order:

1. one child-menu item for each module in sorted order;
2. `Continue`;
3. `Quit`.

Main menu properties:

```text
Title:       GetMeReady (beta)
TitleDetail:  - Created by Mikael Levén
Toolbar:     Up/Down Select  Left/Right Column  Space Toggle  Enter Open  Esc Quit
```

Space toggles the selected module. Enter opens its child menu. Enter on
`Continue` closes the menu with action result `Continue`. Enter on `Quit`
closes it with action result `Quit`.

### 8.2 Module menu

Each module has a child menu with:

1. `(Back)` as the first item;
2. one action item for every parsed entry, in file/include order.

Properties:

```text
Title:   module DisplayName
Toolbar: Up/Down Select  Left/Right Column  Space Toggle  Backspace Back
```

Enter on `(Back)` returns to the parent. Enter on an entry performs the item
action, which is intentionally an empty action in the selection UI; entry
selection happens with Space.

Returning from a child menu MUST restore the parent's previous selected item.
Reopening a module MUST restore that module menu's previous selected item as
well.

### 8.3 Execution menu

The execution menu contains:

1. `[x] Create restore point`;
2. `Save configuration (not implemented)`;
3. `Proceed (dry-run)`;
4. `Proceed`;
5. `Quit`.

Properties:

```text
Title:              Execution options
Initial selection:  Save configuration (not implemented)
Toolbar:            Up/Down Select  Space Toggle  Enter Select  Esc Quit
```

`Proceed (dry-run)` and `Proceed` close the menu and require a confirmation
dialog. A negative confirmation returns to the execution menu.

### 8.4 Layout and capacity

The GMR menu layout is calculated from the item count:

```text
if itemCount > 48: error
columnCount = max(1, min(4, ceil(itemCount / 12)))
rowsPerColumn = ceil(itemCount / columnCount)
```

Examples:

| Items | Columns | Rows per column |
| ---: | ---: | ---: |
| 1 | 1 | 1 |
| 12 | 1 | 12 |
| 13 | 2 | 7 |
| 25 | 3 | 9 |
| 48 | 4 | 12 |

The underlying TUI renderer MUST reject an empty menu, duplicate item IDs,
invalid item types, and item counts greater than the configured capacity.

Items fill by column, not by row. With seven rows, indexes `0..6` are in the
first column, `7..13` in the second, and so on. Prefix numbers, when enabled,
use this global item order.

### 8.5 Keyboard navigation

| Key | Required behavior |
| --- | --- |
| Up | Previous item in the current column; wraps. |
| Down | Next item in the current column; wraps. |
| Left | Same row in the previous populated column; wraps and clamps. |
| Right | Same row in the next populated column; wraps and clamps. |
| Home | First item in the first column. |
| End | Last item in the last populated column. |
| Page Up | First item in the current column. |
| Page Down | Last item in the current column. |
| Enter | Run an action, open a child menu, or activate GoBack. |
| Space | Run the optional item Space action and redraw. |
| Backspace | Return from a child menu; no effect at root. |
| Escape | Return from a child menu, or close the root menu. |

Horizontal navigation preserves the row where possible. When the target column
is shorter, select its last item. Empty trailing configured columns remain in
the layout but are skipped by navigation.

### 8.6 Confirmation dialog

The common confirmation dialog has two choices, Yes and No. The default choice
is No. Left, Right, and Tab toggle the choice. `Y` returns true, `N` and
Escape return false, and Enter returns the current choice.

It is used in two places:

- abort: `Abort?` / `Abort without running the selected commands?`;
- execution: `Proceed?` with either `Run the selected commands in dry-run mode?`
  or `Run the selected commands now?`.

An abort confirmation is shown when `SelectionTouched` is true or at least one
module is enabled. This means a descriptor with `# selected: true` can require
confirmation even when the user has not pressed Space.

### 8.7 Rendering contract

The renderer MUST provide the behavior already supplied by ConsoleTUI:

- hide the cursor while the TUI is active;
- use Unicode box drawing by default and support an ASCII fallback;
- use a centralized theme with active/inactive item, border, title, toolbar,
  and dialog styles;
- render by column and recalculate after a terminal resize;
- redraw only changed selection cells when possible;
- fully redraw after a Space action, submenu change, or resize;
- wrap toolbar text at word boundaries where possible;
- truncate long unbreakable text with `…`, or `...` in ASCII mode;
- reserve the terminal's rightmost column to prevent automatic wrapping from
  corrupting the frame;
- fail clearly when the terminal is too narrow or too short;
- clear the rendered area before returning or propagating an error.

Every public interactive operation MUST snapshot and restore cursor position,
cursor visibility, foreground color, background color, and terminal styling.
An action that writes temporary output is allowed; the TUI redraws the page
after the action completes.

The default theme is a black background with cyan accent. The default style
roles and their semantic purpose MUST match the ConsoleTUI theme. Exact RGB
styling is optional when the terminal cannot support it, but the fallback must
remain readable.

GMR menus use no numeric or bullet item prefixes. They use the renderer's
default active selection marker (`▶` in Unicode mode), no header, and no
footer. These are GMR menu choices, not generic ConsoleTUI defaults that a
platform port may change independently.

## 9. Application flow

```text
Start
  |
  +-- discover .gmr files
  |
  +-- parse modules and initialize defaults
  |
  +-- show main menu
  |      |
  |      +-- Space: change module selection
  |      +-- Enter: open module
  |      +-- Continue: leave main menu
  |      +-- Quit/Escape: optional abort confirmation, then exit
  |
  +-- show execution options
  |      |
  |      +-- Space: toggle checkpoint request
  |      +-- Proceed: confirmation dialog
  |      +-- negative confirmation: remain in execution menu
  |      +-- Quit/Escape: optional abort confirmation, then exit
  |
  +-- build selected-entry list
  |
  +-- optional recovery checkpoint
  |
  +-- dry-run or execute entries in module/entry order
  |
  +-- report aggregate success/failure
  |
 End
```

The main menu is shown until `Continue` is selected or the user exits. The
execution menu is shown until `Proceed`/`Proceed (dry-run)` is confirmed or the
user exits.

No further GMR selection prompt is allowed after the final confirmation. Once
execution starts, all selected entries are processed without additional TUI
selection questions.

## 10. Execution plan and result handling

The selected-entry list is flattened in this exact order:

1. enabled modules in module sort order;
2. enabled entries in each module's file/include order.

If the list is empty, print a warning equivalent to `Nothing was selected to
run.` and exit without invoking a package manager, shell, or checkpoint
provider.

### 10.1 Dry-run

Dry-run follows the same selection, checkpoint, validation, and ordering path
as normal execution, but MUST NOT change the machine. It reports the command
that would be run and records each item as a successful preview with no exit
code.

The final report is equivalent to:

```text
Dry run complete: N item(s) would be processed.
```

The checkpoint is described but not created during dry-run.

### 10.2 Normal execution

The checkpoint provider runs first when requested. If checkpoint creation
fails, the launcher reports the error and aborts before invoking any selected
package or shell command.

Each selected package or shell command is then processed independently:

- a failure is recorded and displayed;
- processing continues with the next entry;
- the final report contains succeeded and failed counts;
- failed entries include their type, display item, and exit code when one is
  available.

Unexpected parser, layout, or TUI errors MUST propagate after console state is
restored. Entry execution errors SHOULD be caught at the entry boundary so
one failed item does not hide later results.

## 11. Platform execution adapters

The following section is the only intentional execution difference between
the three TUI versions. The common parser still produces the same `Package`
and `ShellCommand` records.

### 11.1 Adapter interface

The platform adapter SHOULD expose these operations:

```text
ValidatePackage(entry) -> validation result
PreviewPackage(entry) -> displayable command
RunPackage(entry) -> result with exit code
PreviewShell(entry) -> displayable command
RunShell(entry) -> result with exit code
CreateCheckpoint() -> result
```

The adapter MUST use argument arrays for standard package commands where the
platform API permits it. Shell commands explicitly written after `$>` are
trusted executable input from the descriptor and may require shell parsing for
pipelines, redirects, quoting, and command chaining.

### 11.2 Windows

For a package entry, construct the current beta WinGet command:

```text
winget install
  --id <package>       # or --name when selected
  [--exact]             # default; omitted for fuzzy
  --source <source>
  --silent
  --accept-package-agreements
  --accept-source-agreements
  --disable-interactivity
```

`msstore` and `winget` select the source. `-Verbose` adds `--verbose` to the
WinGet command and affects only execution/preview verbosity; it does not alter
selection.

For `$>` and legacy `PS>`:

- a local `.ps1` path is resolved relative to the descriptor and invoked with
  PowerShell plus its parsed arguments;
- an arbitrary command is executed as PowerShell command text;
- a local script MUST exist before it is invoked;
- a non-native `.sh` script MUST be rejected as a platform mismatch.

The current beta recognizes `.cmd`, `.bat`, and `.exe` while parsing some
command forms, but those are not executable as `.gmr` PowerShell entries in
the beta path. Ports MUST NOT silently expand that behavior.

When requested, Windows creates a system restore point through
`Checkpoint-Computer` and requires an elevated PowerShell session.

### 11.3 macOS

The shell for `$>` entries is Bash, as required by the macOS registry
documentation:

- a local `.sh` path is resolved relative to the descriptor and run through
  Bash with its parsed arguments;
- arbitrary `$>` text is run by Bash so pipes, redirects, and shell operators
  have their normal meaning;
- a local `.ps1` file is a platform mismatch and MUST fail clearly;
- a script path MUST be checked before execution.

For a standard package entry (`Package.Id` or `> Package.Id`), the default
package command is:

```text
brew install <package>
```

Homebrew casks and other special forms MUST be expressed as an explicit `$>`
command, for example:

```text
"Visual Studio Code" : $> brew install --cask visual-studio-code
```

The adapter uses the package token, not the display title, as the Homebrew
argument. `id` and `name` both identify that token. Windows-only sources
(`winget` and `msstore`) MUST be rejected with a platform-specific diagnostic.
`exact` is naturally satisfied by passing the package token to Homebrew;
`fuzzy` has no implicit Homebrew equivalent and MUST be rejected rather than
silently changing the requested match mode.

The repository does not currently define a macOS native restore-point
provider. The adapter MUST NOT claim that a Windows restore point was created.
It must either provide a documented native checkpoint implementation or fail
the requested checkpoint before package/script execution.

### 11.4 Linux

The shell for `$>` entries is Bash, as required by the Linux registry
documentation:

- a local `.sh` path is resolved relative to the descriptor and run through
  Bash with its parsed arguments;
- arbitrary `$>` text is run by Bash;
- a local `.ps1` file is a platform mismatch and MUST fail clearly;
- a script path MUST be checked before execution.

Linux has no single package manager shared by all supported distributions.
The package command therefore belongs to the Linux adapter configuration, not
to the common parser. For example, an adapter may configure one of these
templates:

```text
apt-get install -y <package>
dnf install -y <package>
pacman -S --noconfirm <package>
zypper --non-interactive install <package>
```

The selected distribution/package-manager template MUST be explicit and
reported in dry-run output. The adapter MUST fail clearly when no supported
package manager is configured or detected; it MUST NOT guess silently based
on a package name.

`id` and `name` both identify the package token. `exact` is represented by
passing that token to the package manager. `fuzzy`, `winget`, and `msstore`
have no portable Linux meaning and MUST be rejected unless the configured
adapter explicitly documents support for them.

The repository does not currently define a Linux native restore-point
provider. The same rule as macOS applies: never report a Windows restore point;
use a documented native provider or fail before executing selected entries.

### 11.5 Environment and working directory

Relative local paths are always resolved against the descriptor directory and
then passed as absolute paths to the executor. The launcher MUST NOT depend on
the caller's current directory for finding a local script.

Windows descriptors may use Windows environment-variable expansion. macOS and
Linux descriptors MAY use the platform's environment-variable syntax. Shell
expansion inside arbitrary `$>` text is performed by the target shell, not by
the GMR parser.

Unless an adapter explicitly documents otherwise, command execution preserves
the launcher's working directory; resolving a local script does not silently
change it.

## 12. Failure and security requirements

Descriptor entries are executable input. The implementation MUST:

- show the selected commands in dry-run mode before execution;
- never use a package display title as an executable command;
- validate local script existence before invocation;
- keep local script resolution tied to the descriptor file;
- avoid command-string interpolation for standard package-manager arguments;
- report unsupported platform syntax instead of silently substituting a
  different command;
- avoid logging secrets that happen to occur in command text;
- preserve console state in a `finally`/defer-style cleanup path;
- not swallow parser, layout, or console errors.

Shell commands, remote installer pipelines, and local scripts are intentionally
executable. They MUST be treated as code supplied by the descriptor author and
must not be presented as harmless package metadata.

## 13. Verification strategy

Every port must have automated tests for the common layer and adapter tests for
its platform.

### 13.1 Common parser golden tests

Use shared fixture files and compare normalized parsed records across Windows,
macOS, and Linux. Cover:

- module names, sorting, selected/required metadata;
- default metadata before and after entries;
- inline default metadata;
- nested includes and include ordering;
- missing includes and circular includes;
- quoted titles and quoted package names;
- `?`, `!`, `fuzzy`, `exact`, `id`, `name`, `winget`, and `msstore`;
- `$>`, `PS>`, `>`, and no operator;
- unterminated quotes and unknown prefixes;
- Unicode titles and commands;
- deterministic display-name fallback and exceptions;
- `.gmrs` exclusion from TUI discovery;
- `# cn:` remaining non-functional in the TUI.

### 13.2 Selection-model tests

Mirror the existing `GMR-Beta.Tests.ps1` cases:

- layout sizes and the 48-item maximum;
- default/selected/required initialization;
- required entries cannot be deselected;
- module Space cycle: selective, all, none;
- first manual entry selection also selects mandatory entries;
- exact module and entry labels;
- main-menu placement of Continue and Quit;
- execution-menu order and initial selection;
- restore-point toggle state;
- title and title-detail values.

### 13.3 TUI engine tests

Test the reusable renderer independently of GMR:

- column-first coordinates;
- vertical and horizontal wrapping/clamping;
- Home, End, Page Up, and Page Down;
- submenu stack and selection restoration;
- action redraw;
- terminal resize recalculation;
- toolbar wrapping;
- ASCII fallback;
- too-narrow and too-short terminal errors;
- confirmation key behavior;
- console-state restoration after success and failure.

### 13.4 Adapter tests

Use fake package-manager and shell executables. No adapter test may install real
software by default. Verify:

- exact dry-run command and argument order;
- local path resolution from a descriptor directory containing spaces;
- script arguments and exit-code propagation;
- continuation after one entry fails;
- checkpoint failure prevents all package/script execution;
- unsupported platform prefixes fail before execution;
- no-op `Save configuration` behavior;
- empty selection does not invoke an executor.

### 13.5 Interactive acceptance test

Run each platform TUI in a real terminal and verify:

1. module order and initial labels;
2. Space toggles and updates counts immediately;
3. Enter opens a module and Backspace/Escape returns;
4. returning to a module restores selection;
5. Continue opens execution options;
6. negative proceed confirmation returns to the execution menu;
7. dry-run prints commands without changing the machine;
8. root Quit/Escape asks for abort confirmation when required;
9. resize recalculates the layout;
10. a failed entry does not prevent later entries from running;
11. the terminal cursor, colors, and prompt are restored after exit.

## 14. Implementation sequence

1. Implement the common `.gmr` parser and normalized domain model.
2. Add shared display-name and selection-state logic.
3. Implement the renderer/input engine and verify it with non-GMR menus.
4. Build the main, module, and execution menus from the shared model.
5. Add the macOS adapter (`brew`, Bash, and checkpoint capability).
6. Add the Linux adapter (configured package manager, Bash, and checkpoint
   capability).
7. Add dry-run/result reporting and failure boundaries.
8. Run shared golden tests on all platforms.
9. Run real-terminal acceptance tests for each adapter.

Do not copy the Windows PowerShell parser and then patch regular expressions
per platform. Implement one grammar and prove parity with shared fixtures.

## 15. Explicit unresolved platform decision

The current Windows TUI has a `Create restore point` option backed by Windows
System Restore. The repository does not yet specify an equivalent macOS or
Linux recovery mechanism. This is not a reason to change the common menu or
parser, but it is a required adapter decision before enabling normal execution
on those platforms:

- implement a documented native checkpoint provider; or
- mark the capability unavailable and block a requested checkpoint before any
  package/script execution.

A macOS/Linux adapter MUST NOT silently treat a requested checkpoint as a
successful no-op.
