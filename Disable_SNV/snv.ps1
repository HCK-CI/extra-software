
if (Test-Path -Path "HKLM:\Software\Microsoft\StrongName\Verification") {
    Remove-Item -Path "HKLM:\Software\Microsoft\StrongName\Verification" -Force -Verbose -Recurse
}
New-Item -Path "HKLM:\Software\Microsoft\StrongName\Verification\*,*" -Force -Verbose

if (Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\StrongName\Verification") {
    Remove-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\StrongName\Verification" -Force -Verbose -Recurse
}
New-Item -Path "HKLM:\Software\Wow6432Node\Microsoft\StrongName\Verification\*,*" -Force -Verbose
