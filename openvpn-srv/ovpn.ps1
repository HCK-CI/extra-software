Copy-Item -Path "$PSScriptRoot\OpenVPN" -Destination "C:\OpenVPN" -Recurse
Copy-Item -Path "$PSScriptRoot\${env:COMPUTERNAME}.ovpn" -Destination "C:\OpenVPN\config-auto"

New-Item -Path "HKLM:\SOFTWARE\OpenVPN" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "Default" -Value "C:\OpenVPN\" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "config_dir" -Value "C:\OpenVPN\config\" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "autostart_config_dir" -Value "C:\OpenVPN\config-auto\" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "config_ext" -Value "ovpn" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "exe_path" -Value "C:\OpenVPN\bin\openvpn.exe" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "log_append" -Value "0" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "log_dir" -Value "C:\OpenVPN\log\" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "ovpn_admin_group" -Value "OpenVPN Administrators" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenVPN" -Name "priority" -Value "NORMAL_PRIORITY_CLASS" -Force

New-Service -Name "OpenVPNService" -BinaryPathName "C:\OpenVPN\bin\openvpnserv2.exe"
Set-Service OpenVPNService -StartupType Automatic -Status Running
