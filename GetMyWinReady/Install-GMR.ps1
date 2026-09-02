<#
.SYNOPSIS
Downloads and starts the Windows GetMeReady registry.
#>
[CmdletBinding()]
param(
    [string] $InstallPath = (Join-Path $HOME 'GetMeReady'),

    [switch] $Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryArchiveUrl = 'https://github.com/mikaelleven/Get-Me-Ready/archive/refs/heads/master.zip'
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ("GetMeReady-" + [Guid]::NewGuid().ToString('N'))

if ((Test-Path -LiteralPath $InstallPath) -and -not $Force) {
    throw "Installation path already exists: $InstallPath. Choose another path or rerun with -Force."
}

try {
    New-Item -ItemType Directory -Path $temporaryPath -Force | Out-Null
    $archivePath = Join-Path $temporaryPath 'GetMeReady.zip'
    $expandedPath = Join-Path $temporaryPath 'expanded'

    Invoke-WebRequest -Uri $repositoryArchiveUrl -OutFile $archivePath -UseBasicParsing
    Expand-Archive -LiteralPath $archivePath -DestinationPath $expandedPath -Force

    $archiveRoot = Get-ChildItem -LiteralPath $expandedPath -Directory | Select-Object -First 1
    if ($null -eq $archiveRoot) {
        throw 'The downloaded GetMeReady archive did not contain a repository directory.'
    }

    $sourcePath = Join-Path $archiveRoot.FullName 'GetMyWinReady'
    $runnerPath = Join-Path $sourcePath 'GMR.ps1'
    if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
        throw "The downloaded archive did not contain the Windows runner: $runnerPath"
    }

    if (Test-Path -LiteralPath $InstallPath) {
        Remove-Item -LiteralPath $InstallPath -Recurse -Force
    }

    Copy-Item -LiteralPath $sourcePath -Destination $InstallPath -Recurse -Force
    Write-Host "GetMeReady was installed to $InstallPath."
    & (Join-Path $InstallPath 'GMR.ps1')
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}
