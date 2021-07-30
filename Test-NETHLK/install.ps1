<#
.SYNOPSIS
  fod.ps1: PowerShell wrapper for Test-NETHLK PowerShell module installation from ZIP.
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

Expand-Archive -Path "$zipPath" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules"
