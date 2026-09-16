<#
.SYNOPSIS
    Selects GMR modules and individual commands through ConsoleTui.

    This is the current stable beta launcher.

.DESCRIPTION
    Discovers .gmr files beside this script. Modules and commands are
    toggled with Space. Enter opens a module and leaves a module menu.
    Continue opens the execution menu.

    A .gmr entry can use optional selection, title, command-type, and WinGet
    prefixes. A missing > means a standard WinGet installation. Use
    "# required: true" to keep a module enabled, or "# selected: true" to
    select it initially. Use -Clean to ignore both module settings for
    debugging.
#>

[CmdletBinding()]
param(
    [switch] $Clean,
    [string] $ElevatedWorkerFile,
    [string] $ElevatedWorkerOutputFile,
    [string] $ElevatedWorkerResultFile
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:UseWingetVerbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

function Set-GmrConsoleDefaults {
    $rawUi = $Host.UI.RawUI
    if ($null -ne $rawUi) {
        $rawUi.BackgroundColor = [ConsoleColor]::Black
        $rawUi.ForegroundColor = [ConsoleColor]::Gray
    }

    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::ForegroundColor = [ConsoleColor]::Gray
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Clear-Host
}


Set-GmrConsoleDefaults

$script:GmrRootDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:GmrRootDirectory)) {
    $script:GmrRootDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$consoleTuiManifest = Join-Path $script:GmrRootDirectory 'external\ConsoleTUI\src\ConsoleTui\ConsoleTui.psd1'
if (-not (Test-Path -LiteralPath $consoleTuiManifest -PathType Leaf)) {
    throw "ConsoleTUI was not found at '$consoleTuiManifest'. Initialize the Git submodule first."
}
Import-Module $consoleTuiManifest -Force -ErrorAction Stop -WarningAction SilentlyContinue
. (Join-Path $script:GmrRootDirectory 'tools\Get-ProgramDisplayName.ps1')
Import-Module (Join-Path $script:GmrRootDirectory 'Gmr.Common.psm1') -Force -ErrorAction Stop -WarningAction SilentlyContinue
Import-Module (Join-Path $script:GmrRootDirectory 'Gmr.Selection.psm1') -Force -ErrorAction Stop -WarningAction SilentlyContinue
$script:GmrState = [pscustomobject] @{ SelectionTouched = $false; StatePersistenceEnabled = $false }
$script:GmrWorkerFailed = $false

function Split-GmrCommandLine {
    param([Parameter(Mandatory = $true)][string] $CommandLine)

    $arguments = New-Object 'System.Collections.Generic.List[string]'
    $current = New-Object System.Text.StringBuilder
    $quote = [char]0
    $tokenStarted = $false

    for ($index = 0; $index -lt $CommandLine.Length; $index++) {
        $character = $CommandLine[$index]
        if ($quote -ne [char]0) {
            if ($character -eq $quote) { $quote = [char]0 }
            else { [void] $current.Append($character) }
            continue
        }

        if ($character -eq '"' -or $character -eq "'") {
            $quote = $character
            $tokenStarted = $true
        }
        elseif ([char]::IsWhiteSpace($character)) {
            if ($tokenStarted) {
                $arguments.Add($current.ToString())
                [void] $current.Clear()
                $tokenStarted = $false
            }
        }
        else {
            [void] $current.Append($character)
            $tokenStarted = $true
        }
    }

    if ($quote -ne [char]0) { throw "Unterminated quotation mark in command line: $CommandLine" }
    if ($tokenStarted) { $arguments.Add($current.ToString()) }
    return $arguments.ToArray()
}

function Get-WingetPackageSpec {
    param([Parameter(Mandatory = $true)][psobject] $Entry)

    $inputArguments = [string[]] @(Split-GmrCommandLine -CommandLine $Entry.Command)
    if ($inputArguments.Count -eq 0) { throw 'A WinGet package entry cannot be empty.' }

    $packageName = $inputArguments[0]
    if ($packageName -match '^-') {
        throw "Unable to determine the package name in WinGet entry: $($Entry.Command)"
    }

    $arguments = @(if ($Entry.WingetSelector -eq 'name') { '--name' } else { '--id' }, $packageName)
    if ($Entry.WingetExact) { $arguments += '--exact' }
    $arguments += @('--source', $Entry.WingetSource, '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    return [pscustomobject] @{
        DisplayName = $packageName
        Selector = if ($Entry.WingetSelector -eq 'name') { '--name' } else { '--id' }
        Source = $Entry.WingetSource
        Arguments = [string[]] $arguments
    }
}

function Test-GmrWingetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)][System.Management.Automation.CommandInfo] $WingetCommand,
        [Parameter(Mandatory = $true)][psobject] $PackageSpec
    )

    $listArguments = @(
        'list', $PackageSpec.Selector, $PackageSpec.DisplayName, '--exact',
        '--source', $PackageSpec.Source, '--disable-interactivity'
    )

    try {
        $listOutput = @(& $WingetCommand.Source @listArguments 2>&1 | ForEach-Object { $_.ToString() })
        $listExitCode = $LASTEXITCODE
        if ($listExitCode -ne 0) { return $false }

        $outputText = $listOutput -join "`n"
        return $outputText.IndexOf($PackageSpec.DisplayName, [StringComparison]::OrdinalIgnoreCase) -ge 0
    }
    catch {
        return $false
    }
}

function Format-GmrCommandArgument {
    param([Parameter(Mandatory = $true)][string] $Argument)
    if ($Argument -match '[\s"]') { return '"{0}"' -f ($Argument -replace '"', '\"') }
    return $Argument
}

