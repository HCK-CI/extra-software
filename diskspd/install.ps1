param(
    [Parameter(Mandatory = $true)]
    [String]$ZipPath
)

$ErrorActionPreference = 'Stop'

function Test-IsGuestX86 {
    return (($env:PROCESSOR_ARCHITECTURE -eq 'x86') -and (-not $env:PROCESSOR_ARCHITEW6432))
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "DiskSpd zip not found: $ZipPath (extra_software diskspd)"
}

# The release zip contains all arches (amd64\, x86\, arm64\); pick per guest OS.
$arch = if (Test-IsGuestX86) { 'x86' } else { 'amd64' }
$installDir = 'C:\diskspd'
$extractDir = Join-Path $env:TEMP ("diskspd-" + [guid]::NewGuid().ToString('N'))

try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractDir -Force

    $srcExe = Join-Path $extractDir "$arch\diskspd.exe"
    if (-not (Test-Path -LiteralPath $srcExe -PathType Leaf)) {
        throw "$arch\diskspd.exe not found in $ZipPath"
    }

    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item -LiteralPath $srcExe -Destination (Join-Path $installDir 'diskspd.exe') -Force
}
finally {
    Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}

$exePath = Join-Path $installDir 'diskspd.exe'
if (-not (Test-Path -LiteralPath $exePath)) {
    throw "diskspd.exe missing after install (expected $exePath)"
}

Write-Output "PASS: DiskSpd installed at $exePath (arch=$arch)"
