# Install and start Win32-OpenSSH sshd (AutoHCK extra-software).
# Usage: install.ps1 <extra-software-path>
#   <extra-software-path> is @sw_path@ (contains OpenSSH-Win64.zip or OpenSSH-Win32.zip).

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SwPath
)

$ErrorActionPreference = 'Continue'

# OPEN ISSUE: https://github.com/PowerShell/Win32-OpenSSH/issues/2017
# install-sshd.ps1 fails on Server 2016 (build < 17763) due to GENERIC_ALL ACEs.
# Workaround: reset C:\ProgramData\ssh ACLs; skip vendor install-sshd.ps1;
# register sshd via sc.exe instead.

function Test-SshdListening {
    return [bool](& netstat -an 2>$null | Select-String -Pattern '[\.:]22\s+.*LISTEN')
}

function Test-IsGuestX86 {
    return (($env:PROCESSOR_ARCHITECTURE -eq 'x86') -and (-not $env:PROCESSOR_ARCHITEW6432))
}

function Get-OpenSshPackageNames {
    if (Test-IsGuestX86) {
        return @{ Zip = 'OpenSSH-Win32.zip'; DestName = 'OpenSSH-Win32' }
    }
    return @{ Zip = 'OpenSSH-Win64.zip'; DestName = 'OpenSSH-Win64' }
}

function Get-PreferredSshdDir {
    $pkg = Get-OpenSshPackageNames
    $candidates = @(
        (Join-Path 'C:\Program Files' $pkg.DestName),
        'C:\Program Files\OpenSSH-Win64',
        'C:\Program Files\OpenSSH-Win32',
        'C:\Program Files\OpenSSH'
    )
    foreach ($d in $candidates) {
        if (Test-Path (Join-Path $d 'sshd.exe')) { return $d }
    }
    return $null
}

function Write-InstallLog {
    param([string]$Message)
    Write-Host $Message
}

function Install-OpenSshFromZip {
    param([string]$SourcePath)

    $pkg = Get-OpenSshPackageNames
    $zipName = $pkg.Zip
    $destName = $pkg.DestName
    Write-InstallLog "Guest arch package: $zipName -> $destName (PROCESSOR_ARCHITECTURE=$($env:PROCESSOR_ARCHITECTURE))"

    $zipPaths = @(
        (Join-Path $SourcePath $zipName),
        (Join-Path $SourcePath 'OpenSSH.zip')
    )
    if (Test-Path $SourcePath) {
        foreach ($filter in @($zipName, 'OpenSSH.zip', 'OpenSSH-Win*.zip')) {
            $found = Get-ChildItem $SourcePath -Filter $filter -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) { $zipPaths = @($found.FullName) + $zipPaths }
        }
    }

    foreach ($zp in ($zipPaths | Select-Object -Unique)) {
        if (-not (Test-Path $zp)) { continue }
        $bn = Split-Path $zp -Leaf
        if ((Test-IsGuestX86) -and ($bn -match 'Win64')) {
            Write-InstallLog "SKIP wrong-arch zip on x86: $zp"
            continue
        }
        if ((-not (Test-IsGuestX86)) -and ($bn -match 'Win32') -and ($bn -ne 'OpenSSH.zip')) {
            Write-InstallLog "SKIP wrong-arch zip on amd64: $zp"
            continue
        }
        Write-InstallLog "Extracting OpenSSH from $zp"
        $dest = Join-Path 'C:\Program Files' $destName
        if (Test-Path $dest) {
            Write-InstallLog "Removing existing $dest"
            Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue
        }
        Expand-Archive -Path $zp -DestinationPath 'C:\Program Files' -Force
        foreach ($nestedName in @($destName, 'OpenSSH-Win64', 'OpenSSH-Win32')) {
            $nested = Join-Path 'C:\Program Files' $nestedName
            if (($nested -ne $dest) -and (Test-Path $nested) -and (Test-Path (Join-Path $nested 'sshd.exe'))) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                Get-ChildItem $nested | Move-Item -Destination $dest -Force
                Remove-Item $nested -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        if (Test-Path "$dest\$destName") {
            Get-ChildItem "$dest\$destName" | Move-Item -Destination $dest -Force
            Remove-Item "$dest\$destName" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path (Join-Path $dest 'sshd.exe')) {
            Write-InstallLog "Extract complete: $dest"
            return $dest
        }
    }
    return $null
}