function Resolve-GmrCommandPath {
    param(
        [Parameter(Mandatory = $true)][string] $CommandName,
        [Parameter(Mandatory = $true)][System.IO.FileInfo] $DescriptorFile
    )

    $resolvedCommand = [Environment]::ExpandEnvironmentVariables($CommandName)
    if (-not [System.IO.Path]::IsPathRooted($resolvedCommand)) {
        $localCommand = Join-Path $DescriptorFile.DirectoryName $resolvedCommand
        if ((Test-Path -LiteralPath $localCommand -PathType Leaf) -or
            $resolvedCommand.IndexOfAny([char[]] @('\', '/')) -ge 0) {
            $resolvedCommand = $localCommand
        }
    }
    if ([System.IO.Path]::IsPathRooted($resolvedCommand)) {
        $resolvedCommand = [System.IO.Path]::GetFullPath($resolvedCommand)
    }
    return $resolvedCommand
}

function Get-GmrPowerShellEntrySpec {
    param(
        [Parameter(Mandatory = $true)][string] $Entry,
        [Parameter(Mandatory = $true)][System.IO.FileInfo] $DescriptorFile
    )

    $value = $Entry.Trim()
    $unquotedValue = $value.Trim('"').Trim("'")
    if ($unquotedValue -match '(?i)^https?://\S+$') {
        return [pscustomobject] @{ Type = 'URL'; Value = $unquotedValue; DisplayValue = $unquotedValue }
    }
    if ($unquotedValue -match '(?i)^www\.\S+$') {
        $url = 'https://{0}' -f $unquotedValue
        return [pscustomobject] @{ Type = 'URL'; Value = $url; DisplayValue = $url }
    }

    $commandParts = [string[]] @(Split-GmrCommandLine -CommandLine $value)
    if ($commandParts.Count -gt 0) {
        $commandName = [Environment]::ExpandEnvironmentVariables($commandParts[0])
        $commandExtension = [System.IO.Path]::GetExtension($commandName).ToLowerInvariant()
        if ($commandExtension -in @('.ps1', '.cmd', '.bat', '.exe')) {
            $arguments = [string[]] @()
            if ($commandParts.Count -gt 1) {
                $arguments = [string[]] $commandParts[1..($commandParts.Count - 1)]
            }
            $resolvedCommand = Resolve-GmrCommandPath -CommandName $commandName -DescriptorFile $DescriptorFile
            $displayParts = @(
                Format-GmrCommandArgument -Argument $resolvedCommand
                $arguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ }
            )
            $type = if ($commandExtension -eq '.ps1') { 'Script' } else { 'Executable' }
            return [pscustomobject] @{
                Type = $type
                Value = $commandName
                FilePath = $resolvedCommand
                Arguments = [string[]] $arguments
                DisplayValue = $displayParts -join ' '
            }
        }
    }
    return [pscustomobject] @{ Type = 'PowerShell'; Value = $value; DisplayValue = $value }
}

function Get-GmrEntryDisplayName {
    param(
        [Parameter(Mandatory = $true)][psobject] $Record,
        [Parameter(Mandatory = $true)][System.IO.FileInfo] $DescriptorFile
    )

    if (-not [string]::IsNullOrWhiteSpace($Record.Title)) {
        return $Record.Title
    }

    if ($Record.Type -eq 'Winget') {
        return Resolve-ProgramDisplayName -InputValue $Record.Command -InputKind Package
    }

    $entrySpec = Get-GmrPowerShellEntrySpec -Entry $Record.Command -DescriptorFile $DescriptorFile
    if ($entrySpec.Type -eq 'Script') {
        return Resolve-ProgramDisplayName -InputValue $entrySpec.FilePath -InputKind Script
    }
    return $entrySpec.DisplayValue
}

function ConvertFrom-GmrEntryLine {
    param(
        [Parameter(Mandatory = $true)][string] $Line,
        [bool] $DefaultEnabled = $true,
        [bool] $Mandatory = $false
    )

    $value = $Line.Trim()
    if ($value -match '(?i)\s+#\s*default\s*:') {
        throw "Inline # default: metadata is not valid .gmr syntax: $Line"
    }

    $operatorIndex = -1
    $operator = $null
    $quote = [char]0
    for ($index = 0; $index -lt $value.Length; $index++) {
        $character = $value[$index]
        if ($quote -ne [char]0) {
            if ($character -eq $quote) { $quote = [char]0 }
            continue
        }
        if ($character -eq '"' -or $character -eq "'") { $quote = $character; continue }
        if ($character -eq '>') {
            $operatorIndex = $index
            $operator = if ($index -gt 1 -and $value.Substring($index - 2, 2) -ieq 'PS') { 'PS>' } elseif ($index -gt 0 -and $value[$index - 1] -eq '$') { '$>' } else { '>' }
            break
        }
    }
    if ($quote -ne [char]0) { throw "Unterminated quotation mark in .gmr entry: $Line" }

    if ($operatorIndex -ge 0) {
        $prefixEnd = $operatorIndex - $operator.Length + 1
        $prefixText = $value.Substring(0, $prefixEnd).Trim()
        $command = $value.Substring($operatorIndex + 1).Trim()
    }
    else {
        $prefixText = ''
        $command = $value
        $titleSeparator = -1
        $quote = [char]0
        for ($index = 0; $index -lt $value.Length; $index++) {
            $character = $value[$index]
            if ($quote -ne [char]0) {
                if ($character -eq $quote) { $quote = [char]0 }
                continue
            }
            if ($character -eq '"' -or $character -eq "'") { $quote = $character; continue }
            if ($character -eq ':') { $titleSeparator = $index; break }
        }
        if ($titleSeparator -ge 0) {
            $prefixText = $value.Substring(0, $titleSeparator).Trim()
            $command = $value.Substring($titleSeparator + 1).Trim()
        }
        else {
            while ($command -match '^\s*(?<prefix>\?|!|(?i:fuzzy|exact|id|name|winget|msstore))(?=\s|$)\s*(?<remaining>.*)$') {
                $prefixText = ('{0} {1}' -f $prefixText, $Matches['prefix']).Trim()
                $command = $Matches['remaining']
            }
        }
    }
    $attachedElevation = $false
    if ($command -match '^!(?=\S)') {
        $command = $command.Substring(1).TrimStart()
        $attachedElevation = $true
    }
    if ([string]::IsNullOrWhiteSpace($command)) { throw "A .gmr entry command cannot be empty: $Line" }

    $title = $null
    $titleMatch = [regex]::Match($prefixText, '(?<quote>["''])(?<title>.*?)\k<quote>')
    if ($titleMatch.Success) {
        $title = $titleMatch.Groups['title'].Value
        $prefixText = $prefixText.Remove($titleMatch.Index, $titleMatch.Length)
    }
    $prefixText = $prefixText.Replace(':', ' ').Trim()
    $prefixTokens = if ([string]::IsNullOrWhiteSpace($prefixText)) { @() } else { [string[]] @(Split-GmrCommandLine -CommandLine $prefixText) }
    $normalizedPrefixTokens = New-Object 'System.Collections.Generic.List[string]'
    foreach ($prefix in $prefixTokens) {
        if ($prefix.Length -gt 1 -and $prefix -match '^[?!^]+$') {
            for ($index = 0; $index -lt $prefix.Length; $index++) {
                [void] $normalizedPrefixTokens.Add([string] $prefix[$index])
            }
        }
        else {
            [void] $normalizedPrefixTokens.Add($prefix)
        }
    }
    $prefixTokens = $normalizedPrefixTokens
    $entryType = if ($operator -in @('$>', 'PS>')) { 'PowerShell' } else { 'Winget' }
    $wingetSelector = if ($command.TrimStart().StartsWith('"')) { 'name' } else { 'id' }
    $wingetSource = 'winget'
    $wingetExact = $true
    $requiresElevation = $attachedElevation
    $hasOptionalPrefix = $false
    $hasMandatoryPrefix = $false
    foreach ($prefix in $prefixTokens) {
        switch -Regex ($prefix) {
            '^\?$' {
                if ($hasMandatoryPrefix) { throw "Optional (?) and mandatory (!) prefixes cannot be combined in .gmr entry: $Line" }
                $hasOptionalPrefix = $true
                $DefaultEnabled = $false
                continue
            }
            '^!$' {
                if ($hasOptionalPrefix) { throw "Optional (?) and mandatory (!) prefixes cannot be combined in .gmr entry: $Line" }
                $hasMandatoryPrefix = $true
                $Mandatory = $true
                continue
            }
            '^\^$' { $requiresElevation = $true; continue }
            '^(?i:fuzzy)$' { $wingetExact = $false; continue }
            '^(?i:exact)$' { $wingetExact = $true; continue }
            '^(?i:id|name)$' { $wingetSelector = $prefix.ToLowerInvariant(); continue }
            '^(?i:winget|msstore)$' { $wingetSource = $prefix.ToLowerInvariant(); continue }
            default { throw "Unknown .gmr prefix '$prefix' in entry: $Line" }
        }
    }
    return [pscustomobject] @{
        Value = $command; Command = $command; Type = $entryType; Title = $title
        DefaultEnabled = $DefaultEnabled; Mandatory = $Mandatory; RequiresElevation = $requiresElevation
        WingetSelector = $wingetSelector; WingetSource = $wingetSource; WingetExact = $wingetExact
    }
}

function Get-GmrEntryRecords {
    param(
        [Parameter(Mandatory = $true)][string] $FilePath,
        [string[]] $IncludeChain = @()
    )

    $fullPath = [System.IO.Path]::GetFullPath($FilePath)
    if ([System.IO.Path]::GetExtension($fullPath) -ine '.gmr') {
        throw "GMR beta only supports .gmr descriptors: $fullPath"
    }
    if ($IncludeChain -contains $fullPath) {
        throw "Circular .gmr include detected: $((@($IncludeChain) + $fullPath) -join ' -> ')"
    }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Descriptor file was not found: $fullPath"
    }

    $records = New-Object 'System.Collections.Generic.List[object]'
    $currentChain = @($IncludeChain) + $fullPath
    foreach ($line in @(Read-GmrUtf8Lines -LiteralPath $fullPath)) {
        if ($line -match '^\s*#\s*default\s*:') { continue }
        if ($line -match '^\s*#\s*include\s*:\s*(.+?)\s*$') {
            $includePath = [Environment]::ExpandEnvironmentVariables($Matches[1].Trim().Trim('"').Trim("'"))
            if (-not [System.IO.Path]::IsPathRooted($includePath)) {
                $includePath = Join-Path ([System.IO.Path]::GetDirectoryName($fullPath)) $includePath
            }
            foreach ($includedRecord in @(Get-GmrEntryRecords -FilePath $includePath -IncludeChain $currentChain)) {
                $records.Add($includedRecord)
            }
            continue
        }
        if ($line -match '^\s*(#|$)') { continue }

        $record = ConvertFrom-GmrEntryLine -Line $line -DefaultEnabled $true
        $records.Add($record)
    }
    return $records.ToArray()
}

