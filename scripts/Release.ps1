<#
.SYNOPSIS
Builds and publishes a versioned GetMeReady GitHub release.

.DESCRIPTION
Creates four ZIP archives: one containing all registries and one for each
platform registry. By default, the script increments VERSION, commits and
pushes that increment, then creates the matching GitHub release and uploads
all archives. Use -NoBump to publish the current VERSION without creating a
version-bump commit. GitHub CLI authentication is required for publishing.

Run with -PackageOnly to create and inspect the archives without changing
VERSION, Git history, tags, or GitHub.
#>
[CmdletBinding()]
param(
    [ValidateSet('Minor', 'Patch', 'Major')]
    [string] $Bump = 'Minor',

    [switch] $NoBump,

    [switch] $PackageOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-ExternalTool {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $output = @(& $FilePath @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $message = ($output | Out-String).Trim()
        throw "$FilePath $($Arguments -join ' ') failed with exit code $LASTEXITCODE. $message"
    }

    return $output
}

function Get-NextVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CurrentVersion,

        [Parameter(Mandatory = $true)]
        [string] $Increment
    )

    if ($CurrentVersion -notmatch '^(\d+)\.(\d+)\.(\d+)\.(\d+)$') {
        throw "VERSION must use four numeric components (for example 2.0.0.0), but was '$CurrentVersion'."
    }

    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $revision = [int]$Matches[4]

    switch ($Increment) {
        'Major' { $major++; $minor = 0; $patch = 0; $revision = 0 }
        'Minor' { $minor++; $patch = 0; $revision = 0 }
        'Patch' { $patch++; $revision = 0 }
        default { throw "Unsupported version increment: $Increment" }
    }

    return "$major.$minor.$patch.$revision"
}

function Copy-ReleaseDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPath
    )

    $excludedDirectoryNames = @('.agents', '.git', '.OLD')
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

    foreach ($item in Get-ChildItem -LiteralPath $SourcePath -Recurse -Force) {
        $relativePath = $item.FullName.Substring($SourcePath.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            continue
        }

        $pathParts = $relativePath -split '[\\/]'
        if (@($pathParts | Where-Object { $excludedDirectoryNames -contains $_ }).Count -gt 0) {
            continue
        }

        $targetPath = Join-Path $DestinationPath $relativePath
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
        else {
            $targetDirectory = Split-Path -Parent $targetPath
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
            Copy-Item -LiteralPath $item.FullName -Destination $targetPath -Force
        }
    }
}

function New-ReleaseArchive {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PackageRoot,

        [Parameter(Mandatory = $true)]
        [string] $ArchivePath
    )

    Compress-Archive -LiteralPath $PackageRoot -DestinationPath $ArchivePath -CompressionLevel Optimal -Force
    $archive = Get-Item -LiteralPath $ArchivePath
    if ($archive.Length -eq 0) {
        throw "Created archive is empty: $ArchivePath"
    }

    return $archive
}

