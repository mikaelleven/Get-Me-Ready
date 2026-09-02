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
    [string] $ElevatedSelectionPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:UseWingetVerbose = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']
Clear-Host

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
$script:GmrState = [pscustomobject] @{ SelectionTouched = $false }

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
    return [pscustomobject] @{ DisplayName = $packageName; Arguments = [string[]] $arguments }
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
    if ([string]::IsNullOrWhiteSpace($command)) { throw "A .gmr entry command cannot be empty: $Line" }

    $title = $null
    $titleMatch = [regex]::Match($prefixText, '(?<quote>["''])(?<title>.*?)\k<quote>')
    if ($titleMatch.Success) {
        $title = $titleMatch.Groups['title'].Value
        $prefixText = $prefixText.Remove($titleMatch.Index, $titleMatch.Length)
    }
    $prefixText = $prefixText.Replace(':', ' ').Trim()
    $prefixTokens = if ([string]::IsNullOrWhiteSpace($prefixText)) { @() } else { [string[]] @(Split-GmrCommandLine -CommandLine $prefixText) }
    $entryType = if ($operator -in @('$>', 'PS>')) { 'PowerShell' } else { 'Winget' }
    $wingetSelector = if ($command.TrimStart().StartsWith('"')) { 'name' } else { 'id' }
    $wingetSource = 'winget'
    $wingetExact = $true
    $requiresElevation = $false
    foreach ($prefix in $prefixTokens) {
        switch -Regex ($prefix) {
            '^\?$' { $DefaultEnabled = $false; continue }
            '^!$' { $Mandatory = $true; continue }
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
        $entries.Add([pscustomobject] @{
            Value = $record.Value
            Command = $record.Command
            Type = $record.Type
            WingetSelector = $record.WingetSelector
            WingetSource = $record.WingetSource
            WingetExact = $record.WingetExact
            DisplayName = $displayName
            DefaultEnabled = [bool] $record.DefaultEnabled
            Mandatory = [bool] $record.Mandatory
            RequiresElevation = [bool] $record.RequiresElevation
            Enabled = $false
            MenuItem = $null
        })
    }

    $module = [pscustomobject] @{
        File = $File
        Type = '.gmr'
        FriendlyName = $friendlyName
        DisplayName = if ($hasFriendlyName) { $friendlyName } else { $File.Name }
        Entries = [object[]] $entries.ToArray()
        Required = $required
        Selected = $selected
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

function Get-GmrEntryLabel {
    param([Parameter(Mandatory = $true)][object] $Entry)
    $requiredSuffix = if (Test-GmrEntryMandatory -Entry $Entry) { ' [required]' } else { '' }
    return '{0} {1}{2}' -f (Get-GmrCheckbox -Checked $Entry.Enabled), $Entry.DisplayName, $requiredSuffix
}

function Get-GmrModuleMode {
    param([Parameter(Mandatory = $true)][object] $Module)

    $selectedCount = @($Module.Entries | Where-Object Enabled).Count
    if ($selectedCount -eq 0 -and -not (Test-GmrModuleRequired -Module $Module)) { return 'None' }
    if ($selectedCount -eq $Module.Entries.Count) { return 'All' }
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

    $selectedCount = @($Module.Entries | Where-Object Enabled).Count
    $requiredSuffix = if (Test-GmrModuleRequired -Module $Module) { ' [required]' } else { '' }
    return '{0} {1} [{2}/{3}]{4}' -f `
        (Get-GmrModuleIndicator -Module $Module),
        $Module.DisplayName,
        $selectedCount,
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
    }
}

function Set-GmrModuleState {
    param(
        [Parameter(Mandatory = $true)][object] $Module,
        [Parameter(Mandatory = $true)][bool] $Enabled
    )

    $effectiveEnabled = $Enabled -or (Test-GmrModuleRequired -Module $Module)
    foreach ($entry in $Module.Entries) {
        $entry.Enabled = $effectiveEnabled -and ($entry.DefaultEnabled -or (Test-GmrEntryMandatory -Entry $entry))
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
        $gmrState = $script:GmrState
        $item.SpaceAction = {
            $gmrState.SelectionTouched = $true
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
                $mandatoryProperty = $moduleEntry.PSObject.Properties['Mandatory']
                $isMandatory = $null -ne $mandatoryProperty -and [bool]$mandatoryProperty.Value
                if ($isMandatory) { $moduleEntry.Enabled = $true }
                $requiredSuffix = if ($isMandatory) { ' [required]' } else { '' }
                $moduleEntry.MenuItem.Label = '{0} {1}{2}' -f `
                    $(if ($moduleEntry.Enabled) { '[x]' } else { '[ ]' }),
                    $moduleEntry.DisplayName,
                    $requiredSuffix
            }
            $moduleRequiredProperty = $Module.PSObject.Properties['Required']
            $moduleIsRequired = $null -ne $moduleRequiredProperty -and [bool]$moduleRequiredProperty.Value
            $selectedCount = @($Module.Entries | Where-Object Enabled).Count
            $Module.Enabled = $selectedCount -gt 0 -or $moduleIsRequired
            $moduleIndicator = if ($selectedCount -eq 0 -and -not $moduleIsRequired) { '[ ]' }
                elseif ($selectedCount -eq $Module.Entries.Count) { '[x]' }
                else { '[*]' }
            $moduleRequiredSuffix = if ($moduleIsRequired) { ' [required]' } else { '' }
            $Module.MenuItem.Label = '{0} {1} [{2}/{3}]{4}' -f `
                $moduleIndicator,
                $Module.DisplayName,
                $selectedCount,
                $Module.Entries.Count,
                $moduleRequiredSuffix
        }.GetNewClosure()
        $items.Add($item)
    }

    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    $Module.Menu = New-TuiMenu `
        -Title $Module.DisplayName `
        -Items $items.ToArray() `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
        -Toolbar 'Up/Down Select  Left/Right Column  Space Toggle  Enter Back  Esc Back'
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
        $gmrState = $script:GmrState
        $moduleRequiredProperty = $module.PSObject.Properties['Required']
        $moduleIsRequired = $null -ne $moduleRequiredProperty -and [bool]$moduleRequiredProperty.Value
        $item.SpaceAction = {
            $gmrState.SelectionTouched = $true
            $selectedCount = @($module.Entries | Where-Object Enabled).Count
            if ($moduleIsRequired -or $selectedCount -eq 0) {
                foreach ($moduleEntry in $module.Entries) {
                    $mandatoryProperty = $moduleEntry.PSObject.Properties['Mandatory']
                    $isMandatory = $null -ne $mandatoryProperty -and [bool]$mandatoryProperty.Value
                    $moduleEntry.Enabled = $moduleEntry.DefaultEnabled -or $isMandatory
                }
            }
            elseif ($selectedCount -lt $module.Entries.Count) {
                foreach ($moduleEntry in $module.Entries) {
                    $moduleEntry.Enabled = $true
                }
            }
            else {
                foreach ($moduleEntry in $module.Entries) { $moduleEntry.Enabled = $false }
            }
            foreach ($moduleEntry in $module.Entries) {
                $mandatoryProperty = $moduleEntry.PSObject.Properties['Mandatory']
                $isMandatory = $null -ne $mandatoryProperty -and [bool]$mandatoryProperty.Value
                $requiredSuffix = if ($isMandatory) { ' [required]' } else { '' }
                $moduleEntry.MenuItem.Label = '{0} {1}{2}' -f `
                    $(if ($moduleEntry.Enabled) { '[x]' } else { '[ ]' }),
                    $moduleEntry.DisplayName,
                    $requiredSuffix
            }
            $selectedCount = @($module.Entries | Where-Object Enabled).Count
            $module.Enabled = $selectedCount -gt 0 -or $moduleIsRequired
            $moduleIndicator = if ($selectedCount -eq 0 -and -not $moduleIsRequired) { '[ ]' }
                elseif ($selectedCount -eq $module.Entries.Count) { '[x]' }
                else { '[*]' }
            $moduleRequiredSuffix = if ($moduleIsRequired) { ' [required]' } else { '' }
            $module.MenuItem.Label = '{0} {1} [{2}/{3}]{4}' -f `
                $moduleIndicator,
                $module.DisplayName,
                $selectedCount,
                $module.Entries.Count,
                $moduleRequiredSuffix
        }.GetNewClosure()
        $items.Add($item)
    }
    $items.Add((New-TuiMenuItem -Id 'continue' -Label 'Continue' -Action { 'Continue' } -CloseAfterAction))
    $items.Add((New-TuiMenuItem -Id 'quit' -Label 'Quit' -Action { 'Quit' } -CloseAfterAction))

    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    return New-TuiMenu `
        -Title 'GetMeReady (beta)' `
        -TitleDetail ' - Created by Mikael Levén' `
        -Items $items.ToArray() `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
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

    $restoreItem = New-TuiMenuItem -Id 'restore-point' -Label '[x] Create restore point' -Action {}
    $gmrState = $script:GmrState
    $restoreItem.SpaceAction = {
        $gmrState.SelectionTouched = $true
        $CreateRestorePoint.Value = -not $CreateRestorePoint.Value
        $restoreItem.Label = '{0} Create restore point' -f $(if ($CreateRestorePoint.Value) { '[x]' } else { '[ ]' })
    }.GetNewClosure()

    $items = @(
        $restoreItem
        (New-TuiMenuItem -Id 'save-configuration' -Label 'Save configuration (not implemented)' -Action {})
        (New-TuiMenuItem -Id 'proceed-dry-run' -Label 'Proceed (dry-run)' -Action { 'DryRun' } -CloseAfterAction)
        (New-TuiMenuItem -Id 'proceed' -Label 'Proceed' -Action { 'Proceed' } -CloseAfterAction)
        (New-TuiMenuItem -Id 'quit' -Label 'Quit' -Action { 'Quit' } -CloseAfterAction)
    )
    $layout = Get-GmrMenuLayout -ItemCount $items.Count
    return New-TuiMenu `
        -Title 'Execution options' `
        -Items $items `
        -ColumnCount $layout.ColumnCount `
        -RowsPerColumn $layout.RowsPerColumn `
        -InitialSelectedIndex 1 `
        -Toolbar 'Up/Down Select  Space Toggle  Enter Select  Esc Quit'
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

function Start-GmrElevatedSelection {
    param(
        [Parameter(Mandatory = $true)][object[]] $SelectedEntries,
        [Parameter(Mandatory = $true)][bool] $CreateRestorePoint
    )

    $selectionPath = Join-Path ([System.IO.Path]::GetTempPath()) ('GMR-ElevatedSelection-{0}.clixml' -f [guid]::NewGuid().ToString('N'))
    [pscustomobject] @{ SelectedEntries = $SelectedEntries; CreateRestorePoint = $CreateRestorePoint } |
        Export-Clixml -LiteralPath $selectionPath -Force

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-ElevatedSelectionPath', $selectionPath)
    if ($script:UseWingetVerbose) { $arguments += '-Verbose' }
    $argumentLine = @($arguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ }) -join ' '
    try {
        $process = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -Verb RunAs -Wait -PassThru -ArgumentList $argumentLine
        if ($process.ExitCode -ne 0) {
            Write-Host "Elevated processing failed with exit code $($process.ExitCode)." -ForegroundColor Red
        }
    }
    catch {
        Remove-Item -LiteralPath $selectionPath -Force -ErrorAction SilentlyContinue
        Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-GmrSelectedCommands {
    param(
        [object[]] $Modules = @(),
        [Parameter(Mandatory = $true)][bool] $DryRun,
        [Parameter(Mandatory = $true)][bool] $CreateRestorePoint,
        [object[]] $SelectedEntries = @()
    )

    if ($SelectedEntries.Count -eq 0) {
        $SelectedEntries = @(
            foreach ($module in $Modules | Where-Object Enabled) {
                foreach ($entry in $module.Entries | Where-Object Enabled) {
                    [pscustomobject] @{ Module = $module; Entry = $entry }
                }
            }
        )
    }
    if ($SelectedEntries.Count -eq 0) {
        Write-Host 'Nothing was selected to run.' -ForegroundColor Yellow
        return
    }

    $requiresElevation = @($SelectedEntries | Where-Object {
        $elevationProperty = $_.Entry.PSObject.Properties['RequiresElevation']
        $null -ne $elevationProperty -and [bool] $elevationProperty.Value
    }).Count -gt 0
    if ($requiresElevation -and -not $DryRun -and -not (Test-GmrAdministrator)) {
        Write-Host 'Starting one elevated process for the selected UAC entries.' -ForegroundColor Cyan
        Start-GmrElevatedSelection -SelectedEntries $SelectedEntries -CreateRestorePoint $CreateRestorePoint
        return
    }

    if ($CreateRestorePoint) {
        if ($DryRun) { Write-Host '  [DRY RUN] Create Windows system restore point.' }
        else {
            try { New-GmrRestorePoint }
            catch {
                Write-Host "Restore point creation failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host 'Processing aborted; no commands were executed.' -ForegroundColor Red
                return
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
                        $scriptArguments = [string[]] $entrySpec.Arguments
                        if ($scriptArguments.Count -gt 0) {
                            & $entrySpec.FilePath @scriptArguments
                        }
                        else {
                            & $entrySpec.FilePath
                        }
                    }
                    elseif ($entrySpec.Type -eq 'PowerShell') {
                        & ([scriptblock]::Create($entrySpec.Value))
                    }
                    else {
                        throw "PowerShell entries cannot run $($entrySpec.Type): $($entry.Command)"
                    }
                    $results += [pscustomobject] @{ Item = $entrySpec.DisplayValue; Type = $entrySpec.Type; Success = $?; ExitCode = $null }
                }
                catch {
                    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                    $results += [pscustomobject] @{ Item = $entry.Value; Type = 'PowerShell'; Success = $false; ExitCode = $null }
                }
                continue
            }
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
                Write-Host '  Failed: winget.exe was not found.' -ForegroundColor Red
                $results += [pscustomobject] @{ Item = $packageSpec.DisplayName; Type = 'WinGet'; Success = $false; ExitCode = $null }
                continue
            }
            & $wingetCommand.Source @wingetArguments
            $exitCode = $LASTEXITCODE
            $results += [pscustomobject] @{
                Item = $packageSpec.DisplayName
                Type = 'WinGet'
                Success = $exitCode -eq 0
                ExitCode = $exitCode
            }
            continue
        }

    }

    $failed = @($results | Where-Object { -not $_.Success })
    if ($DryRun) {
        Write-Host "Dry run complete: $($results.Count) item(s) would be processed." -ForegroundColor Yellow
    }
    else {
        Write-Host "Completed: $($results.Count - $failed.Count) succeeded, $($failed.Count) failed." -ForegroundColor $(
            if ($failed.Count -eq 0) { 'Green' } else { 'Yellow' }
        )
        if ($failed.Count -gt 0) { $failed | Format-Table Type, Item, ExitCode -AutoSize }
    }
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

    $modules = [object[]] @($descriptorFiles | ForEach-Object { Get-GmrDescriptor -File $_ -Clean:$Clean } | Sort-Object SortIndex, @{ Expression = { $_.File.Name } })
    $theme = New-TuiTheme -AccentColor Cyan -BackgroundColor Black
    [void] (Set-TuiThemeStyle -Theme $theme -Element Title -ForegroundColor White -Bold $true)
    [void] (Set-TuiThemeStyle -Theme $theme -Element TitleDetail -ForegroundColor Gray -Bold $true)
    $mainMenu = New-GmrMainMenu -Modules $modules

    while ($true) {
        $mainResult = Show-TuiMenu -Menu $mainMenu -Theme $theme
        if ($mainResult.ItemId -eq 'continue') { break }
        if ($mainResult.ItemId -eq 'quit' -or $mainResult.ClosedReason -eq 'Escape') {
            if (Confirm-GmrAbort -Modules $modules -Theme $theme) { return }
        }
    }

    $createRestorePoint = $true
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
                Invoke-GmrSelectedCommands `
                    -Modules $modules `
                    -DryRun $dryRun `
                    -CreateRestorePoint $createRestorePoint
                return
            }
            continue
        }
        if ($executionResult.ItemId -eq 'quit' -or $executionResult.ClosedReason -eq 'Escape') {
            if (Confirm-GmrAbort -Modules $modules -Theme $theme) { return }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not [string]::IsNullOrWhiteSpace($ElevatedSelectionPath)) {
        try {
            $elevatedSelection = Import-Clixml -LiteralPath $ElevatedSelectionPath
            Remove-Item -LiteralPath $ElevatedSelectionPath -Force -ErrorAction SilentlyContinue
            Invoke-GmrSelectedCommands `
                -DryRun $false `
                -CreateRestorePoint ([bool] $elevatedSelection.CreateRestorePoint) `
                -SelectedEntries ([object[]] $elevatedSelection.SelectedEntries)
        }
        catch {
            Write-Host "Elevated processing could not start: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Start-GmrBeta -Clean:$Clean
    }
}