function Get-GmrDescriptor {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo] $File,
        [switch] $Clean
    )

    if ($File.Extension -ine '.gmr') {
        throw "GMR beta only supports .gmr descriptors: $($File.FullName)"
    }

    $lines = @(Read-GmrUtf8Lines -LiteralPath $File.FullName)
    $friendlyName = $null
    $sortIndex = [int]::MaxValue
    $required = $false
    $selected = $false
    $hidden = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*#\s*name\s*:\s*(.+?)\s*$') {
            $friendlyName = $Matches[1].Trim()
        }
        if ($line -match '^\s*#\s*sortindex\s*:\s*(\d+)\s*$') {
            $sortIndex = [int] $Matches[1]
        }
        if ($line -match '^\s*#\s*required\s*:\s*(yes|true|no|false)\s*$') {
            $required = $Matches[1] -match '^(?i:yes|true)$'
        }
        if ($line -match '^\s*#\s*selected\s*:\s*(yes|true|no|false)\s*$') {
            $selected = $Matches[1] -match '^(?i:yes|true)$'
        }
        if ($line -match '^\s*#\s*hidden\s*:\s*(yes|true|no|false)\s*$') {
            $hidden = $Matches[1] -match '^(?i:yes|true)$'
        }
    }
    if ($Clean) {
        $required = $false
        $selected = $false
    }
    $hasFriendlyName = -not [string]::IsNullOrWhiteSpace($friendlyName)
    if (-not $hasFriendlyName) {
        $friendlyName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    }

    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($record in @(Get-GmrEntryRecords -FilePath $File.FullName)) {
        $displayName = Get-GmrEntryDisplayName -Record $record -DescriptorFile $File
        $entry = [pscustomobject] @{
            Value = $record.Value
            Command = $record.Command
            Type = $record.Type
            Title = $record.Title
            WingetSelector = $record.WingetSelector
            WingetSource = $record.WingetSource
            WingetExact = $record.WingetExact
            DisplayName = $displayName
            DefaultEnabled = [bool] $record.DefaultEnabled
            Mandatory = [bool] $record.Mandatory
            RequiresElevation = [bool] $record.RequiresElevation
            Enabled = $false
            StateId = $null
            StateStatus = 0
            MenuItem = $null
        }
        $entry.StateId = Get-GmrEntryStateId -Entry $entry
        $entries.Add($entry)
    }

    $module = [pscustomobject] @{
        File = $File
        Type = '.gmr'
        FriendlyName = $friendlyName
        DisplayName = if ($hasFriendlyName) { $friendlyName } else { $File.Name }
        Entries = [object[]] $entries.ToArray()
        Required = $required
        Selected = $selected
        Hidden = [bool] ($hidden -or $entries.Count -eq 0)
        Enabled = $false
        MenuItem = $null
        Menu = $null
        SortIndex = $sortIndex
    }
    if ($module.Required -or $module.Selected) {
        Set-GmrModuleState -Module $module -Enabled $true
    }
    return $module
}

function Get-GmrMenuLayout {
    param([Parameter(Mandatory = $true)][ValidateRange(1, [int]::MaxValue)][int] $ItemCount)

    if ($ItemCount -gt 48) {
        throw "A menu contains $ItemCount items. The supported maximum is 48 (4 columns x 12 rows)."
    }
    $columnCount = [Math]::Max(1, [Math]::Min(4, [int] [Math]::Ceiling($ItemCount / 12.0)))
    $rowsPerColumn = [int] [Math]::Ceiling($ItemCount / [double] $columnCount)
    return [pscustomobject] @{ ColumnCount = $columnCount; RowsPerColumn = $rowsPerColumn }
}

function Get-GmrCheckbox {
    param([bool] $Checked)
    if ($Checked) { return '[x]' }
    return '[ ]'
}

function Test-GmrEntryMandatory {
    param([Parameter(Mandatory = $true)][object] $Entry)
    $property = $Entry.PSObject.Properties['Mandatory']
    return $null -ne $property -and [bool]$property.Value
}

function Test-GmrModuleRequired {
    param([Parameter(Mandatory = $true)][object] $Module)
    $property = $Module.PSObject.Properties['Required']
    return $null -ne $property -and [bool]$property.Value
}

function Get-GmrEntryStateStatus {
    param([Parameter(Mandatory = $true)][object] $Entry)
    $property = $Entry.PSObject.Properties['StateStatus']
    if ($null -eq $property) { return 0 }
    return [int] $property.Value
}

function Test-GmrEntryStateLocked {
    param([Parameter(Mandatory = $true)][object] $Entry)
    return (Get-GmrEntryStateStatus -Entry $Entry) -ge 2
}

function Test-GmrEntryStateDisabled {
    param([Parameter(Mandatory = $true)][object] $Entry)
    return (Get-GmrEntryStateStatus -Entry $Entry) -ge 4
}

function Get-GmrEntryLabel {
    param([Parameter(Mandatory = $true)][object] $Entry)

    $entryMarker = ''
    $elevationProperty = $Entry.PSObject.Properties['RequiresElevation']
    if ($null -ne $elevationProperty -and [bool]$elevationProperty.Value) {
        $entryMarker += ' ' + [char]0x1D41
    }
    if (Test-GmrEntryMandatory -Entry $Entry) {
        $entryMarker += ' ' + [char]0x1D3F
    }
    $displayName = '{0}{1}' -f $Entry.DisplayName, $entryMarker
    $status = Get-GmrEntryStateStatus -Entry $Entry
    if ($status -eq 4) {
        return '[*] {0}' -f $displayName
    }
    $progressSuffix = if ($status -ge 2) { ' [in progress - locked]' } elseif ($status -eq 1) { ' [in progress]' } else { '' }
    $indicator = if ($status -ge 1 -and $status -le 3) { '[*]' } else { Get-GmrCheckbox -Checked $Entry.Enabled }
    return '{0} {1}{2}' -f $indicator, $displayName, $progressSuffix
}

function Save-GmrModuleSelectionState {
    param([Parameter(Mandatory = $true)][object] $Module)
    if (-not $script:GmrState.StatePersistenceEnabled) { return }
    foreach ($entry in $Module.Entries) {
        $id = if ($entry.PSObject.Properties['StateId']) { $entry.StateId } else { Get-GmrEntryStateId -Entry $entry }
        $record = Set-GmrStateRecord -RootDirectory $script:GmrRootDirectory -Id $id -Selected $entry.Enabled
        if ($entry.PSObject.Properties['StateStatus']) { $entry.StateStatus = $record.status }
    }
}

