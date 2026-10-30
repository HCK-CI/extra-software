$ErrorActionPreference = 'Stop'
$SrcDir = $PSScriptRoot
$InstallDir = 'C:\iometer'

function Test-IsGuestX86 {
    return (($env:PROCESSOR_ARCHITECTURE -eq 'x86') -and (-not $env:PROCESSOR_ARCHITEW6432))
}

$IsX86 = Test-IsGuestX86
$Arch = if ($IsX86) { 'x86' } else { 'amd64' }

# Preferred zip name matches config file_name; fall back to upstream release name.
if ($IsX86) {
    $ZipNames = @('iometer-win32.zip', 'iometer-1.1.0-win32.i386-bin.zip')
} else {
    $ZipNames = @('iometer-win64.zip', 'iometer-1.1.0-win64.x86_64-bin.zip')
}

$ZipFile = $null
foreach ($name in $ZipNames) {
    $candidate = Join-Path $SrcDir $name
    if (Test-Path $candidate) {
        $ZipFile = $candidate
        break
    }
}

if (-not $ZipFile) {
    Write-Output "FAIL: iometer zip not found under $SrcDir (tried: $($ZipNames -join ', '))"
    exit 1
}

Write-Output "DIAG: arch=$Arch, zip=$ZipFile"

# The release archive is flat: IOmeter.exe + Dynamo.exe at the top level.
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Expand-Archive -LiteralPath $ZipFile -DestinationPath $InstallDir -Force

# First-run EULA suppression: the functest worker (iometer_worker.ps1)
# imports this into HKCU as the interactive user before running IOmeter
# in /c mode. The Version value must match the IOmeter.exe file version
# ("1.1.0"), otherwise the EULA dialog blocks startup.
$RegFile = Join-Path $SrcDir 'iometer.reg'
if (Test-Path -LiteralPath $RegFile) {
    Copy-Item -LiteralPath $RegFile -Destination (Join-Path $InstallDir 'iometer.reg') -Force
} else {
    Write-Output "WARN: iometer.reg not found under $SrcDir; first-run EULA is not suppressed"
}

foreach ($exe in @('IOmeter.exe', 'Dynamo.exe')) {
    $exePath = Join-Path $InstallDir $exe
    if (-not (Test-Path -LiteralPath $exePath)) {
        Write-Output "FAIL: $exe missing after extract (expected $exePath)"
        exit 1
    }
}

Write-Output "PASS: iometer installed ($InstallDir, arch=$Arch)"
exit 0