function Stop-SshdQuiet {
    Write-Output 'Stopping any existing sshd process/service...'
    Get-Process -Name 'sshd' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    & sc.exe stop sshd 2>&1 | Out-Null
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline) {
        $svc = Get-Service -Name 'sshd' -ErrorAction SilentlyContinue
        if (-not $svc -or $svc.Status -eq 'Stopped') { break }
        Start-Sleep -Seconds 1
    }
    Get-Process -Name 'sshd' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Start-SshdService {
    Write-InstallLog 'Starting sshd via sc.exe...'
    & sc.exe config sshd start= demand 2>&1 | Out-Null
    $startOut = & sc.exe start sshd 2>&1 | Out-String
    Write-InstallLog ("sc start sshd: " + $startOut.Trim())

    $deadline = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $deadline) {
        $svc = Get-Service -Name 'sshd' -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running' -and (Test-SshdListening)) {
            Write-InstallLog 'sshd Running and listening on :22'
            return $true
        }
        Start-Sleep -Seconds 1
    }

    $svc = Get-Service -Name 'sshd' -ErrorAction SilentlyContinue
    $status = if ($svc) { $svc.Status } else { 'missing' }
    Write-InstallLog "sshd not ready after sc start (status=$status, listen=$(Test-SshdListening))"
    return $false
}

function Capture-SshdDebugSnippet {
    $dbgLog = Join-Path $env:TEMP 'autohck_sshd_debug.txt'
    Remove-Item $dbgLog -Force -ErrorAction SilentlyContinue
    Write-Output "Capturing short sshd debug to $dbgLog ..."
    try {
        $p = Start-Process -FilePath $script:sshdExe -ArgumentList @('-d', '-d', '-d') `
            -RedirectStandardError $dbgLog -RedirectStandardOutput "$dbgLog.out" `
            -NoNewWindow -PassThru -ErrorAction Stop
        Start-Sleep -Seconds 3
        if (-not $p.HasExited) {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }
    } catch {
        Write-Output "sshd debug spawn failed: $($_.Exception.Message)"
    }
    if (Test-Path $dbgLog) {
        $lines = Get-Content $dbgLog -TotalCount 40 -ErrorAction SilentlyContinue
        if ($lines) { Write-Output ("sshd debug:`n" + ($lines -join "`n")) }
    }
}

if (-not (Test-Path $SwPath)) {
    Write-Output "FAIL: extra-software path not found: $SwPath"
    exit 1
}

Write-Output "openssh extra-software install: begin (sw_path=$SwPath)"
Stop-SshdQuiet
Start-Sleep 1

Write-Output 'Locating sshd.exe...'
$pkg = Get-OpenSshPackageNames
$bundledZip = Join-Path $SwPath $pkg.Zip
if (Test-Path $bundledZip) {
    Write-Output "Using bundled extra-software zip: $bundledZip"
    $dir = Install-OpenSshFromZip -SourcePath $SwPath
} else {
    Write-Output 'No bundled zip in extra-software path; checking existing install...'
    $dir = Get-PreferredSshdDir
    if (-not $dir) {
        Write-Output 'sshd.exe not preinstalled; extracting from extra-software zip...'
        $dir = Install-OpenSshFromZip -SourcePath $SwPath
    }
}
if (-not $dir -or -not (Test-Path (Join-Path $dir 'sshd.exe'))) {
    Write-Output 'FAIL: sshd.exe not found (expected OpenSSH-Win64.zip or OpenSSH-Win32.zip in extra-software path)'
    exit 1
}
Write-Output "Using OpenSSH from $dir"

$script:sshdExe = Join-Path $dir 'sshd.exe'
$sshKeygen = Join-Path $dir 'ssh-keygen.exe'
$installScript = Join-Path $dir 'install-sshd.ps1'

$sshDir = 'C:\ProgramData\ssh'
if (Test-Path $sshDir) {
    Write-Output 'Resetting C:\ProgramData\ssh ACLs (CREATOR OWNER / GENERIC_ALL workaround)'
    & icacls $sshDir /inheritance:d 2>&1 | Out-Null
    & icacls $sshDir /remove 'CREATOR OWNER' 2>&1 | Out-Null
    & icacls $sshDir /remove '*S-1-3-0' 2>&1 | Out-Null
}

