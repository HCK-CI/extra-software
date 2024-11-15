$ErrorActionPreference = 'Stop'

Write-Output "Creating directory for mounting WIM file"
New-Item -Path "C:\Users\Administrator\install_wim" -Force -Verbose -ItemType Directory

Write-Output "Mounting WIM file"
& "dism" "/Mount-Wim" "/WimFile:E:\sources\install.wim" "/Index:4" "/MountDir:C:\Users\Administrator\install_wim" "/ReadOnly"

Write-Output "Copying RoMetadata.dll to System32 and SysWOW64"
Copy-Item -Path "C:\Users\Administrator\install_wim\Windows\System32\RoMetadata.dll" -Destination "C:\Windows\System32\RoMetadata.dll" -Force -Verbose
Copy-Item -Path "C:\Users\Administrator\install_wim\Windows\SysWOW64\RoMetadata.dll" -Destination "C:\Windows\SysWOW64\RoMetadata.dll" -Force -Verbose

Write-Output "Unmounting WIM file"
& "dism" "/Unmount-Wim" "/MountDir:C:\Users\Administrator\install_wim" "/Discard"

Write-Output "Removing temporary files"
Remove-Item -Path "C:\Users\Administrator\install_wim" -Force -Recurse -Verbose

Get-Date
Start-Sleep -Seconds 10
Get-Date
