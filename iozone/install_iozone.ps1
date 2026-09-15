<#
.SYNOPSIS
    Launcher for iozone Clickteam installer GUI automation.
    Runs in Session 0 (WinRM); schedules the worker on the interactive desktop.
.DESCRIPTION
    ExtraSoftwareManager runs this script via WinRM (Session 0), which has
    no interactive desktop. The Clickteam installer requires a visible GUI,
    so this launcher creates a scheduled task to run install_iozone_worker.ps1
    on the interactive desktop (Session 1). It then polls for a result file
    written by the worker and returns PASS/FAIL to the manager.
#>
param([string]$SwPath)

$ErrorActionPreference = "Stop"

$workDir      = "C:\AutoHCK\iozone_install"
$resultFile   = Join-Path $workDir "result.txt"
$workerLog    = Join-Path $workDir "worker.log"
$workerScript = Join-Path $SwPath "install_iozone_worker.ps1"
$installerExe = Join-Path $SwPath "IozoneSetup.exe"
$taskName     = "AutoHCK_InstallIozone"
$timeoutSec   = 120

function Get-InteractiveUser {
    $winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $u = (Get-ItemProperty -Path $winlogon -Name "DefaultUserName" -ErrorAction SilentlyContinue).DefaultUserName
    if ($u) { return $u }
    return "Administrator"
}

New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Remove-Item -Force $resultFile -ErrorAction SilentlyContinue
Remove-Item -Force $workerLog -ErrorAction SilentlyContinue

$user = Get-InteractiveUser
Write-Output "Installing iozone via interactive session (user=$user, sw_path=$SwPath)"

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$arg = "-NoProfile -ExecutionPolicy Bypass -File `"$workerScript`" -InstallerPath `"$installerExe`""
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arg
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Output "Scheduled task started; waiting for result..."

$deadline = (Get-Date).AddSeconds($timeoutSec)
while ((Get-Date) -lt $deadline) {
    if (Test-Path $resultFile) {
        $text = (Get-Content -Path $resultFile -Raw).Trim()
        Write-Output $text
        if (Test-Path $workerLog) {
            Write-Output "--- worker.log ---"
            Get-Content -Path $workerLog | ForEach-Object { Write-Output $_ }
        }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        if ($text -like "PASS:*") { exit 0 }
        exit 1
    }
    Start-Sleep -Seconds 2
}

Write-Output "FAIL: timed out waiting for iozone install"
if (Test-Path $workerLog) {
    Write-Output "--- worker.log ---"
    Get-Content -Path $workerLog | ForEach-Object { Write-Output $_ }
}
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
exit 1
