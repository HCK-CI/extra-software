param(
    [Parameter(Mandatory = $true)]
    [String]$ZipPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $ZipPath)) {
    throw "windbg.zip not found: $ZipPath"
}

Expand-Archive -Path $ZipPath -DestinationPath 'C:\' -Force

$msi = Get-ChildItem -Path 'C:\windbg' -Filter '*Debuggers*.msi' -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $msi) {
    throw 'SDK Debuggers MSI not found under C:\windbg'
}

$args = "/i `"$($msi.FullName)`" /quiet /norestart /l*v $env:TEMP\windbg-install.log"
$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $args -Wait -PassThru
if ($p.ExitCode -ne 0) {
    throw "msiexec failed with exit code $($p.ExitCode)"
}

Write-Output "PASS: Debugging Tools installed from $($msi.FullName)"
