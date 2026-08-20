<#
OBSOLETE: This legacy launcher is retained for reference only. Use GMR.ps1.

#>

<#
AGENT INSTRUCTIONS

- This project is primarily used for Farming Simulator mods (Lua) and modding
  tools (Node.js/JavaScript or Python).
- Prefer Python for helper scripts and everyday automation tools.
- The owner has extensive C# and .NET experience.
- Communicate directly, with minimal explanation and a strong task focus.
- Preserve compatibility with Windows PowerShell 5.1 unless requirements state
  otherwise.
#>

<#
.SYNOPSIS
    Selects and installs groups of WinGet packages and runs groups of child
    PowerShell scripts.

.DESCRIPTION
    Descriptor files are discovered beside this script:

      *.gmr  - One WinGet package ID per non-empty, non-comment line. A line
               beginning with "PS>" runs the referenced PowerShell script.
      *.gmrs - One PowerShell script path/one-liner, executable command, batch
               file, or website URL per non-empty, non-comment line. Relative
               .ps1/.cmd/.bat/.exe paths resolve from the descriptor's directory.
               Bare www. URLs use HTTPS.

    Optional descriptor metadata:

      # cn: unique-canonical-name
      # name: User-friendly variant name
      # sortindex: numeric menu order (lower values first)
      # include: relative-or-absolute-path-to-another.gmr

    Files sharing a canonical name are presented as mutually exclusive variants.
    Included .gmr files are expanded recursively into the including package.
    All choices are collected before installation or script execution starts.

.PARAMETER DryRun
    Collects the normal selections and previews the WinGet commands and child
    scripts without executing them.

.PARAMETER CreateRestorePoint
    Creates a Windows system restore point after selection and before executing
    any WinGet packages or child scripts. When omitted, the user is asked during
    selection. Pass -CreateRestorePoint or -CreateRestorePoint:$false to override
    the interactive choice. Creation requires an elevated PowerShell session.

.PARAMETER Verbose
    Displays descriptor contents below each option during package selection.

.EXAMPLE
    .\GMR.ps1 -DryRun

.EXAMPLE
    .\GMR.ps1 -CreateRestorePoint

.EXAMPLE
    .\GMR.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [switch] $DryRun,
    [switch] $CreateRestorePoint
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$showVerboseSelection = $PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']

$rootDirectory = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($rootDirectory)) {
    $rootDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Get-GmrPackageEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [string[]] $IncludeChain = @()
    )

    $fullPath = [System.IO.Path]::GetFullPath($FilePath)
    if ($IncludeChain -contains $fullPath) {
        $cycle = (@($IncludeChain) + $fullPath) -join ' -> '
        throw "Circular .gmr include detected: $cycle"
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Included .gmr file was not found: $fullPath"
    }

    if ([System.IO.Path]::GetExtension($fullPath) -ine '.gmr') {
        throw "Only .gmr files can be included: $fullPath"
    }

    $entries = New-Object 'System.Collections.Generic.List[string]'
    $currentChain = @($IncludeChain) + $fullPath

    foreach ($line in @(Get-Content -LiteralPath $fullPath)) {
        if ($line -match '^\s*#\s*include\s*:\s*(.+?)\s*$') {
            $includePath = [Environment]::ExpandEnvironmentVariables($Matches[1].Trim().Trim('"').Trim("'"))
            if (-not [System.IO.Path]::IsPathRooted($includePath)) {
                $includePath = Join-Path -Path ([System.IO.Path]::GetDirectoryName($fullPath)) -ChildPath $includePath
            }

            foreach ($includedEntry in @(Get-GmrPackageEntries -FilePath $includePath -IncludeChain $currentChain)) {
                $entries.Add($includedEntry)
            }
        }
        elseif ($line -notmatch '^\s*(#|$)') {
            $entry = $line.Trim()
            if ($entry -match '^\?\>\s*(.+?)\s*$') {
                $entry = $Matches[1]
            }
            elseif ($entry -match '^\?\s+(PS>\s*.+?)\s*$') {
                $entry = $Matches[1]
            }
            $entries.Add($entry)
        }
    }

    return $entries.ToArray()
}

