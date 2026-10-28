param(
    [Parameter(Mandatory = $true)]
    [String]$ZipPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "MinGit zip not found: $ZipPath (extra_software git)"
}

$zipName = Split-Path -Leaf $ZipPath
$want64 = $zipName -match '(?i)64-bit|x64'
$os64 = [Environment]::Is64BitOperatingSystem

if ($want64 -and -not $os64) {
    Write-Output "PASS: skip MinGit x64 on 32-bit Windows ($zipName)"
    exit 0
}
if (-not $want64 -and $os64) {
    Write-Output "PASS: skip MinGit x86 on 64-bit Windows ($zipName)"
    exit 0
}

$destRoot = 'C:\AutoHCK\Git'
if (Test-Path -LiteralPath $destRoot) {
    Remove-Item -LiteralPath $destRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $destRoot -Force | Out-Null
Expand-Archive -LiteralPath $ZipPath -DestinationPath $destRoot -Force

$git = @(
    'C:\AutoHCK\Git\cmd\git.exe'
    'C:\AutoHCK\Git\mingw64\bin\git.exe'
    'C:\AutoHCK\Git\mingw32\bin\git.exe'
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $git) {
    throw "MinGit extract finished but git.exe was not found under $destRoot"
}

$gitDir = Split-Path -Parent $git
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
if ($machinePath -notlike "*${gitDir}*") {
    [Environment]::SetEnvironmentVariable('Path', "$gitDir;$machinePath", 'Machine')
}

Write-Output "PASS: Git installed ($git)"
