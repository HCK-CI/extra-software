# Install VS 2022 Build Tools from extra-software package.
# Prefer offline layout (@sw_path@\layout) with --noWeb so lab runs do not depend on Microsoft CDN.
# Fallback: bootstrapper + channel URI (requires guest world network / --client_world_net).
param(
    [Parameter(Mandatory = $true)]
    [string]$SwPath
)

$ErrorActionPreference = 'Stop'
Write-Output '=== extra-software: install VS Build Tools 2022 ==='
Write-Output "SwPath=$SwPath"

$msbuildCandidates = @(
    'C:\BuildTools\MSBuild\Current\Bin\MSBuild.exe',
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe')
)

function Find-MSBuild {
    foreach ($c in $msbuildCandidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Enable-WorldNet {
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -ne 'Up' -and $_.HardwareInterface } |
        ForEach-Object {
            Write-Output "Enabling adapter $($_.Name)"
            Enable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
        }
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -eq 'Up' } |
        ForEach-Object {
            try { ipconfig /renew $_.Name 2>$null | Out-Null } catch {}
        }
    Start-Sleep -Seconds 5
    $if10 = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like '10.0.2.*' } |
        Select-Object -First 1
    if ($if10) {
        Write-Output "World DHCP OK: $($if10.IPAddress)"
        route add 0.0.0.0 mask 0.0.0.0 10.0.2.2 metric 1 2>$null | Out-Null
    } else {
        Write-Output 'WARNING: no 10.0.2.x address yet'
    }
}

$existing = Find-MSBuild
if ($existing) {
    Write-Output "PASS: MSBuild already present at $existing"
    exit 0
}

$os = Get-CimInstance Win32_OperatingSystem
$is2016 = ($os.Caption -match '2016') -or ($os.BuildNumber -eq '14393')
if ($is2016) {
    $sdkComponent = 'Microsoft.VisualStudio.Component.Windows10SDK.19041'
    $channelUri = 'https://aka.ms/vs/17/release.LTSC.17.8/channel'
} else {
    $sdkComponent = 'Microsoft.VisualStudio.Component.Windows11SDK.26100'
    $channelUri = 'https://aka.ms/vs/17/release/channel'
}

$workloadArgs = @(
    '--add', 'Microsoft.VisualStudio.Workload.MSBuildTools',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools',
    '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    '--add', $sdkComponent,
    '--includeRecommended'
)

$layoutDir = Join-Path $SwPath 'layout'
$bootstrap = Join-Path $SwPath 'vs_BuildTools.exe'
if (-not (Test-Path -LiteralPath $bootstrap)) {
    throw @"
vs_BuildTools.exe missing under $SwPath.

Place the bootstrapper (and preferably an offline layout/) on the lab NFS
extra-software tree — do not commit them to git (NDIS65-style).
"@
}

$localBootstrap = 'C:\vs_BuildTools.exe'
Copy-Item -LiteralPath $bootstrap -Destination $localBootstrap -Force

$layoutBootstrap = Join-Path $layoutDir 'vs_BuildTools.exe'
$hasLayout = (Test-Path -LiteralPath $layoutDir) -and (
    (Test-Path -LiteralPath (Join-Path $layoutDir 'Response.json')) -or
    (Test-Path -LiteralPath $layoutBootstrap) -or
    (@(Get-ChildItem -LiteralPath $layoutDir -ErrorAction SilentlyContinue).Count -gt 2)
)

if ($hasLayout) {
    Write-Output "Using offline layout: $layoutDir (--noWeb)"
    if (Test-Path -LiteralPath $layoutBootstrap) {
        $localBootstrap = $layoutBootstrap
    }
    $installArgs = @(
        '--quiet', '--wait', '--norestart',
        '--noWeb',
        '--installPath', 'C:\BuildTools'
    ) + $workloadArgs
} else {
    Write-Output 'WARNING: no offline layout/ — falling back to Microsoft CDN (prefer populating layout/ on lab host)'
    Enable-WorldNet
    Write-Output "Using channel: $channelUri"
    $installArgs = @(
        '--quiet', '--wait', '--norestart', '--nocache',
        '--noUpdateInstaller',
        '--channelUri', $channelUri,
        '--installPath', 'C:\BuildTools'
    ) + $workloadArgs
    try {
        $r = Invoke-WebRequest -Uri $channelUri -UseBasicParsing -Method Head -TimeoutSec 60
        Write-Output "Preflight channel OK ($($r.StatusCode))"
    } catch {
        throw @"
No offline layout and Microsoft CDN unreachable: $($_.Exception.Message)

Populate layout/ next to this package (do not commit to git), e.g.:
  vs_BuildTools.exe --layout <extra-software>/vs_buildtools/layout --lang en-US ``
    --add Microsoft.VisualStudio.Workload.MSBuildTools ``
    --add Microsoft.VisualStudio.Workload.VCTools ``
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ``
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 ``
    --includeRecommended
Also run AutoHCK with --client_world_net when using CDN fallback.
"@
    }
}

Write-Output ("Args: " + ($installArgs -join ' '))
$p = Start-Process -FilePath $localBootstrap -ArgumentList $installArgs -Wait -PassThru
Write-Output "Bootstrapper exit code: $($p.ExitCode)"

$found = Find-MSBuild
if (-not $found -and ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010)) {
    Start-Sleep -Seconds 10
    $found = Find-MSBuild
}
if (-not $found) {
    throw "VS Build Tools install failed (exit $($p.ExitCode)); MSBuild not found"
}
Write-Output "PASS: MSBuild installed at $found"
