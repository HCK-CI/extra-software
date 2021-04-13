<#
.SYNOPSIS
  fod.ps1: Powershell wrapper for Features on Demand installation from zip archive.
.NOTES
  Author:         Kostiantyn Kostiuk <konstantin@daynix.com>
  License:        BSD
#>

[CmdletBinding()]
param([String]$zipPath)

$ErrorActionPreference = 'Stop'

if ($zipPath -eq "") {
  Write-Error 'zipPath is not specified. Installation failed.'
}

$id = [guid]::NewGuid()
$extractFolder = "${env:TEMP}\${id}"

Expand-Archive -Path "$zipPath" -DestinationPath "$extractFolder"

$desktopFolder = Get-ChildItem -Path "$extractFolder" -Recurse -Include 'Desktop' -Directory | Select-Object -First 1
Write-Output "Desktop folder: $($desktopFolder.FullName)"

switch ($env:PROCESSOR_ARCHITECTURE) {
  'x86' {
    $cabFolder = Get-ChildItem -Path "$($desktopFolder.FullName)" -Recurse `
      -Include 'x86' -Directory | Select-Object -First 1
    Break
  }
  'AMD64' {
    $cabFolder = Get-ChildItem -Path "$($desktopFolder.FullName)" -Recurse `
      -Include 'x64' -Directory | Select-Object -First 1
    Break
  }
  Default { Write-Error 'Unknown processor architecture. Installation failed.' }
}

Write-Output "CAB folder: $($cabFolder.FullName)"

Get-Childitem -Path "$($cabFolder.FullName)" -Recurse -Include "*.cab" -File | ForEach-Object {
  Write-Output "Installing: $($_.FullName)"
  & "dism" "/online" "/add-package" "/packagepath:$($_.FullName)" "/NoRestart"
}
