<#
.SYNOPSIS
    GUI automation worker for IozoneSetup.exe (Clickteam Install Creator).
    Runs in the interactive desktop session via scheduled task.
.DESCRIPTION
    Uses Win32 PostMessage BM_CLICK to click buttons directly by handle,
    bypassing keyboard focus issues with SConfig console.
    Navigates the 6-page Clickteam wizard:
      1. Welcome        -> Next
      2. Directory       -> Next (accept default)
      3. Create dir?     -> Yes
      4. Confirmation    -> Start
      5. Complete        -> Next
      6. Publisher       -> Exit
    Writes PASS:/FAIL: to C:\AutoHCK\iozone_install\result.txt.
#>
param([string]$InstallerPath)

$workDir    = "C:\AutoHCK\iozone_install"
$resultFile = Join-Path $workDir "result.txt"
$logFile    = Join-Path $workDir "worker.log"

New-Item -ItemType Directory -Force -Path $workDir | Out-Null
New-Item -ItemType Directory -Force -Path "C:\temp" | Out-Null

Start-Transcript -Path $logFile -Force
$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public class ClickButton {
    public delegate bool EnumChildProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumChildProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int max);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int max);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);

    private const uint BM_CLICK = 0x00F5;

    public static bool ClickByText(string winTitle, string btnSubstring) {
        IntPtr wnd = FindWindow(null, winTitle);
        if (wnd == IntPtr.Zero) return false;

        IntPtr found = IntPtr.Zero;
        EnumChildWindows(wnd, (h, l) => {
            var cls = new StringBuilder(256);
            GetClassName(h, cls, 256);
            if (cls.ToString() != "Button") return true;

            var txt = new StringBuilder(256);
            GetWindowText(h, txt, 256);
            if (txt.ToString().IndexOf(btnSubstring, StringComparison.OrdinalIgnoreCase) >= 0) {
                found = h;
                return false;
            }
            return true;
        }, IntPtr.Zero);

        if (found == IntPtr.Zero) return false;
        return PostMessage(found, BM_CLICK, IntPtr.Zero, IntPtr.Zero);
    }

    public static List<string> ListControls(string winTitle) {
        var r = new List<string>();
        IntPtr wnd = FindWindow(null, winTitle);
        if (wnd == IntPtr.Zero) { r.Add("Window not found"); return r; }
        EnumChildWindows(wnd, (h, l) => {
            var t = new StringBuilder(256); GetWindowText(h, t, 256);
            var c = new StringBuilder(256); GetClassName(h, c, 256);
            if (t.Length > 0) r.Add("[" + t + "] cls=" + c);
            return true;
        }, IntPtr.Zero);
        return r;
    }

    public static bool WindowExists(string winTitle) {
        return FindWindow(null, winTitle) != IntPtr.Zero;
    }
}
"@

try {
    Write-Output "Worker session=$([System.Diagnostics.Process]::GetCurrentProcess().SessionId)"
    Write-Output "InstallerPath=$InstallerPath"

    $localExe = "C:\temp\IozoneSetup.exe"
    $srcResolved = (Resolve-Path $InstallerPath -ErrorAction SilentlyContinue).Path
    if ($srcResolved -ne $localExe -and (Test-Path $InstallerPath)) {
        Copy-Item -Path $InstallerPath -Destination $localExe -Force
        Write-Output "Copied to $localExe"
    } elseif (-not (Test-Path $localExe)) {
        throw "Installer not found"
    } else {
        Write-Output "Installer already at $localExe"
    }

    $title = "Iozone3_483 Install Program"

    Write-Output "Launching installer..."
    $proc = Start-Process -FilePath $localExe -PassThru
    Write-Output "PID=$($proc.Id)"
    Start-Sleep -Seconds 5

    if (-not [ClickButton]::WindowExists($title)) {
        throw "Installer window not found"
    }
    Write-Output "Window found"

    $ok = [ClickButton]::ClickByText($title, "Next")
    Write-Output "Step 1 Next: $ok"
    Start-Sleep -Seconds 2

    $ok = [ClickButton]::ClickByText($title, "Next")
    Write-Output "Step 2 Next: $ok"
    Start-Sleep -Seconds 2

    Start-Sleep -Seconds 1
    $ok = [ClickButton]::ClickByText($title, "Yes")
    if (-not $ok) {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.AppActivate($title)
        Start-Sleep -Milliseconds 300
        $wsh.SendKeys("{ENTER}")
        Write-Output "Step 3 Yes: fallback SendKeys Enter"
    } else {
        Write-Output "Step 3 Yes: $ok"
    }
    Start-Sleep -Seconds 2

    $controls = [ClickButton]::ListControls($title)
    Write-Output "Step 4 controls: $($controls -join ', ')"
    $ok = [ClickButton]::ClickByText($title, "Start")
    Write-Output "Step 4 Start: $ok"
    Start-Sleep -Seconds 8

    $ok = [ClickButton]::ClickByText($title, "Next")
    Write-Output "Step 5 Next: $ok"
    Start-Sleep -Seconds 2

    $ok = [ClickButton]::ClickByText($title, "xit")
    Write-Output "Step 6 Exit: $ok"
    Start-Sleep -Seconds 2

    if (-not $proc.HasExited) {
        Write-Output "Waiting for process..."
        $proc.WaitForExit(30000)
    }
    Write-Output "Exited=$($proc.HasExited)"

    $iozoneExe = "C:\Program Files (x86)\Benchmarks\Iozone3_483\iozone.exe"
    if (Test-Path $iozoneExe) {
        Write-Output "SUCCESS: $iozoneExe"
        Set-Content $resultFile "PASS: iozone installed at $iozoneExe"
    } else {
        $found = Get-ChildItem C:\ -Filter iozone.exe -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Output "Found at $($found.FullName)"
            Set-Content $resultFile "PASS: iozone installed at $($found.FullName)"
        } else {
            throw "iozone.exe not found after install"
        }
    }
} catch {
    Write-Output "ERROR: $_"
    Set-Content $resultFile "FAIL: $_"
}

Stop-Transcript
