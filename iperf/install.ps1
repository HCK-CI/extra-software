$ErrorActionPreference = 'Stop'
$SrcDir = $PSScriptRoot
$InstallDir = 'C:\iperf'

function Test-IsGuestX86 {
    return (($env:PROCESSOR_ARCHITECTURE -eq 'x86') -and (-not $env:PROCESSOR_ARCHITEW6432))
}

$IsX86 = Test-IsGuestX86
$Arch = if ($IsX86) { 'x86' } else { 'amd64' }

# Preferred zip name matches config file_name; fall back to legacy name.
if ($IsX86) {
    $ZipNames = @('iperf-win32.zip', 'iperf3-win.zip')
} else {
    $ZipNames = @('iperf-win64.zip', 'iperf3-win.zip')
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
    Write-Output "FAIL: iperf3 zip not found under $SrcDir (tried: $($ZipNames -join ', '))"
    exit 1
}

Write-Output "DIAG: arch=$Arch, zip=$ZipFile"

$TempDir = Join-Path $env:TEMP ("iperf3_extract_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
try {
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $TempDir -Force

    $exe = Get-ChildItem -Path $TempDir -Recurse -Filter 'iperf3.exe' |
        Select-Object -First 1
    if (-not $exe) {
        Write-Output 'FAIL: iperf3.exe not found inside zip'
        exit 1
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -LiteralPath $exe.FullName -Destination (Join-Path $InstallDir 'iperf3.exe') -Force

    # Copy any required DLLs (cygwin, msvcrt, etc.) from the same directory.
    Get-ChildItem -Path $exe.DirectoryName -Filter '*.dll' -ErrorAction SilentlyContinue |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $InstallDir $_.Name) -Force
        }
} finally {
    Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$parts = @()
if (-not [string]::IsNullOrEmpty($machinePath)) {
    $parts = @($machinePath -split ';' | Where-Object { $_ -ne '' })
}
if ($parts -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable('Path', ($InstallDir + ';' + $machinePath), 'Machine')
}

Write-Output "PASS: iperf3 installed ($InstallDir, arch=$Arch)"
exit 0
