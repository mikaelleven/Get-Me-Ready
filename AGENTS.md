# GetMeReady agent instructions

GetMeReady is organized around three platform agents. Each agent owns one
platform registry and is responsible for interpreting and applying the shared
GMR module format on that platform.

## Platform agents and registries

| Agent | Registry | Supported platform |
| --- | --- | --- |
| GetMyMacReady | `GetMyMacReady/` | macOS |
| GetMyWinReady | `GetMyWinReady/` | Windows |
| GetMyNixReady | `GetMyNixReady/` | Linux |

The registries are platform-specific. A registry must only be executed by
the platform agent it was designed for; entries, scripts, paths, package
managers, and command syntax must not be assumed to work on another platform.

Each registry may therefore use platform-specific paths and discovery and
installation methods. Typical examples are Homebrew and macOS paths for
`GetMyMacReady`, WinGet and PowerShell paths for `GetMyWinReady`, and the
appropriate Linux package manager and filesystem paths for `GetMyNixReady`.
The platform agent is responsible for selecting and validating the method
appropriate to its own operating system.

## Shared GMR contract

All three registries use the same GMR file format, naming conventions, and
module rules. The shared format provides portability of the registry
structure, not portability of the commands inside an entry. A module must
always be interpreted in the context of its target platform.

When changing a registry:

- Preserve the established GMR naming conventions and module boundaries.
- Keep platform-specific commands and paths in the registry for that
  platform.
- Do not execute or validate a registry with the wrong platform agent.
- Keep platform-specific scripts alongside the registry that invokes them.
- Update the relevant platform documentation and generated catalog when the
  registry's project rules require it.

The detailed interpretation rules for GMR modules belong in `RULES.md` and
apply equally to all three agents, subject to each platform's command and
installation capabilities.
