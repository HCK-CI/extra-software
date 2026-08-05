# Install winfsp-tests into the WinFsp bin directory (x64 and x86).
param(
    [Parameter(Mandatory = $true)]
    [String]$zipPath
)

$ErrorActionPreference = 'Stop'

$extractFolder = Join-Path $env:TEMP "winfsp-tests-$([guid]::NewGuid().ToString('N'))"
$binCandidates = @(
    'C:\Program Files (x86)\WinFsp\bin',
    'C:\Program Files\WinFsp\bin'
)

$binDir = $null
foreach ($cand in $binCandidates) {
    if (Test-Path -LiteralPath $cand) {
        $binDir = $cand
        break
    }
}
if (-not $binDir) {
    # WinFsp MSI usually creates the (x86) path even on x64; fall back for pure x86 guests.
    $binDir = if (${env:ProgramFiles(x86)}) {
        'C:\Program Files (x86)\WinFsp\bin'
    } else {
        'C:\Program Files\WinFsp\bin'
    }
}

Expand-Archive -Force -Path $zipPath -DestinationPath $extractFolder
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$installed = @()
foreach ($exeName in @('winfsp-tests-x64.exe', 'winfsp-tests-x86.exe')) {
    $src = Join-Path $extractFolder $exeName
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Missing $exeName in $zipPath"
    }
    Copy-Item -Force -LiteralPath $src -Destination (Join-Path $binDir $exeName)
    $installed += $exeName
}

Remove-Item -Recurse -Force -LiteralPath $extractFolder -ErrorAction SilentlyContinue

Write-Output ("PASS: installed {0} to {1}" -f ($installed -join ', '), $binDir)
