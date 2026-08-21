param(
    [Parameter(Mandatory = $true)]
    [String]$MsiPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $MsiPath)) {
    throw "7z MSI not found: $MsiPath"
}

# Keep a copy for support_win_fs (elevate installer from virtiofs share).
$stageDir = 'C:\7-Zip'
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
Copy-Item -Force -LiteralPath $MsiPath -Destination (Join-Path $stageDir '7z-x64.msi')

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

Write-Output "PASS: 7z installed at $sevenZipExe; MSI staged at $stageDir\7z-x64.msi (msiexec exit $($p.ExitCode))"