function Test-RequiredCommand {
    param([Parameter(Mandatory = $true)][string] $Name)

    if ($null -eq (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
        throw "Required command was not found: $Name"
    }
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$versionPath = Join-Path $repositoryRoot 'VERSION'
$artifactsPath = Join-Path $repositoryRoot 'artifacts'
$platforms = @('GetMyWinReady', 'GetMyMacReady', 'GetMyNixReady')

foreach ($platform in $platforms) {
    $platformPath = Join-Path $repositoryRoot $platform
    if (-not (Test-Path -LiteralPath $platformPath -PathType Container)) {
        throw "Platform registry was not found: $platformPath"
    }
}

if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
    throw "Version file was not found: $versionPath"
}

$currentVersion = (Get-Content -LiteralPath $versionPath -Raw).Trim()
$nextVersion = if ($NoBump) {
    $currentVersion
}
else {
    Get-NextVersion -CurrentVersion $currentVersion -Increment $Bump
}
$tagName = "v$nextVersion"

if (-not $PackageOnly) {
    Test-RequiredCommand -Name 'git'
    Test-RequiredCommand -Name 'gh'

    $repositoryTopLevel = (Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'rev-parse', '--show-toplevel') | Select-Object -Last 1).ToString().Trim()
    $repositoryTopLevel = [System.IO.Path]::GetFullPath($repositoryTopLevel)
    if (-not [string]::Equals($repositoryTopLevel, $repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Release.ps1 must run from the root of the parent Git repository: $repositoryRoot"
    }

    $changes = @(Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'status', '--porcelain'))
    if ($changes.Count -gt 0) {
        throw 'The parent repository has uncommitted changes. Commit or stash them before publishing a release.'
    }

    $existingTag = @(Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'tag', '--list', $tagName))
    if ($existingTag.Count -gt 0) {
        throw "Tag already exists locally: $tagName"
    }

    Invoke-ExternalTool -FilePath 'gh' -Arguments @('auth', 'status') | Out-Null
}

$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ("GetMeReady-release-" + [Guid]::NewGuid().ToString('N'))
$assets = New-Object 'System.Collections.Generic.List[string]'

try {
    New-Item -ItemType Directory -Path $temporaryPath -Force | Out-Null
    New-Item -ItemType Directory -Path $artifactsPath -Force | Out-Null

    $allPackageRoot = Join-Path $temporaryPath "GetMeReady-$nextVersion"
    New-Item -ItemType Directory -Path $allPackageRoot -Force | Out-Null
    foreach ($fileName in @('LICENSE', 'README.md', 'RULES.md')) {
        Copy-Item -LiteralPath (Join-Path $repositoryRoot $fileName) -Destination (Join-Path $allPackageRoot $fileName) -Force
    }
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'scripts') -Destination (Join-Path $allPackageRoot 'scripts') -Recurse -Force
    Set-Content -LiteralPath (Join-Path $allPackageRoot 'VERSION') -Value $nextVersion -Encoding UTF8

    foreach ($platform in $platforms) {
        Copy-ReleaseDirectory -SourcePath (Join-Path $repositoryRoot $platform) -DestinationPath (Join-Path $allPackageRoot $platform)
    }

    $allArchivePath = Join-Path $artifactsPath "GetMeReady-$nextVersion-all.zip"
    [void]$assets.Add((New-ReleaseArchive -PackageRoot $allPackageRoot -ArchivePath $allArchivePath).FullName)

    foreach ($platform in $platforms) {
        $packageRoot = Join-Path $temporaryPath "$platform-$nextVersion"
        Copy-ReleaseDirectory -SourcePath (Join-Path $repositoryRoot $platform) -DestinationPath $packageRoot
        Set-Content -LiteralPath (Join-Path $packageRoot 'VERSION') -Value $nextVersion -Encoding UTF8

        $archivePath = Join-Path $artifactsPath "$platform-$nextVersion.zip"
        [void]$assets.Add((New-ReleaseArchive -PackageRoot $packageRoot -ArchivePath $archivePath).FullName)
    }

    if ($PackageOnly) {
        $assets | ForEach-Object { Get-Item -LiteralPath $_ }
        return
    }

    if (-not $NoBump) {
        Set-Content -LiteralPath $versionPath -Value $nextVersion -Encoding UTF8
        Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'add', 'VERSION') | Out-Null
        Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'commit', '-m', "Release $tagName") | Out-Null
        Invoke-ExternalTool -FilePath 'git' -Arguments @('-C', $repositoryRoot, 'push', 'origin', 'HEAD') | Out-Null
    }

    Invoke-ExternalTool -FilePath 'gh' -Arguments (@('release', 'create', $tagName, '--title', $tagName, '--generate-notes') + $assets.ToArray()) | Out-Null

    [pscustomobject]@{
        Version = $nextVersion
        Tag = $tagName
        Assets = $assets.ToArray()
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}
