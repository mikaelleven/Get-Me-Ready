<#
.SYNOPSIS
Runs the GetMeReady installer appropriate for the current operating system.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$rawBaseUrl = 'https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master'
$isWindows = $env:OS -eq 'Windows_NT'

if ($isWindows) {
    $installerUrl = "$rawBaseUrl/GetMyWinReady/Install-GMR.ps1"
    $installerPath = Join-Path ([System.IO.Path]::GetTempPath()) ("Install-GMR-" + [Guid]::NewGuid().ToString('N') + '.ps1')
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        & $installerPath
    }
    finally {
        if (Test-Path -LiteralPath $installerPath) {
            Remove-Item -LiteralPath $installerPath -Force
        }
    }

    return
}

$systemName = & uname -s
switch ($systemName) {
    'Darwin' { $installerUrl = "$rawBaseUrl/GetMyMacReady/Install-GMR.sh" }
    'Linux' { $installerUrl = "$rawBaseUrl/GetMyNixReady/Install-GMR.sh" }
    default { throw "GetMeReady does not support this operating system: $systemName" }
}

$installerPath = Join-Path ([System.IO.Path]::GetTempPath()) ("Install-GMR-" + [Guid]::NewGuid().ToString('N') + '.sh')
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    & bash $installerPath
}
finally {
    if (Test-Path -LiteralPath $installerPath) {
        Remove-Item -LiteralPath $installerPath -Force
    }
}
