---
name: append
description: Add a program or script to one or more GetMeReady platform registries. Use when a request asks to append, add, or register software for macOS, Windows, Linux, or a selected combination of platforms.
---

# Append a program to GetMeReady

Use this skill to add one program or script to the Mac, Windows, and/or Linux
registry. Work from the GetMeReady repository root and preserve unrelated
registry content.

## 1. Determine the target platforms

Read the request and classify the target as one, several, or all platforms:

- macOS: `GetMyMacReady/`
- Windows: `GetMyWinReady/`
- Linux: `GetMyNixReady/`

If the target is not clear, ask before editing. Do not assume that a program
should be added to all platforms merely because it exists on more than one.
If the requested program is inherently platform-specific, explain that and
confirm the intended registry when needed.

## 2. Inspect the target registry

Before editing each selected registry:

1. Read its local `AGENTS.md`, if present.
2. Inspect its README and nearby `.gmr` modules.
3. Search for an existing entry, equivalent package, or related installer.
4. Identify the existing module category and its selection convention.

All registries share the GMR structure and naming rules, but commands,
paths, package managers, and scripts are platform-specific. Never copy a
Windows command into the Mac or Linux registry without adapting and checking
it for that platform.

## 3. Select the installation method

Choose the native method that best represents the requested software:

- Windows: prefer an authentic exact WinGet package ID.
- macOS: prefer an authentic Homebrew formula or cask.
- Linux: prefer the distribution/package-manager method defined by the Linux
  registry; if the target distribution is unclear, ask which distribution to
  support.
- Official vendor scripts or direct downloads are fallbacks when no suitable
  native package exists.

Search for the best matching package and verify the package identity, name,
publisher/owner, and source before editing. Do not silently choose a
lookalike package. If multiple matches remain plausible, show the choices and
ask the user.

For a remote installer, prefer the official maintainer URL. Treat the
downloaded script as executable code and inspect it before execution. Follow
the shared `RULES.md` normalization rules:

- Windows PowerShell URL: `$> irm <url> | iex`
- macOS/Linux shell URL: `$> curl -fsSL <url> | bash`

The `$>` operator is mandatory for scripts. Do not use the obsolete `PS>`
operator; script technology is inferred from the target operating system and
script extension.

## 4. Choose or create the module

Use an existing category when the program has the same purpose as its
entries. Infer the category from explicit user wording, then from similar
existing modules. If no category is suitable, create a new module with:

- a unique descriptive PascalCase file name;
- `# name: <display name>`;
- a suitable `# sortindex: <integer>`;
- one entry per program or application-specific workflow.

If the category or placement is genuinely ambiguous, ask rather than making
a speculative structural change.

## 5. Add the smallest correct entry

For a single package installation, add one package entry using the exact
native package identifier. Preserve the module's existing optional/default
selection style unless the user explicitly requests another behavior.

For a Windows entry, add the `^` UAC-elevation prefix when the request includes
the keyword `UAC` or `admin`. The prefix may be combined with `?`, `!`, a title,
and package-selection prefixes; for example, `? ^> Example.Package`. Do not
add `^` to macOS or Linux entries.

When the request uses a labeled instruction such as:

```text
"Herdr": "irm https://herdr.dev/install.ps1 | iex", brew install herdr
```

interpret the quoted label as an explicit display title and create
platform-specific entries with that title:

```text
"Herdr" $> irm https://herdr.dev/install.ps1 | iex
"Herdr" > herdr
```

The colon after the title is optional when the title is immediately followed
by a GMR operator. Keep the title identical across equivalent platform
entries; never include the title text in the executable command.

For a multi-step installation, create one application-specific script in the
target registry and add exactly one script entry:

```text
$> <script filename>
```

The script must run from a terminal, resolve paths from its own location, be
safe to rerun where practical, and fail clearly when a required step fails.
Use the platform's native script technology: PowerShell on Windows and Bash
or the registry's documented shell on macOS/Linux. Do not create a wrapper
when one exact package entry is sufficient.

When adding the same program to multiple registries, create platform-native
entries in each registry. A shared display name does not imply a shared
command or shared script file.

## 6. Verify the change

Before handing off:

1. Re-read every changed module and script.
2. Confirm the entry is in the intended registry and category.
3. Confirm package IDs and URLs identify the requested software.
4. Confirm every script entry uses `$>` and no new `PS>` entry was added.
5. Confirm local script paths resolve relative to their module.
6. Run the platform's parser or dry-run mode where available; do not execute
   live installation merely as a validation shortcut.
7. Run relevant tests and syntax checks for changed scripts.

Report anything that could not be verified, especially package identity,
publisher, URL ownership, hash/version, platform availability, or runtime
prerequisites. Do not commit unless the user separately requests a commit.