function Split-GmrCommandLine {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CommandLine
    )

    $arguments = New-Object 'System.Collections.Generic.List[string]'
    $current = New-Object System.Text.StringBuilder
    $quote = [char]0
    $tokenStarted = $false

    for ($index = 0; $index -lt $CommandLine.Length; $index++) {
        $character = $CommandLine[$index]

        if ($quote -ne [char]0) {
            if ($character -eq $quote) {
                $quote = [char]0
            }
            else {
                [void]$current.Append($character)
            }
            continue
        }

        if ($character -eq '"' -or $character -eq "'") {
            $quote = $character
            $tokenStarted = $true
        }
        elseif ([char]::IsWhiteSpace($character)) {
            if ($tokenStarted) {
                $arguments.Add($current.ToString())
                [void]$current.Clear()
                $tokenStarted = $false
            }
        }
        else {
            [void]$current.Append($character)
            $tokenStarted = $true
        }
    }

    if ($quote -ne [char]0) {
        throw "Unterminated quotation mark in command line: $CommandLine"
    }

    if ($tokenStarted) {
        $arguments.Add($current.ToString())
    }

    return $arguments.ToArray()
}

function Get-WingetPackageSpec {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Entry
    )

    $inputArguments = [string[]]@(Split-GmrCommandLine -CommandLine $Entry)
    if ($inputArguments.Count -eq 0) {
        throw 'A WinGet package entry cannot be empty.'
    }

    $packageName = $inputArguments[0]
    if ($packageName -match '^-') {
        throw "Unable to determine the package name in WinGet entry: $Entry"
    }

    $selector = if ($Entry -match '^\s*"') { '--name' } else { '--id' }
    $source = 'winget'
    $useExact = $true
    $customArguments = New-Object 'System.Collections.Generic.List[string]'

    for ($index = 1; $index -lt $inputArguments.Count; $index++) {
        $argument = $inputArguments[$index]
        $optionName = ($argument -split '=', 2)[0]

        if ($argument -ieq 'fuzzy' -or $argument -ieq '--fuzzy') {
            $useExact = $false
            continue
        }

        if ($argument -ieq '--exact' -or $argument -in @('--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')) {
            continue
        }

        if ($optionName -in @('-s', '--source')) {
            if ($argument -match '=') {
                $source = ($argument -split '=', 2)[1]
            }
            elseif ($index + 1 -lt $inputArguments.Count) {
                $index++
                $source = $inputArguments[$index]
            }
            else {
                throw "WinGet source is missing a value in entry: $Entry"
            }
            continue
        }

        [void]$customArguments.Add($argument)
    }

    $arguments = @($selector, $packageName) + $customArguments.ToArray()
    if ($useExact) {
        $arguments += '--exact'
    }
    $arguments += @('--source', $source, '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')

    [PSCustomObject]@{
        DisplayName = $packageName
        Arguments   = [string[]]$arguments
    }
}

function Format-GmrCommandArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Argument
    )

    if ($Argument -match '[\s"]') {
        return '"{0}"' -f ($Argument -replace '"', '\"')
    }

    return $Argument
}

function Get-GmrSpecialScriptEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Entry
    )

    if ($Entry -match '^PS>\s*(.+?)\s*$') {
        return $Matches[1]
    }

    return $null
}

function Get-GmrDescriptor {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $File
    )

    $lines = @(Get-Content -LiteralPath $File.FullName)
    $canonicalName = $null
    $friendlyName = $null
    $sortIndex = [int]::MaxValue

    foreach ($line in $lines) {
        if (-not $canonicalName -and $line -match '^\s*#\s*cn\s*:\s*(.+?)\s*$') {
            $canonicalName = $Matches[1].Trim()
        }
        elseif (-not $friendlyName -and $line -match '^\s*#\s*name\s*:\s*(.+?)\s*$') {
            $friendlyName = $Matches[1].Trim()
        }
        elseif ($line -match '^\s*#\s*sortindex\s*:\s*(\d+)\s*$') {
            $sortIndex = [int]$Matches[1]
        }
    }

    $hasFriendlyName = -not [string]::IsNullOrWhiteSpace($friendlyName)
    if (-not $hasFriendlyName) {
        $friendlyName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    }

    $entries = @(
        if ($File.Extension -ieq '.gmr') {
            Get-GmrPackageEntries -FilePath $File.FullName
        }
        else {
            $lines |
                Where-Object { $_ -notmatch '^\s*(#|$)' } |
                ForEach-Object { $_.Trim() }
        }
    )

    $groupKey = if ([string]::IsNullOrWhiteSpace($canonicalName)) {
        'file:{0}' -f $File.FullName
    }
    else {
        'cn:{0}' -f $canonicalName
    }

    [PSCustomObject]@{
        File          = $File
        Type          = $File.Extension.ToLowerInvariant()
        CanonicalName = $canonicalName
        FriendlyName  = $friendlyName
        DisplayName   = if ($hasFriendlyName) { $friendlyName } else { $File.Name }
        Entries       = [string[]]$entries
        GroupKey      = $groupKey
        SortIndex     = $sortIndex
    }
}

