<#
.SYNOPSIS
  fod.ps1: Powershell wrapper for Features on Demand installation from ISO.
.NOTES
  Author:         Kostiantyn Kostiuk <konstantin@daynix.com>
  License:        BSD
#>

[CmdletBinding()]
param([String]$isoPath)

$ErrorActionPreference = 'Stop'

if ($isoPath -eq "") {
  Write-Error 'isoPath is not specified. Installation failed.'
}

$fod_iso_tmp = "${env:TEMP}\fod.iso"
Copy-Item -Path "$isoPath" -Destination "$fod_iso_tmp"

$image = Mount-DiskImage -ImagePath "$fod_iso_tmp" -PassThru
$volume = $image | Get-Volume
$driveLetter = $volume.DriveLetter

Add-WindowsCapability -Online -Name ServerCore.AppCompatibility~~~~0.0.1.0 -Source "${driveLetter}:" -LimitAccess

Dismount-DiskImage -ImagePath "$fod_iso_tmp"
Remove-Item -Path "$fod_iso_tmp" -Force