function Restore-GmrStateSelections {
    param([Parameter(Mandatory = $true)][object[]] $Modules)
    $state = Read-GmrState -RootDirectory $script:GmrRootDirectory
    foreach ($module in $Modules) {
        foreach ($entry in $module.Entries) {
            $record = Get-GmrStateRecord -State $state -Id $entry.StateId
            if ($null -ne $record) {
                $entry.Enabled = ([int] $record.status -lt 4) -and ([bool] $record.selected -or ([int] $record.status -ge 2))
                $entry.StateStatus = [int] $record.status
            }
        }
        Update-GmrModuleLabel -Module $module
    }
}

function Set-GmrEntryInstallStatus {
    param([Parameter(Mandatory = $true)][object] $Entry, [Parameter(Mandatory = $true)][ValidateRange(0, 4)][int] $Status)
    $Entry.Enabled = $true
    if ($Entry.PSObject.Properties['StateStatus']) { $Entry.StateStatus = $Status }
    if ($script:GmrState.StatePersistenceEnabled) {
        $id = if ($Entry.PSObject.Properties['StateId']) { $Entry.StateId } else { Get-GmrEntryStateId -Entry $Entry }
        [void] (Set-GmrStateRecord -RootDirectory $script:GmrRootDirectory -Id $id -Selected $true -Status $Status)
    }
}

function Get-GmrModuleStateCounts {
    param([Parameter(Mandatory = $true)][object] $Module)

    $installedCount = @($Module.Entries | Where-Object { (Get-GmrEntryStateStatus -Entry $_) -eq 4 }).Count
    $selectedCount = @($Module.Entries | Where-Object {
        (Get-GmrEntryStateStatus -Entry $_) -lt 4 -and $_.Enabled
    }).Count
    return [pscustomobject] @{
        Installed = $installedCount
        Selected = $selectedCount
        Active = $installedCount + $selectedCount
    }
}

function Get-GmrModuleMode {
    param([Parameter(Mandatory = $true)][object] $Module)

    $counts = Get-GmrModuleStateCounts -Module $Module
    if ($counts.Active -eq 0 -and -not (Test-GmrModuleRequired -Module $Module)) { return 'None' }
    if ($counts.Active -eq $Module.Entries.Count) { return 'All' }
    return 'Selective'
}

function Get-GmrModuleIndicator {
    param([Parameter(Mandatory = $true)][object] $Module)

    switch (Get-GmrModuleMode -Module $Module) {
        'All' { return '[x]' }
        'Selective' { return '[*]' }
        default { return '[ ]' }
    }
}

function Get-GmrModuleLabel {
    param([Parameter(Mandatory = $true)][object] $Module)

    $counts = Get-GmrModuleStateCounts -Module $Module
    $selectedSuffix = if ($counts.Selected -gt 0) { '*' } else { '' }
    $requiredSuffix = if (Test-GmrModuleRequired -Module $Module) { ' [required]' } else { '' }
    return '{0} {1} [{2}{3}/{4}]{5}' -f `
        (Get-GmrModuleIndicator -Module $Module),
        $Module.DisplayName,
        $counts.Active,
        $selectedSuffix,
        $Module.Entries.Count,
        $requiredSuffix
}

function Update-GmrEntryLabel {
    param([Parameter(Mandatory = $true)][object] $Entry)
    if ($null -ne $Entry.MenuItem) {
        $Entry.MenuItem.Label = Get-GmrEntryLabel -Entry $Entry
    }
}

function Update-GmrModuleLabel {
    param([Parameter(Mandatory = $true)][object] $Module)
    $selectedCount = @($Module.Entries | Where-Object Enabled).Count
    $selectedProperty = $Module.PSObject.Properties['Selected']
    $isSelected = $null -ne $selectedProperty -and [bool]$selectedProperty.Value
    $Module.Enabled = $selectedCount -gt 0 -or (Test-GmrModuleRequired -Module $Module) -or $isSelected
    if ($null -ne $Module.MenuItem) {
        $Module.MenuItem.Label = Get-GmrModuleLabel -Module $Module
        $counts = Get-GmrModuleStateCounts -Module $Module
        $Module.MenuItem.Bright = $counts.Selected -gt 0
    }
}

function Set-GmrModuleState {
    param(
        [Parameter(Mandatory = $true)][object] $Module,
        [Parameter(Mandatory = $true)][bool] $Enabled
    )

    $effectiveEnabled = $Enabled -or (Test-GmrModuleRequired -Module $Module)
    foreach ($entry in $Module.Entries) {
        $entry.Enabled = ((Test-GmrEntryStateLocked -Entry $entry) -and -not (Test-GmrEntryStateDisabled -Entry $entry)) -or
            ((-not (Test-GmrEntryStateDisabled -Entry $entry)) -and $effectiveEnabled -and ($entry.DefaultEnabled -or (Test-GmrEntryMandatory -Entry $entry)))
        Update-GmrEntryLabel -Entry $entry
    }
    Update-GmrModuleLabel -Module $Module
}

function New-GmrModuleMenu {
    param([Parameter(Mandatory = $true)][object] $Module)

    $items = New-Object 'System.Collections.Generic.List[object]'
    $items.Add((New-TuiMenuItem -Id 'back' -Label '(Back)' -GoBack))
    for ($index = 0; $index -lt $Module.Entries.Count; $index++) {
        $entry = $Module.Entries[$index]
        $item = New-TuiMenuItem `
            -Id "entry-$index" `
            -Label (Get-GmrEntryLabel -Entry $entry) `
            -GoBack
        $entry.MenuItem = $item
        $item.Dimmed = (Get-GmrEntryStateStatus -Entry $entry) -eq 4
        $item.Bright = (Get-GmrEntryStateStatus -Entry $entry) -lt 4 -and $entry.Enabled
        $gmrState = $script:GmrState
        $saveSelection = ${function:Save-GmrModuleSelectionState}
        $item.SpaceAction = {
            $gmrState.SelectionTouched = $true
            if ($entry.PSObject.Properties['StateStatus'] -and [int] $entry.StateStatus -ge 2) { return }
            $entryMandatoryProperty = $entry.PSObject.Properties['Mandatory']
            $entryIsMandatory = $null -ne $entryMandatoryProperty -and [bool]$entryMandatoryProperty.Value
            $hadSelectedEntries = @($Module.Entries | Where-Object Enabled).Count -gt 0
            if ($entryIsMandatory) {
                if (-not $hadSelectedEntries) {
                    $entry.Enabled = $true
                }
            }
            else {
                $entry.Enabled = -not $entry.Enabled
                if (-not $hadSelectedEntries -and $entry.Enabled) {
                    foreach ($moduleEntry in $Module.Entries) {
                        $mandatoryProperty = $moduleEntry.PSObject.Properties['Mandatory']
                        if ($null -ne $mandatoryProperty -and [bool]$mandatoryProperty.Value) {
                            $moduleEntry.Enabled = $true
                        }
                    }
                }
            }
            foreach ($moduleEntry in $Module.Entries) {
                if ((Get-GmrEntryStateStatus -Entry $moduleEntry) -eq 4) { $moduleEntry.Enabled = $true }
                $moduleEntry.MenuItem.Label = Get-GmrEntryLabel -Entry $moduleEntry
                $moduleEntry.MenuItem.Dimmed = (Get-GmrEntryStateStatus -Entry $moduleEntry) -eq 4
                $moduleEntry.MenuItem.Bright = (Get-GmrEntryStateStatus -Entry $moduleEntry) -lt 4 -and $moduleEntry.Enabled
            }
            $moduleRequiredProperty = $Module.PSObject.Properties['Required']
            $moduleIsRequired = $null -ne $moduleRequiredProperty -and [bool]$moduleRequiredProperty.Value
            $selectedCount = @($Module.Entries | Where-Object Enabled).Count
            $Module.Enabled = $selectedCount -gt 0 -or $moduleIsRequired
            Update-GmrModuleLabel -Module $Module
            & $saveSelection -Module $Module
        }.GetNewClosure()
        $items.Add($item)
    }

    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    $Module.Menu = New-TuiMenu `
        -Title $Module.DisplayName `
        -Items $items.ToArray() `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
        -SelectionMarker '>' `
        -Toolbar ('Up/Down Select  Left/Right Column  Space Toggle  Enter Back  Esc Back    {0} UAC  {1} Required' -f ([char]0x1D41), ([char]0x1D3F))
    return $Module.Menu
}