function Read-VariantSelection {
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $Variants,

        [switch] $ShowDetails
    )

    $canonicalName = $Variants[0].CanonicalName
    $heading = if ([string]::IsNullOrWhiteSpace($canonicalName)) {
        $Variants[0].FriendlyName
    }
    else {
        $canonicalName
    }

    Write-Host ''
    Write-Host ('Select package: {0}' -f $heading) -ForegroundColor Cyan
    Write-Host '  [0] None'

    for ($index = 0; $index -lt $Variants.Count; $index++) {
        $variant = $Variants[$index]
        Write-Host ('  [{0}] {1}' -f ($index + 1), $variant.DisplayName)

        if ($ShowDetails) {
            if ($variant.Type -eq '.gmr') {
                $detailItems = @(
                    $variant.Entries | ForEach-Object {
                        $specialScript = Get-GmrSpecialScriptEntry -Entry $_
                        if ($null -ne $specialScript) {
                            'PS> {0}' -f (Get-GmrsEntrySpec -Entry $specialScript -DescriptorFile $variant.File).DisplayValue
                        }
                        else {
                            (Get-WingetPackageSpec -Entry $_).DisplayName
                        }
                    }
                )
            }
            else {
                $detailItems = @(
                    $variant.Entries | ForEach-Object {
                        $entrySpec = Get-GmrsEntrySpec -Entry $_ -DescriptorFile $variant.File
                        switch ($entrySpec.Type) {
                            'Script' { [System.IO.Path]::GetFileNameWithoutExtension($entrySpec.DisplayValue) }
                            'URL' { $entrySpec.DisplayValue }
                            default { $entrySpec.DisplayValue }
                        }
                    }
                )
            }

            $detailText = if ($detailItems.Count -eq 0) {
                '(no entries)'
            }
            else {
                $detailItems -join ', '
            }
            Write-Host ('      {0}' -f $detailText) -ForegroundColor DarkGray
        }
    }

    while ($true) {
        $answer = Read-Host ('Choose 0-{0}' -f $Variants.Count)
        if ($null -eq $answer) {
            throw 'Interactive input is unavailable. Run GMR.ps1 from an interactive PowerShell session.'
        }

        $selection = 0
        if ([int]::TryParse($answer, [ref]$selection) -and
            $selection -ge 0 -and
            $selection -le $Variants.Count) {
            if ($selection -eq 0) {
                return $null
            }

            return $Variants[$selection - 1]
        }

        Write-Host 'Invalid selection.' -ForegroundColor Yellow
    }
}

function Read-RestorePointSelection {
    Write-Host ''
    Write-Host 'Create a Windows system restore point before execution?' -ForegroundColor Cyan
    Write-Host '  [0] No'
    Write-Host '  [1] Yes'

    while ($true) {
        $answer = Read-Host 'Choose 0-1'
        if ($null -eq $answer) {
            throw 'Interactive input is unavailable. Run GMR.ps1 from an interactive PowerShell session.'
        }

        $selection = 0
        if ([int]::TryParse($answer, [ref]$selection) -and $selection -in @(0, 1)) {
            return $selection -eq 1
        }

        Write-Host 'Invalid selection.' -ForegroundColor Yellow
    }
}

function Read-ProceedConfirmation {
    while ($true) {
        $answer = Read-Host 'Proceed? (Y/N)'
        if ($null -eq $answer) {
            throw 'Interactive input is unavailable. Run GMR.ps1 from an interactive PowerShell session.'
        }

        switch ($answer.Trim().ToLowerInvariant()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            default { Write-Host 'Enter Y or N.' -ForegroundColor Yellow }
        }
    }
}

function Resolve-ChildScriptPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Entry,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $DescriptorFile
    )

    $path = [Environment]::ExpandEnvironmentVariables($Entry.Trim().Trim('"').Trim("'"))
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        $path = Join-Path -Path $DescriptorFile.DirectoryName -ChildPath $path
    }

    $resolvedPath = (Resolve-Path -LiteralPath $path -ErrorAction Stop).ProviderPath
    if ([System.IO.Path]::GetExtension($resolvedPath) -ine '.ps1') {
        throw "Child script is not a .ps1 file: $resolvedPath"
    }

    return $resolvedPath
}

