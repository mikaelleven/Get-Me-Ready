[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $RepositoryRoot,
    [string] $OutputPath = $null
)

$ErrorActionPreference = 'Stop'
$repositoryPath = if ([System.IO.Path]::IsPathRooted($RepositoryRoot)) {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $RepositoryRoot))
}
if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
    throw "Registry directory was not found: $repositoryPath"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repositoryPath 'ProgramCatalog.md'
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repositoryPath $OutputPath
}

$displayNameScript = Join-Path $PSScriptRoot 'GetMyWinReady\tools\Get-ProgramDisplayName.ps1'
if (-not (Test-Path -LiteralPath $displayNameScript -PathType Leaf)) {
    throw "Program display-name helper was not found: $displayNameScript"
}
. $displayNameScript

function Get-ProgramName {
    param([Parameter(Mandatory = $true)][string] $Entry)

    $value = $Entry.Trim()
    if ($value -match '^\?\>\s*(.+?)\s*$') { $value = $Matches[1] }
    elseif ($value -match '^\?\s+(.+?)\s*$') { $value = $Matches[1] }

    if ($value -match '^(?:"(?<double>[^"\r\n]+)"|''(?<single>[^''\r\n]+)'')\s*:\s*(?<command>.+)$') {
        return $(if ($Matches['double']) { $Matches['double'] } else { $Matches['single'] })
    }

    if ($value -match '^PS>\s*(.+?)\s*$') {
        $scriptName = Split-Path -Leaf ($Matches[1].Trim().Split(' ')[0])
        return Resolve-ProgramDisplayName -InputValue $scriptName -InputKind Script
    }

    if ($value -match '\.(ps1|cmd|bat|exe)(?:\s|$)' -or $value -match '^(https?://|www\.)') { return $null }

    $packageKey = ($value -split '\s+', 2)[0].Trim('"', "'")
    return Resolve-ProgramDisplayName -InputValue $packageKey -InputKind Package
}

$modules = @(
    Get-ChildItem -LiteralPath $repositoryPath -File |
        Where-Object { $_.Extension -in @('.gmr', '.gmrs') } |
        ForEach-Object {
            $lines = @(Get-Content -LiteralPath $_.FullName)
            $nameLine = ($lines | Where-Object { $_ -match '^\s*#\s*name\s*:\s*(.+?)\s*$' } | Select-Object -First 1)
            if ($null -eq $nameLine -or $nameLine -notmatch '^\s*#\s*name\s*:\s*(.+?)\s*$') { return }
            $moduleName = $Matches[1].Trim()
            $sortIndex = 1000
            $sort = ($lines | Where-Object { $_ -match '^\s*#\s*sortindex\s*:\s*(\d+)\s*$' } | Select-Object -First 1)
            if ($sort -match '(\d+)') { $sortIndex = [int]$Matches[1] }
            $programs = New-Object 'System.Collections.Generic.List[string]'
            foreach ($line in $lines) {
                if ($line -match '^\s*(#|$)') { continue }
                $programName = Get-ProgramName -Entry $line
                if (-not [string]::IsNullOrWhiteSpace($programName) -and -not $programs.Contains($programName)) {
                    [void]$programs.Add($programName)
                }
            }
            [pscustomobject]@{ Name = $moduleName; SortIndex = $sortIndex; Programs = $programs.ToArray() }
        } |
        Where-Object { $_.Programs.Count -gt 0 } |
        Sort-Object SortIndex, Name
)

$output = New-Object 'System.Collections.Generic.List[string]'
[void]$output.Add('# Programs installable with GetMeReady')
[void]$output.Add('')
[void]$output.Add('This file is generated best-effort from the entry keys and script paths in the GMR descriptors. Run `..\UpdateProgramCatalog.ps1 <registry>` after adding or renaming an installable program.')
[void]$output.Add('')
foreach ($module in $modules) {
    [void]$output.Add("## $($module.Name)")
    [void]$output.Add('')
    foreach ($program in $module.Programs) { [void]$output.Add("- $program") }
    [void]$output.Add('')
}
$output.RemoveAt($output.Count - 1)

$output | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Output (Get-Item -LiteralPath $OutputPath)
