$ErrorActionPreference = 'Stop'
$SrcDir = $PSScriptRoot
$InstallDir = 'C:\ntttcp'
$ExeFile = Join-Path $SrcDir 'ntttcp.exe'

if (-not (Test-Path $ExeFile)) {
    Write-Output "FAIL: ntttcp.exe not found at $ExeFile"
    exit 1
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item -Path $ExeFile -Destination (Join-Path $InstallDir 'ntttcp.exe') -Force

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$parts = @()
if (-not [string]::IsNullOrEmpty($machinePath)) {
    $parts = @($machinePath -split ';' | Where-Object { $_ -ne '' })
}
if ($parts -notcontains $InstallDir) {
    [Environment]::SetEnvironmentVariable('Path', ($InstallDir + ';' + $machinePath), 'Machine')
}

Write-Output "PASS: ntttcp installed ($InstallDir)"
exit 0