function Get-GmrsEntrySpec {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Entry,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $DescriptorFile
    )

    $value = $Entry.Trim()
    $unquotedValue = $value.Trim('"').Trim("'")

    if ($unquotedValue -match '(?i)^https?://\S+$') {
        return [PSCustomObject]@{ Type = 'URL'; Value = $unquotedValue; DisplayValue = $unquotedValue }
    }

    if ($unquotedValue -match '(?i)^www\.\S+$') {
        $url = 'https://{0}' -f $unquotedValue
        return [PSCustomObject]@{ Type = 'URL'; Value = $url; DisplayValue = $url }
    }

    $commandParts = [string[]]@(Split-GmrCommandLine -CommandLine $value)
    if ($commandParts.Count -gt 0) {
        $commandName = [Environment]::ExpandEnvironmentVariables($commandParts[0])
        $commandExtension = [System.IO.Path]::GetExtension($commandName).ToLowerInvariant()

        if ($commandExtension -in @('.ps1', '.cmd', '.bat', '.exe')) {
            $arguments = if ($commandParts.Count -gt 1) {
                [string[]]$commandParts[1..($commandParts.Count - 1)]
            }
            else {
                [string[]]@()
            }

            $resolvedCommand = $commandName
            if (-not [System.IO.Path]::IsPathRooted($resolvedCommand)) {
                $localCommand = Join-Path -Path $DescriptorFile.DirectoryName -ChildPath $resolvedCommand
                if ((Test-Path -LiteralPath $localCommand -PathType Leaf) -or
                    $resolvedCommand.IndexOfAny([char[]]@('\', '/')) -ge 0) {
                    $resolvedCommand = $localCommand
                }
            }

            if ([System.IO.Path]::IsPathRooted($resolvedCommand)) {
                $resolvedCommand = [System.IO.Path]::GetFullPath($resolvedCommand)
            }

            $displayParts = @(
                Format-GmrCommandArgument -Argument $resolvedCommand
                $arguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ }
            )
            $type = if ($commandExtension -eq '.ps1') { 'Script' } else { 'Executable' }
            return [PSCustomObject]@{
                Type         = $type
                Value        = $commandName
                FilePath     = $resolvedCommand
                Arguments    = $arguments
                DisplayValue = $displayParts -join ' '
            }
        }
    }

    return [PSCustomObject]@{ Type = 'PowerShell'; Value = $value; DisplayValue = $value }
}

function New-GmrRestorePoint {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdministrator) {
        throw 'Creating a restore point requires an elevated PowerShell session. Run GMR.ps1 as Administrator.'
    }

    $checkpointCommand = Get-Command -Name 'Checkpoint-Computer' -ErrorAction SilentlyContinue
    if ($null -eq $checkpointCommand) {
        throw 'Checkpoint-Computer is unavailable on this system.'
    }

    $description = 'GMR setup - {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ('Creating restore point: {0}' -f $description) -ForegroundColor Cyan
    Checkpoint-Computer -Description $description -RestorePointType 'MODIFY_SETTINGS'
    Write-Host 'Restore point created.' -ForegroundColor Green
}

$descriptorFiles = @(
    Get-ChildItem -LiteralPath $rootDirectory -File |
        Where-Object { $_.Extension -in @('.gmr', '.gmrs') } |
        Sort-Object Name
)

if ($descriptorFiles.Count -eq 0) {
    Write-Host "No .gmr or .gmrs files found in '$rootDirectory'." -ForegroundColor Yellow
    return
}

$descriptors = @($descriptorFiles | ForEach-Object { Get-GmrDescriptor -File $_ } | Sort-Object SortIndex, @{ Expression = { $_.File.Name } })
$groups = @($descriptors | Group-Object -Property GroupKey)
$selectedDescriptors = @()

Write-Host ('Found {0} setup descriptor(s) in {1}' -f $descriptors.Count, $rootDirectory)
Write-Host 'Make all selections now. No further GMR input will be requested.'

foreach ($group in $groups) {
    $variants = @($group.Group | Sort-Object SortIndex, FriendlyName, @{ Expression = { $_.File.Name } })
    $selected = Read-VariantSelection -Variants $variants -ShowDetails:$showVerboseSelection
    if ($null -ne $selected) {
        $selectedDescriptors += $selected
    }
}