function New-GmrMainMenu {
    param([Parameter(Mandatory = $true)][object[]] $Modules)

    $items = New-Object 'System.Collections.Generic.List[object]'
    for ($index = 0; $index -lt $Modules.Count; $index++) {
        $module = $Modules[$index]
        $childMenu = New-GmrModuleMenu -Module $module
        $item = New-TuiMenuItem `
            -Id "module-$index" `
            -Label (Get-GmrModuleLabel -Module $module) `
            -ChildMenu $childMenu
        $module.MenuItem = $item
        $moduleCounts = Get-GmrModuleStateCounts -Module $module
        $item.Bright = $moduleCounts.Selected -gt 0
        $gmrState = $script:GmrState
        $saveSelection = ${function:Save-GmrModuleSelectionState}
        $moduleRequiredProperty = $module.PSObject.Properties['Required']
        $moduleIsRequired = $null -ne $moduleRequiredProperty -and [bool]$moduleRequiredProperty.Value
        $item.SpaceAction = {
            $gmrState.SelectionTouched = $true
            $selectedCount = @($module.Entries | Where-Object Enabled).Count
            if ($moduleIsRequired -or $selectedCount -eq 0) {
                foreach ($moduleEntry in $module.Entries) {
                    $mandatoryProperty = $moduleEntry.PSObject.Properties['Mandatory']
                    $isMandatory = $null -ne $mandatoryProperty -and [bool]$mandatoryProperty.Value
                    $moduleEntry.Enabled = ($moduleEntry.PSObject.Properties['StateStatus'] -and [int] $moduleEntry.StateStatus -eq 2) -or
                        ((-not ($moduleEntry.PSObject.Properties['StateStatus'] -and [int] $moduleEntry.StateStatus -ge 4)) -and ($moduleEntry.DefaultEnabled -or $isMandatory))
                }
            }
            elseif ($selectedCount -lt $module.Entries.Count) {
                foreach ($moduleEntry in $module.Entries) {
                    $moduleEntry.Enabled = -not ($moduleEntry.PSObject.Properties['StateStatus'] -and [int] $moduleEntry.StateStatus -ge 4)
                }
            }
            else {
                foreach ($moduleEntry in $module.Entries) {
                    $moduleEntry.Enabled = $moduleEntry.PSObject.Properties['StateStatus'] -and [int] $moduleEntry.StateStatus -eq 2
                }
            }
            foreach ($moduleEntry in $module.Entries) {
                if ((Get-GmrEntryStateStatus -Entry $moduleEntry) -eq 4) { $moduleEntry.Enabled = $true }
                $moduleEntry.MenuItem.Label = Get-GmrEntryLabel -Entry $moduleEntry
                $moduleEntry.MenuItem.Dimmed = (Get-GmrEntryStateStatus -Entry $moduleEntry) -eq 4
                $moduleEntry.MenuItem.Bright = (Get-GmrEntryStateStatus -Entry $moduleEntry) -lt 4 -and $moduleEntry.Enabled
            }
            $selectedCount = @($module.Entries | Where-Object Enabled).Count
            $module.Enabled = $selectedCount -gt 0 -or $moduleIsRequired
            Update-GmrModuleLabel -Module $module
            & $saveSelection -Module $module
        }.GetNewClosure()
        $items.Add($item)
    }
    $items.Add((New-TuiMenuItem -Id 'continue' -Label 'Continue' -Action { 'Continue' } -CloseAfterAction))
    $items.Add((New-TuiMenuItem -Id 'quit' -Label 'Quit' -Action { 'Quit' } -CloseAfterAction))

    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    return New-TuiMenu `
        -Title 'GetMeReady (beta)' `
        -TitleDetail ' - Created by Mikael Levén ' `
        -Items $items.ToArray() `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
        -SelectionMarker '>' `
        -Toolbar 'Up/Down Select  Left/Right Column  Space Toggle  Enter Open  Esc Quit'
}

function Test-GmrSelectionChanged {
    param([Parameter(Mandatory = $true)][object[]] $Modules)
    return $script:GmrState.SelectionTouched -or @($Modules | Where-Object Enabled).Count -gt 0
}

function Confirm-GmrAbort {
    param(
        [Parameter(Mandatory = $true)][object[]] $Modules,
        [Parameter(Mandatory = $true)][object] $Theme
    )
    if (-not (Test-GmrSelectionChanged -Modules $Modules)) { return $true }
    return Show-TuiConfirmDialog `
        -Title 'Abort?' `
        -Message 'Abort without running the selected commands?' `
        -DefaultChoice No `
        -Theme $Theme
}

function New-GmrExecutionMenu {
    param([Parameter(Mandatory = $true)][ref] $CreateRestorePoint)

    $restoreItem = New-TuiMenuItem -Id 'restore-point' -Label '[ ] Create restore point' -Action {}
    $restoreItem.Dimmed = $true
    $gmrState = $script:GmrState
    $restoreItem.SpaceAction = {
        $gmrState.SelectionTouched = $true
        $CreateRestorePoint.Value = -not $CreateRestorePoint.Value
        $restoreItem.Label = '{0} Create restore point' -f $(if ($CreateRestorePoint.Value) { '[x]' } else { '[ ]' })
    }.GetNewClosure()

    $saveConfigurationItem = New-TuiMenuItem -Id 'save-configuration' -Label 'Save configuration (not implemented)' -Action {}
    $saveConfigurationItem.Dimmed = $true

    $items = @(
        $restoreItem
        $saveConfigurationItem
        (New-TuiMenuItem -Id 'proceed-dry-run' -Label 'Proceed (dry-run)' -Action { 'DryRun' } -CloseAfterAction)
        (New-TuiMenuItem -Id 'proceed' -Label 'Proceed' -Action { 'Proceed' } -CloseAfterAction)
        (New-TuiMenuItem -Id 'quit' -Label 'Quit' -Action { 'Quit' } -CloseAfterAction)
    )
    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    return New-TuiMenu `
        -Title 'Execution options' `
        -Items $items `
        -InitialSelectedIndex 2 `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
        -SelectionMarker '>' `
        -Toolbar 'Up/Down Select  Space Toggle  Enter Back  Esc Back'
}

function New-GmrRestorePoint {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Creating a restore point requires an elevated PowerShell session. Run GMR.ps1 as Administrator.'
    }
    if ($null -eq (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue)) {
        throw 'Checkpoint-Computer is unavailable on this system.'
    }
    $description = 'GMR setup - {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host "Creating restore point: $description" -ForegroundColor Cyan
    Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS
    Write-Host 'Restore point created.' -ForegroundColor Green
}

function Test-GmrAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-GmrWindowsPowerShellPath {
    return (Get-Command powershell.exe -CommandType Application -ErrorAction Stop).Source
}

function New-GmrExecutionSummary {
    param([object[]] $Results = @())

    $normalizedResults = @($Results)
    return [pscustomobject] @{
        Results = $normalizedResults
        Succeeded = @($normalizedResults | Where-Object { $_.Success }).Count
        Failed = @($normalizedResults | Where-Object { -not $_.Success }).Count
    }
}

function Write-GmrExecutionSummary {
    param(
        [Parameter(Mandatory = $true)][object] $Summary,
        [string] $Label = 'Completed'
    )

    Write-Host ("{0}: {1} succeeded, {2} failed." -f $Label, $Summary.Succeeded, $Summary.Failed) -ForegroundColor $(
        if ($Summary.Failed -eq 0) { 'Green' } else { 'Yellow' }
    )
    if ($Summary.Failed -gt 0) {
        @($Summary.Results | Where-Object { -not $_.Success }) |
            Format-Table Type, Item, ExitCode -AutoSize |
            Out-Host
    }
}

function Get-GmrWorkerOutputLineCount {
    param(
        [Parameter(Mandatory = $true)][string] $OutputFile,
        [Parameter(Mandatory = $true)][int] $ReadLineCount
    )

    if (-not (Test-Path -LiteralPath $OutputFile -PathType Leaf)) {
        return $ReadLineCount
    }

    try {
        $rawOutput = Get-Content -LiteralPath $OutputFile -Raw -Encoding UTF8
        if ([string]::IsNullOrEmpty($rawOutput)) {
            return $ReadLineCount
        }
        $lines = @($rawOutput -split "`r?`n")
        $completeLineCount = $lines.Count - 1
        for ($index = $ReadLineCount; $index -lt $completeLineCount; $index++) {
            [Console]::Out.WriteLine([string] $lines[$index])
        }
        return $completeLineCount
    }
    catch [System.IO.IOException] {
        # The worker may be flushing the relay file. Retry on the next poll.
        return $ReadLineCount
    }
}

function Save-GmrWorkerResult {
    param(
        [Parameter(Mandatory = $true)][string] $ResultFile,
        [Parameter(Mandatory = $true)][object] $Summary
    )

    $Summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ResultFile -Encoding UTF8
}

function Start-GmrElevatedWorker {
    param(
        [Parameter(Mandatory = $true)][object[]] $SelectedEntries,
        [Parameter(Mandatory = $true)][bool] $CreateRestorePoint
    )

    $temporaryRoot = [System.IO.Path]::GetTempPath()
    $payloadPath = Join-Path $temporaryRoot ('GMR-Elevation-{0}.json' -f [guid]::NewGuid().ToString('N'))
    $outputPath = Join-Path $temporaryRoot ('GMR-Elevation-{0}.out' -f [guid]::NewGuid().ToString('N'))
    $resultPath = Join-Path $temporaryRoot ('GMR-Elevation-{0}.result.json' -f [guid]::NewGuid().ToString('N'))
    $payload = [pscustomobject] @{
        EntryIds = [string[]] @($SelectedEntries | ForEach-Object { $_.Entry.StateId })
        CreateRestorePoint = $CreateRestorePoint
    }
    $payload | ConvertTo-Json -Compress | Set-Content -LiteralPath $payloadPath -Encoding UTF8

    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        $PSCommandPath
        '-ElevatedWorkerFile'
        $payloadPath
        '-ElevatedWorkerOutputFile'
        $outputPath
        '-ElevatedWorkerResultFile'
        $resultPath
    )
    if ($script:UseWingetVerbose) { $arguments += '-Verbose' }
    $argumentLine = @($arguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ }) -join ' '
    $process = $null
    $readLineCount = 0

    try {
        Set-Content -LiteralPath $outputPath -Value $null -Encoding UTF8
        $process = Start-Process -FilePath (Get-GmrWindowsPowerShellPath) -Verb RunAs -PassThru -ArgumentList $argumentLine
        do {
            $readLineCount = Get-GmrWorkerOutputLineCount -OutputFile $outputPath -ReadLineCount $readLineCount
            $process.Refresh()
            if (-not $process.HasExited) {
                Start-Sleep -Milliseconds 100
            }
        } while (-not $process.HasExited)
        $process.WaitForExit()
        Start-Sleep -Milliseconds 50
        $readLineCount = Get-GmrWorkerOutputLineCount -OutputFile $outputPath -ReadLineCount $readLineCount

        if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
            $workerSummary = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($process.ExitCode -ne 0) {
                Write-Host "Elevated installation worker failed with exit code $($process.ExitCode)." -ForegroundColor Red
                if ($workerSummary.Failed -eq 0) {
                    $workerSummary = New-GmrExecutionSummary -Results @(
                        @($workerSummary.Results)
                        [pscustomobject] @{ Item = 'Elevated installation worker'; Type = 'Worker'; Success = $false; ExitCode = $process.ExitCode }
                    )
                }
            }
            return $workerSummary
        }

        Write-Host "Elevated installation worker failed with exit code $($process.ExitCode)." -ForegroundColor Red
        return (New-GmrExecutionSummary -Results @(
            [pscustomobject] @{ Item = 'Elevated installation worker'; Type = 'Worker'; Success = $false; ExitCode = $process.ExitCode }
        ))
    }
    catch {
        Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        return (New-GmrExecutionSummary -Results @(
            [pscustomobject] @{ Item = 'Elevated installation worker'; Type = 'Worker'; Success = $false; ExitCode = $null }
        ))
    }
    finally {
        Remove-Item -LiteralPath $payloadPath, $outputPath, $resultPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-GmrSelectedEntries {
    param([Parameter(Mandatory = $true)][object[]] $Modules)

    return @(
        foreach ($module in $Modules | Where-Object Enabled) {
            foreach ($entry in $module.Entries | Where-Object { $_.Enabled -and (Get-GmrEntryStateStatus -Entry $_) -lt 4 }) {
                [pscustomobject] @{ Module = $module; Entry = $entry }
            }
        }
    )
}

function Invoke-GmrElevatedWorker {
    param(
        [Parameter(Mandatory = $true)][string] $WorkerFile,
        [string] $ResultFile
    )

    if (-not (Test-Path -LiteralPath $WorkerFile -PathType Leaf)) {
        throw "Elevated worker payload was not found: $WorkerFile"
    }

    $payload = Get-Content -LiteralPath $WorkerFile -Raw | ConvertFrom-Json
    $entryIds = [string[]] @($payload.EntryIds)
    $descriptorFiles = @(
        Get-ChildItem -LiteralPath $script:GmrRootDirectory -File |
            Where-Object { $_.Extension -ieq '.gmr' } |
            Sort-Object Name
    )
    $modules = [object[]] @($descriptorFiles | ForEach-Object { Get-GmrDescriptor -File $_ } | Where-Object { -not $_.Hidden })
    Restore-GmrStateSelections -Modules $modules
    $script:GmrState.StatePersistenceEnabled = $true

    $selectedEntries = @(
        foreach ($module in $modules) {
            foreach ($entry in $module.Entries) {
                if ($entryIds -contains $entry.StateId) {
                    [pscustomobject] @{ Module = $module; Entry = $entry }
                }
            }
        }
    )
    if ($selectedEntries.Count -ne $entryIds.Count) {
        throw 'One or more selected elevated entries could not be resolved.'
    }

    try {
        if ([bool] $payload.CreateRestorePoint) {
            New-GmrRestorePoint
        }
        if ($selectedEntries.Count -gt 0) {
            $summary = Invoke-GmrSelectedCommands -DryRun $false -CreateRestorePoint $false -SelectedEntries $selectedEntries
            if ($summary.Failed -gt 0) {
                $script:GmrWorkerFailed = $true
            }
        }
        else {
            $summary = New-GmrExecutionSummary
            Write-Host 'Nothing was selected to run.' -ForegroundColor Yellow
            Write-GmrExecutionSummary -Summary $summary
        }
        if (-not [string]::IsNullOrWhiteSpace($ResultFile)) {
            Save-GmrWorkerResult -ResultFile $ResultFile -Summary $summary
        }
    }
    catch {
        $script:GmrWorkerFailed = $true
        Write-Host "Elevated worker failed: $($_.Exception.Message)" -ForegroundColor Red
        $failureItem = if ([bool] $payload.CreateRestorePoint) { 'Restore point' } else { 'Elevated worker' }
        $failureType = if ([bool] $payload.CreateRestorePoint) { 'RestorePoint' } else { 'Worker' }
        $summary = New-GmrExecutionSummary -Results @(
            [pscustomobject] @{ Item = $failureItem; Type = $failureType; Success = $false; ExitCode = $null }
        )
        if (-not [string]::IsNullOrWhiteSpace($ResultFile)) {
            Save-GmrWorkerResult -ResultFile $ResultFile -Summary $summary
        }
    }
}

function Start-GmrTranscript {
    param([string] $Suffix = '')

    $logDirectory = Join-Path $script:GmrRootDirectory 'Logs'
    New-Item -ItemType Directory -Path $logDirectory -Force -ErrorAction Stop | Out-Null
    $logPath = Join-Path $logDirectory ('GMR-{0}{1}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $Suffix)
    Start-Transcript -LiteralPath $logPath -ErrorAction Stop | Out-Null
    Write-Host "Logging this GMR session to: $logPath" -ForegroundColor DarkGray
    return $logPath
}

function Invoke-GmrSelectedCommands {
    param(
        [object[]] $Modules = @(),
        [Parameter(Mandatory = $true)][bool] $DryRun,
        [Parameter(Mandatory = $true)][bool] $CreateRestorePoint,
        [object[]] $SelectedEntries = @()
    )

    if (-not $PSBoundParameters.ContainsKey('SelectedEntries')) {
        $SelectedEntries = Get-GmrSelectedEntries -Modules $Modules
    }
    if ($SelectedEntries.Count -eq 0) {
        Write-Host 'Nothing was selected to run.' -ForegroundColor Yellow
        $emptySummary = New-GmrExecutionSummary
        Write-GmrExecutionSummary -Summary $emptySummary
        return $emptySummary
    }

    if ($CreateRestorePoint) {
        if ($DryRun) { Write-Host '  [DRY RUN] Create Windows system restore point.' }
        else {
            try { New-GmrRestorePoint }
            catch {
                Write-Host "Restore point creation failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host 'Processing aborted; no commands were executed.' -ForegroundColor Red
                $restorePointFailure = New-GmrExecutionSummary -Results @(
                    [pscustomobject] @{ Item = 'Restore point'; Type = 'RestorePoint'; Success = $false; ExitCode = $null }
                )
                Write-GmrExecutionSummary -Summary $restorePointFailure
                return $restorePointFailure
            }
        }
    }

    $results = @()
    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
    foreach ($selection in $SelectedEntries) {
        $module = $selection.Module
        $entry = $selection.Entry
        if ($module.Type -eq '.gmr') {
            if ($entry.Type -eq 'PowerShell') {
                $exitCode = $null
                $underlyingExitCode = $null
                try {
                    $entrySpec = Get-GmrPowerShellEntrySpec -Entry $entry.Command -DescriptorFile $module.File
                    if ($DryRun) {
                        $action = if ($entrySpec.Type -eq 'Script') { 'Run PowerShell script' } else { 'Run PowerShell' }
                        Write-Host "  [DRY RUN] $action`: $($entrySpec.DisplayValue)"
                        $results += [pscustomobject] @{ Item = $entrySpec.DisplayValue; Type = $entrySpec.Type; Success = $true; ExitCode = $null }
                        continue
                    }
                    if ($entrySpec.Type -eq 'Script') {
                        if (-not (Test-Path -LiteralPath $entrySpec.FilePath -PathType Leaf)) {
                            throw "Child script was not found: $($entrySpec.FilePath)"
                        }
                        $scriptArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $entrySpec.FilePath) + [string[]] $entrySpec.Arguments
                        $childOutput = @(
                            & (Get-GmrWindowsPowerShellPath) @scriptArguments 2>&1 |
                                ForEach-Object {
                                    Write-Host ([string] $_)
                                    $_
                                }
                        )
                        $exitCode = $LASTEXITCODE
                        if ($exitCode -ne 0) {
                            $outputText = ($childOutput | ForEach-Object { [string] $_ }) -join [Environment]::NewLine
                            $underlyingMatch = [regex]::Match($outputText, '(?i)exit code\s+(-?\d+)')
                            if ($underlyingMatch.Success) {
                                $underlyingExitCode = $underlyingMatch.Groups[1].Value
                                throw "Child script exited with code $exitCode (underlying command exit code $underlyingExitCode)."
                            }
                            throw "Child script exited with code $exitCode."
                        }
                    }
                    elseif ($entrySpec.Type -eq 'PowerShell') {
                        & ([scriptblock]::Create($entrySpec.Value)) 2>&1 |
                            ForEach-Object { Write-Host ([string] $_) }
                    }
                    else {
                        throw "PowerShell entries cannot run $($entrySpec.Type): $($entry.Command)"
                    }
                    $results += [pscustomobject] @{ Item = $entrySpec.DisplayValue; Type = $entrySpec.Type; Success = $?; ExitCode = $null }
                }
                catch {
                    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                    $failureExitCode = if ($null -ne $exitCode) { $exitCode } else { $null }
                    if ($null -ne $underlyingExitCode) {
                        $failureExitCode = $underlyingExitCode
                    }
                    $results += [pscustomobject] @{ Item = $entry.Value; Type = 'PowerShell'; Success = $false; ExitCode = $failureExitCode }
                }
                continue
            }
            try {
                $packageSpec = Get-WingetPackageSpec -Entry $entry
                $wingetArguments = @('install') + $packageSpec.Arguments
                if ($script:UseWingetVerbose) {
                    $wingetArguments += '--verbose'
                }
                if ($DryRun) {
                    $preview = @($wingetArguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ }) -join ' '
                    Write-Host "  [DRY RUN] winget $preview"
                    $results += [pscustomobject] @{ Item = $packageSpec.DisplayName; Type = 'WinGet'; Success = $true; ExitCode = $null }
                    continue
                }
                Write-Host "  winget install $($packageSpec.DisplayName)"
                if ($null -eq $wingetCommand) {
                    throw 'winget.exe was not found.'
                }

                if (Test-GmrWingetPackageInstalled -WingetCommand $wingetCommand -PackageSpec $packageSpec) {
                    Set-GmrEntryInstallStatus -Entry $entry -Status 4
                    Write-Host "  Warning: $($packageSpec.DisplayName) is already installed; skipping." -ForegroundColor Yellow
                    $results += [pscustomobject] @{
                        Item = $packageSpec.DisplayName
                        Type = 'WinGet'
                        Success = $true
                        ExitCode = 0
                    }
                    continue
                }

                Set-GmrEntryInstallStatus -Entry $entry -Status 1
                Set-GmrEntryInstallStatus -Entry $entry -Status 2
                & $wingetCommand.Source @wingetArguments 2>&1 |
                    ForEach-Object { Write-Host ([string] $_) }
                $exitCode = $LASTEXITCODE
                if ($exitCode -ne 0) {
                    Write-Host "  Failed: winget exited with code $exitCode." -ForegroundColor Red
                }
                else {
                    Set-GmrEntryInstallStatus -Entry $entry -Status 3
                    if (Test-GmrWingetPackageInstalled -WingetCommand $wingetCommand -PackageSpec $packageSpec) {
                        Set-GmrEntryInstallStatus -Entry $entry -Status 4
                    }
                }
                $results += [pscustomobject] @{
                    Item = $packageSpec.DisplayName
                    Type = 'WinGet'
                    Success = $exitCode -eq 0
                    ExitCode = $exitCode
                }
            }
            catch {
                Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                $results += [pscustomobject] @{ Item = $entry.Value; Type = 'WinGet'; Success = $false; ExitCode = $null }
            }
            continue
        }

    }

    $summary = New-GmrExecutionSummary -Results $results
    if ($DryRun) {
        Write-Host "Dry run complete: $($results.Count) item(s) would be processed." -ForegroundColor Yellow
    }
    Write-GmrExecutionSummary -Summary $summary
    return $summary
}