$osBuild = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).CurrentBuildNumber
$useVendorInstall = $true
if ($osBuild -gt 0 -and $osBuild -lt 17763) {
    Write-Output "OS build $osBuild < 17763: skipping vendor install-sshd.ps1 (Server 2016 workaround)"
    $useVendorInstall = $false
}

if ($useVendorInstall -and (Test-Path $installScript)) {
    Write-Output "Running install-sshd.ps1 from $dir"
    & powershell.exe -ExecutionPolicy Bypass -File $installScript 2>&1 | Out-String | Write-Output
}

$svc = Get-Service -Name 'sshd' -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Output 'Creating sshd service via sc.exe'
    & sc.exe create sshd binPath= "`"$script:sshdExe`"" start= demand 2>&1 | Out-Null
    & sc.exe create ssh-agent binPath= "`"$(Join-Path $dir 'ssh-agent.exe')`"" start= demand 2>&1 | Out-Null
} else {
    Write-Output 'Updating sshd service binPath via sc.exe'
    & sc.exe config sshd binPath= "`"$script:sshdExe`"" 2>&1 | Out-Null
}

$env:Path = "$dir;" + $env:Path
Write-Output 'Session PATH updated (skipped Machine env write)'

Write-Output "Ensuring $sshDir exists and ACLs are normalized..."
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
& icacls $sshDir /inheritance:r /grant 'SYSTEM:(OI)(CI)(F)' /grant 'Administrators:(OI)(CI)(F)' /grant 'Authenticated Users:(OI)(CI)(RX)' 2>&1 | Out-Null

if ((Test-Path $sshKeygen) -and -not (Test-Path (Join-Path $sshDir 'ssh_host_ed25519_key'))) {
    Write-Output 'Generating host keys...'
    & $sshKeygen -A 2>&1 | Out-Null
}
Get-ChildItem $sshDir -Filter 'ssh_host_*' -ErrorAction SilentlyContinue |
    Where-Object { -not $_.Name.EndsWith('.pub') } |
    ForEach-Object {
        icacls $_.FullName /inheritance:r /grant 'SYSTEM:(F)' /grant 'Administrators:(F)' 2>&1 | Out-Null
    }

$sshdConfig = Join-Path $sshDir 'sshd_config'
$defaultConfig = Join-Path $dir 'sshd_config_default'
if (-not (Test-Path $sshdConfig) -and (Test-Path $defaultConfig)) {
    Write-Output 'Copying sshd_config_default'
    Copy-Item $defaultConfig $sshdConfig -Force
}
if (-not (Test-Path $sshdConfig)) {
    Write-Output 'Writing minimal sshd_config'
    @"
Port 22
PubkeyAuthentication yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys __PROGRAMDATA__/ssh/administrators_authorized_keys
Subsystem sftp sftp-server.exe
"@ | Set-Content -Path $sshdConfig -Force
}

Write-Output 'Patching sshd_config for pubkey auth...'
$content = Get-Content $sshdConfig -Raw
$content = $content -replace '(?m)^#?\s*PubkeyAuthentication\s+\w+', 'PubkeyAuthentication yes'
if ($content -notmatch 'PubkeyAuthentication') { $content += "`nPubkeyAuthentication yes`n" }
$content = $content -replace '(?m)^(\s*Match Group administrators)', '# $1'
$content = $content -replace '(?m)^(\s*AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys)\s*$', '# $1'
if ($content -notmatch '(?m)^\s*AuthorizedKeysFile\s+') {
    $content += "`nAuthorizedKeysFile .ssh/authorized_keys __PROGRAMDATA__/ssh/administrators_authorized_keys`n"
}
Set-Content -Path $sshdConfig -Value $content -Force

Write-Output 'Ensuring firewall rule for TCP/22...'
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 `
    -ErrorAction SilentlyContinue | Out-Null

Write-Output 'Running sshd -t...'
$t = & $script:sshdExe -t 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Output "FAIL: sshd -t failed: $($t.Trim())"
    exit 1
}
Write-Output 'sshd -t OK'

$started = Start-SshdService
if (-not $started) {
    Capture-SshdDebugSnippet
    $svc = Get-Service -Name 'sshd' -ErrorAction SilentlyContinue
    Write-Output 'FAIL: sshd Windows service is not running and listening on port 22'
    if ($svc) { Write-Output "sshd status: $($svc.Status)" }
    exit 1
}

Write-Output "PASS: OpenSSH service listening on port 22 ($dir)"
exit 0
