param(
    [Parameter(Mandatory = $true)]
    [String]$MsiPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $MsiPath)) {
    throw "7z MSI not found: $MsiPath"
}

$msiName = Split-Path -Leaf $MsiPath
$want64 = $msiName -match '(?i)x64'
$os64 = [Environment]::Is64BitOperatingSystem

# Keep a copy for support_win_fs (elevate installer from virtiofs share).
$stageDir = 'C:\7-Zip'
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
Copy-Item -Force -LiteralPath $MsiPath -Destination (Join-Path $stageDir $msiName)

if ($want64 -and -not $os64) {
    Write-Output "PASS: skip msiexec of 7z x64 on 32-bit Windows; MSI staged at $stageDir\$msiName"
    exit 0
}
if (-not $want64 -and $os64) {
    Write-Output "PASS: skip msiexec of 7z x86 on 64-bit Windows; MSI staged at $stageDir\$msiName"
    exit 0
}

$log = Join-Path $env:TEMP '7z-install.log'
$p = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @(
    '/i', $MsiPath,
    '/l*v', $log,
    '/qn',
    '/norestart'
)

if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
    throw "msiexec 7z failed: exit $($p.ExitCode) (log=$log)"
}

$sevenZipExe = 'C:\Program Files\7-Zip\7z.exe'
if (-not (Test-Path -LiteralPath $sevenZipExe)) {
    throw "7z.exe missing after MSI install (expected $sevenZipExe, log=$log)"
}

Write-Output "PASS: 7z installed at $sevenZipExe; MSI staged at $stageDir\$msiName (msiexec exit $($p.ExitCode))"
