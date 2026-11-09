[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$ZipPath)

$ErrorActionPreference = 'Stop'

$testsRoot = 'C:\Program Files (x86)\Windows Kits\10\Hardware Lab Kit\Tests'
$extractDir = Join-Path $env:TEMP ('CCDEdid-' + [guid]::NewGuid().ToString('N'))

try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractDir -Force

    foreach ($arch in @('amd64', 'x86')) {
        $targetArch = if ($arch -eq 'amd64') { 'AMD64' } else { 'x86' }
        $destination = Join-Path $testsRoot "$targetArch\nttest\windowstest\graphics\wddm\bin"
        $targetFile = Join-Path $destination 'CCDEdid.exe'
        if (Test-Path -LiteralPath $targetFile -PathType Leaf) { continue }

        $source = Join-Path $extractDir "$arch\CCDEdid.exe"
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "$arch/CCDEdid.exe not found in $ZipPath"
        }

        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $targetFile
    }
}
finally {
    Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}