$shouldCreateRestorePoint = if ($PSBoundParameters.ContainsKey('CreateRestorePoint')) {
    [bool]$CreateRestorePoint
}
else {
    Read-RestorePointSelection
}

Write-Host ''
Write-Host 'Execution summary' -ForegroundColor Cyan
Write-Host 'Selected packages:'
if ($selectedDescriptors.Count -eq 0) {
    Write-Host '  (none)' -ForegroundColor Yellow
}
else {
    foreach ($descriptor in $selectedDescriptors) {
        Write-Host ('  - {0}' -f $descriptor.DisplayName)
    }
}

$restorePointLabel = if ($shouldCreateRestorePoint) { 'Yes' } else { 'No' }
Write-Host ('Restore point: {0}' -f $restorePointLabel)
Write-Host ''

if (-not (Read-ProceedConfirmation)) {
    Write-Host 'Cancelled. No changes were made.' -ForegroundColor Yellow
    return
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Selection complete. Starting dry run; no changes will be made.' -ForegroundColor Yellow
}
else {
    Write-Host 'Selection complete. Starting unattended processing.' -ForegroundColor Green
}

if ($selectedDescriptors.Count -eq 0) {
    Write-Host 'Nothing was selected to run.' -ForegroundColor Yellow
    return
}

if ($shouldCreateRestorePoint) {
    if ($DryRun) {
        Write-Host '  [DRY RUN] Create Windows system restore point.'
    }
    else {
        try {
            New-GmrRestorePoint
        }
        catch {
            Write-Host ('Restore point creation failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
            Write-Host 'Processing aborted; no packages or child scripts were executed.' -ForegroundColor Red
            return
        }
    }
}

$results = @()
$wingetCommand = Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue

foreach ($descriptor in $selectedDescriptors) {
    Write-Host ''
    Write-Host ('Processing {0} ({1})' -f $descriptor.FriendlyName, $descriptor.File.Name) -ForegroundColor Cyan

    if ($descriptor.Entries.Count -eq 0) {
        Write-Host '  No entries found.' -ForegroundColor Yellow
        continue
    }

    if ($descriptor.Type -eq '.gmr') {
        foreach ($packageEntry in $descriptor.Entries) {
            $specialScript = Get-GmrSpecialScriptEntry -Entry $packageEntry
            if ($null -ne $specialScript) {
                try {
                    $entrySpec = Get-GmrsEntrySpec -Entry $specialScript -DescriptorFile $descriptor.File
                    if ($entrySpec.Type -ne 'Script') {
                        throw "PS> entries must reference a PowerShell script: $packageEntry"
                    }
                    if ($DryRun) {
                        Write-Host ('  [DRY RUN] Run PowerShell script: {0}' -f $entrySpec.DisplayValue)
                        $results += [PSCustomObject]@{ Item = $entrySpec.DisplayValue; Type = 'Script'; Success = $true; ExitCode = $null }
                        continue
                    }
                    if (-not (Test-Path -LiteralPath $entrySpec.FilePath -PathType Leaf)) {
                        throw "Child script was not found: $($entrySpec.FilePath)"
                    }
                    Write-Host ('  Running {0}' -f $entrySpec.DisplayValue)
                    if ($null -eq $entrySpec.Arguments -or $entrySpec.Arguments.Count -eq 0) {
                        & $entrySpec.FilePath
                    } else {
                        $scriptArguments = [string[]]$entrySpec.Arguments
                        & $entrySpec.FilePath @scriptArguments
                    }
                    $success = $?
                    $results += [PSCustomObject]@{ Item = $entrySpec.DisplayValue; Type = 'Script'; Success = $success; ExitCode = $null }
                }
                catch {
                    Write-Host ('  Failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
                    $results += [PSCustomObject]@{ Item = $packageEntry; Type = 'Script'; Success = $false; ExitCode = $null }
                }
                continue
            }
            $packageSpec = Get-WingetPackageSpec -Entry $packageEntry
            $packageName = $packageSpec.DisplayName
            $wingetArguments = @('install') + $packageSpec.Arguments
            if ($showVerboseSelection) {
                $wingetArguments += '--verbose'
            }

            if ($DryRun) {
                $previewArguments = @($wingetArguments | ForEach-Object { Format-GmrCommandArgument -Argument $_ })
                Write-Host ('  [DRY RUN] winget {0}' -f ($previewArguments -join ' '))
                $results += [PSCustomObject]@{ Item = $packageName; Type = 'WinGet'; Success = $true; ExitCode = $null }
                continue
            }

            Write-Host ('  winget install {0}' -f $packageName)

            if ($null -eq $wingetCommand) {
                Write-Host '  Failed: winget.exe was not found.' -ForegroundColor Red
                $results += [PSCustomObject]@{ Item = $packageName; Type = 'WinGet'; Success = $false; ExitCode = $null }
                continue
            }

            & $wingetCommand.Source @wingetArguments
            $exitCode = $LASTEXITCODE
            $success = $exitCode -eq 0
            $results += [PSCustomObject]@{ Item = $packageName; Type = 'WinGet'; Success = $success; ExitCode = $exitCode }

            if (-not $success) {
                Write-Host ('  Failed with exit code {0}.' -f $exitCode) -ForegroundColor Red
            }
        }
    }
    elseif ($descriptor.Type -eq '.gmrs') {
        foreach ($gmrsEntry in $descriptor.Entries) {
            try {
                $entrySpec = Get-GmrsEntrySpec -Entry $gmrsEntry -DescriptorFile $descriptor.File

                if ($DryRun) {
                    switch ($entrySpec.Type) {
                        'Script' { Write-Host ('  [DRY RUN] Run PowerShell script: {0}' -f $entrySpec.DisplayValue) }
                        'Executable' { Write-Host ('  [DRY RUN] Run executable: {0}' -f $entrySpec.DisplayValue) }
                        'URL' { Write-Host ('  [DRY RUN] Open website: {0}' -f $entrySpec.DisplayValue) }
                        default { Write-Host ('  [DRY RUN] Run PowerShell: {0}' -f $entrySpec.DisplayValue) }
                    }
                    $results += [PSCustomObject]@{ Item = $entrySpec.DisplayValue; Type = $entrySpec.Type; Success = $true; ExitCode = $null }
                    continue
                }

                $exitCode = $null
                switch ($entrySpec.Type) {
                    'Script' {
                        $childScriptPath = Resolve-ChildScriptPath -Entry $entrySpec.FilePath -DescriptorFile $descriptor.File
                        Write-Host ('  Running {0}' -f $childScriptPath)
                        $commandArguments = [string[]]$entrySpec.Arguments
                        & $childScriptPath @commandArguments
                        $success = $?
                    }
                    'Executable' {
                        Write-Host ('  Running executable: {0}' -f $entrySpec.DisplayValue)
                        $commandArguments = [string[]]$entrySpec.Arguments
                        & $entrySpec.FilePath @commandArguments
                        $invocationSucceeded = $?
                        $exitCode = $LASTEXITCODE
                        $success = $invocationSucceeded -and $exitCode -eq 0
                    }
                    'URL' {
                        Write-Host ('  Opening {0}' -f $entrySpec.Value)
                        Start-Process -FilePath $entrySpec.Value
                        $success = $?
                    }
                    default {
                        Write-Host ('  Running PowerShell: {0}' -f $entrySpec.Value)
                        $command = [scriptblock]::Create($entrySpec.Value)
                        & $command
                        $success = $?
                    }
                }

                $results += [PSCustomObject]@{ Item = $entrySpec.DisplayValue; Type = $entrySpec.Type; Success = $success; ExitCode = $exitCode }

                if (-not $success) {
                    Write-Host '  Entry reported an error.' -ForegroundColor Red
                }
            }
            catch {
                Write-Host ('  Failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
                $results += [PSCustomObject]@{ Item = $gmrsEntry; Type = 'GMRS'; Success = $false; ExitCode = $null }
            }
        }
    }
}

Write-Host ''
if ($results.Count -eq 0) {
    Write-Host 'Nothing was selected to run.' -ForegroundColor Yellow
    return
}

$failedResults = @($results | Where-Object { -not $_.Success })
$successfulCount = $results.Count - $failedResults.Count
if ($DryRun) {
    Write-Host ('Dry run complete: {0} item(s) would be processed.' -f $results.Count) -ForegroundColor Yellow
    return
}

Write-Host ('Completed: {0} succeeded, {1} failed.' -f $successfulCount, $failedResults.Count) -ForegroundColor $(
    if ($failedResults.Count -eq 0) { 'Green' } else { 'Yellow' }
)

if ($failedResults.Count -gt 0) {
    $failedResults | Format-Table Type, Item, ExitCode -AutoSize
}
