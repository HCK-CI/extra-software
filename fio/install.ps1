param(
    [Parameter(Mandatory = $true)]
    [String]$MsiPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $MsiPath)) {
    throw "fio MSI not found: $MsiPath"
}

$msiName = Split-Path -Leaf $MsiPath
$want64 = $msiName -match '(?i)x64'
$os64 = [Environment]::Is64BitOperatingSystem

if ($want64 -and -not $os64) {
    Write-Output "PASS: skip msiexec of fio x64 on 32-bit Windows"
    exit 0
}
if (-not $want64 -and $os64) {
    Write-Output "PASS: skip msiexec of fio x86 on 64-bit Windows"
    exit 0
}

$log = Join-Path $env:TEMP 'fio-install.log'
$p = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @(
    '/i', $MsiPath,
    '/l*v', $log,
    '/qn',
    '/norestart'
)

if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
    throw "msiexec fio failed: exit $($p.ExitCode) (log=$log)"
}

$fioExe = 'C:\Program Files\fio\fio.exe'
if (-not (Test-Path -LiteralPath $fioExe)) {
    throw "fio.exe missing after MSI install (expected $fioExe, log=$log)"
}

Write-Output "PASS: fio installed at $fioExe (msiexec exit $($p.ExitCode))"
