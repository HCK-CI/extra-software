$ErrorActionPreference = 'Stop'
$SrcDir = $PSScriptRoot
$InstallDir = 'C:\iperf'
$ZipFile = Join-Path $SrcDir 'iperf3-win.zip'

if (-not (Test-Path $ZipFile)) {
    Write-Output "FAIL: iperf3-win.zip not found at $ZipFile"
    exit 1
}

$TempDir = Join-Path $env:TEMP ("iperf3_extract_" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
try {
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $TempDir -Force
    $exe = Get-ChildItem -Path $TempDir -Recurse -Filter 'iperf3.exe' | Select-Object -First 1
    if (-not $exe) {
        Write-Output 'FAIL: iperf3.exe not found inside zip'
        exit 1
    }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -LiteralPath $exe.FullName -Destination (Join-Path $InstallDir 'iperf3.exe') -Force
    $dll = Get-ChildItem -Path $TempDir -Recurse -Filter 'cygwin1.dll' | Select-Object -First 1
    if ($dll) {
        Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $InstallDir 'cygwin1.dll') -Force
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

Write-Output "PASS: iperf3 installed ($InstallDir)"
exit 0