function Start-GmrBeta {
    param([switch] $Clean)

    Clear-Host
    $script:GmrState.SelectionTouched = $false
    $descriptorFiles = @(
        Get-ChildItem -LiteralPath $script:GmrRootDirectory -File |
            Where-Object { $_.Extension -ieq '.gmr' } |
            Sort-Object Name
    )
    if ($descriptorFiles.Count -eq 0) {
        Write-Host ("No .gmr files found in '{0}'." -f $script:GmrRootDirectory) -ForegroundColor Yellow
        return
    }

    $modules = [object[]] @($descriptorFiles | ForEach-Object { Get-GmrDescriptor -File $_ -Clean:$Clean } | Where-Object { -not $_.Hidden } | Sort-Object SortIndex, @{ Expression = { $_.File.Name } })
    Restore-GmrStateSelections -Modules $modules
    $script:GmrState.StatePersistenceEnabled = $true
    $theme = New-TuiTheme -AccentColor Cyan -BackgroundColor Black
    $backgroundRgb = '#0D1117'
    $textRgb = '#B8B8B8'
    $selectedTextRgb = '#F8F4F4'
    $dimRgb = '#808080'
    $accentRgb = '#4E8275'
    [void] (Set-TuiThemeStyle -Theme $theme -Element Title -ForegroundColor '#FFFFFF' -BackgroundColor $backgroundRgb -Bold $true)
    [void] (Set-TuiThemeStyle -Theme $theme -Element TitleDetail -ForegroundColor $textRgb -BackgroundColor $backgroundRgb -Bold $true)
    [void] (Set-TuiThemeStyle -Theme $theme -Element MenuItem -ForegroundColor $textRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element SelectedMenuItem -ForegroundColor $selectedTextRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element ActiveMenuItem -ForegroundColor '#FFFFFF' -BackgroundColor $accentRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element MenuItemPrefix -ForegroundColor $accentRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element Footer -ForegroundColor $dimRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element Toolbar -ForegroundColor $dimRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element ToolbarShortcut -ForegroundColor $textRgb -BackgroundColor $backgroundRgb -Bold $true)
    [void] (Set-TuiThemeStyle -Theme $theme -Element Border -ForegroundColor $accentRgb -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element DialogText -ForegroundColor '#FFFFFF' -BackgroundColor $backgroundRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element ActiveDialogChoice -ForegroundColor '#FFFFFF' -BackgroundColor $accentRgb)
    [void] (Set-TuiThemeStyle -Theme $theme -Element Other -ForegroundColor $textRgb -BackgroundColor $backgroundRgb)
    $mainMenu = New-GmrMainMenu -Modules $modules

    while ($true) {
        while ($true) {
            $mainResult = Show-TuiMenu -Menu $mainMenu -Theme $theme
        if ($mainResult.ItemId -eq 'continue') { break }
            if ($mainResult.ItemId -eq 'quit' -or $mainResult.ClosedReason -eq 'Escape') {
                if (Confirm-GmrAbort -Modules $modules -Theme $theme) { return }
            }
        }

        $createRestorePoint = $false
    $executionMenu = New-GmrExecutionMenu -CreateRestorePoint ([ref] $createRestorePoint)
    while ($true) {
        $executionResult = Show-TuiMenu -Menu $executionMenu -Theme $theme
        if ($executionResult.ItemId -in @('proceed-dry-run', 'proceed')) {
            $dryRun = $executionResult.ItemId -eq 'proceed-dry-run'
            $message = if ($dryRun) {
                'Run the selected commands in dry-run mode?'
            }
            else { 'Run the selected commands now?' }
            if (Show-TuiConfirmDialog -Title 'Proceed?' -Message $message -DefaultChoice No -Theme $theme) {
                $selectedEntries = Get-GmrSelectedEntries -Modules $modules
                $elevatedEntries = @($selectedEntries | Where-Object { $_.Entry.RequiresElevation })
                $regularEntries = @($selectedEntries | Where-Object { -not $_.Entry.RequiresElevation })

                $sessionResults = @()
                if ($dryRun) {
                    $dryRunSummary = Invoke-GmrSelectedCommands -DryRun $true -CreateRestorePoint $createRestorePoint -SelectedEntries $selectedEntries
                    $sessionResults += @($dryRunSummary.Results)
                }
                else {
                    if ($elevatedEntries.Count -gt 0 -or $createRestorePoint) {
                        $elevatedSummary = Start-GmrElevatedWorker -SelectedEntries $elevatedEntries -CreateRestorePoint $createRestorePoint
                        $sessionResults += @($elevatedSummary.Results)
                    }
                    if ($regularEntries.Count -gt 0) {
                        $regularSummary = Invoke-GmrSelectedCommands -DryRun $false -CreateRestorePoint $false -SelectedEntries $regularEntries
                        $sessionResults += @($regularSummary.Results)
                    }
                }
                $sessionSummary = New-GmrExecutionSummary -Results $sessionResults
                Write-GmrExecutionSummary -Summary $sessionSummary -Label 'Session complete'
                return 'Quit'
            }
            continue
        }
        if ($executionResult.ItemId -eq 'quit' -or $executionResult.ClosedReason -eq 'Escape') {
            if (Confirm-GmrAbort -Modules $modules -Theme $theme) { return }
            }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $gmrResult = $null
    $transcriptStarted = $false
    $workerFailed = $false
    try {
        $transcriptSuffix = if ([string]::IsNullOrWhiteSpace($ElevatedWorkerFile)) { '' } else { '-elevated' }
        [void] (Start-GmrTranscript -Suffix $transcriptSuffix)
        $transcriptStarted = $true
        if (-not [string]::IsNullOrWhiteSpace($ElevatedWorkerFile)) {
            $workerWriter = $null
            try {
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                $workerWriter = New-Object System.IO.StreamWriter($ElevatedWorkerOutputFile, $false, $utf8NoBom)
                & {
                    Invoke-GmrElevatedWorker -WorkerFile $ElevatedWorkerFile -ResultFile $ElevatedWorkerResultFile
                } *>&1 | ForEach-Object {
                    $workerWriter.WriteLine([string] $_)
                    $workerWriter.Flush()
                }
                $workerFailed = $script:GmrWorkerFailed
            }
            catch {
                $workerFailed = $true
                if ($null -ne $workerWriter) {
                    $workerWriter.WriteLine("Elevated worker failed: $($_.Exception.Message)")
                    $workerWriter.Flush()
                }
            }
            finally {
                if ($null -ne $workerWriter) {
                    $workerWriter.Dispose()
                }
            }
        }
        else {
            $gmrResult = Start-GmrBeta -Clean:$Clean
        }
    }
    finally {
        if ($transcriptStarted) {
            Stop-Transcript | Out-Null
        }
    }

    if ($workerFailed) {
        exit 1
    }
}
