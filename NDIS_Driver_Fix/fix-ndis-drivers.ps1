# NDIS Driver Fix Script
# This script fixes unsigned NDIS drivers issue in HLK/WLK by copying signed drivers from ntndis* source folders
# Reference: https://github.com/HCK-CI/AutoHCK/issues/819
#
# Problem: After HLK installation, drivers in NDISTest65\bin\protocol are unsigned
# Solution: Copy signed versions from NDISTest\bin\ntndis*\ folders

$ErrorActionPreference = 'Stop'

Write-Output "=========================================="
Write-Output "NDIS Driver Fix Script"
Write-Output "=========================================="
Write-Output ""

# Base path for HLK installation
$hlkBasePath = "C:\Program Files (x86)\Windows Kits\10\Hardware Lab Kit\Tests\amd64\NetHlk"
$ndisTest65BinProtocolPath = Join-Path $hlkBasePath "NDISTest65\bin\protocol"
$ndisTestBinPath = Join-Path $hlkBasePath "NDISTest\bin"

# Function to check if a driver file is signed
function Test-DriverSigned {
    param (
        [string]$FilePath
    )
    
    try {
        $signature = Get-AuthenticodeSignature -FilePath $FilePath
        return ($signature.Status -eq 'Valid')
    }
    catch {
        return $false
    }
}

# Function to find and copy signed driver from ntndis* folders
function Copy-SignedDriver {
    param (
        [string]$DriverName,
        [string]$DestinationPath,
        [array]$SourceFolders
    )
    
    foreach ($folder in $SourceFolders) {
        $sourceDriverPath = Join-Path $folder.FullName $DriverName
        
        if (Test-Path $sourceDriverPath) {
            # Check if source driver is signed
            $isSourceSigned = Test-DriverSigned -FilePath $sourceDriverPath
            
            if ($isSourceSigned) {
                Write-Output "  [COPY] $DriverName from $($folder.Name)"
                Copy-Item -Path $sourceDriverPath -Destination $DestinationPath -Force -Verbose
                return $true
            }
        }
    }
    
    return $false
}

# Fix NDIS Test 6.5 drivers
Write-Output "Checking NDIS Test 6.5 drivers..."

if (Test-Path $ndisTest65BinProtocolPath) {
    Write-Output "Found NDISTest65 path: $ndisTest65BinProtocolPath"
    
    # Check if drivers in protocol folder are signed
    $protocolDrivers = Get-ChildItem -Path $ndisTest65BinProtocolPath -Filter "*.sys" -ErrorAction SilentlyContinue
    $unsignedCount = 0
    $unsignedDrivers = @()
    
    foreach ($driver in $protocolDrivers) {
        $isSigned = Test-DriverSigned -FilePath $driver.FullName
        if (-not $isSigned) {
            Write-Output "  [UNSIGNED] $($driver.Name)"
            $unsignedCount++
            $unsignedDrivers += $driver
        }
        else {
            Write-Output "  [SIGNED] $($driver.Name)"
        }
    }
    
    if ($unsignedCount -gt 0) {
        Write-Output ""
        Write-Output "Found $unsignedCount unsigned driver(s), attempting to fix..."
        Write-Output "Looking for signed drivers in: $ndisTestBinPath"
        
        # Get all ntndis* subdirectories as source
        $ntndisfolders = Get-ChildItem -Path $ndisTestBinPath -Directory -Filter "ntndis*" -ErrorAction SilentlyContinue
        
        if ($ntndisfolders.Count -eq 0) {
            Write-Output "  [ERROR] No ntndis* folders found in $ndisTestBinPath"
        }
        else {
            Write-Output "  Found $($ntndisfolders.Count) ntndis* source folders"
            
            $fixedCount = 0
            foreach ($unsignedDriver in $unsignedDrivers) {
                $driverFixed = Copy-SignedDriver -DriverName $unsignedDriver.Name -DestinationPath $unsignedDriver.FullName -SourceFolders $ntndisfolders
                
                if ($driverFixed) {
                    $fixedCount++
                }
                else {
                    Write-Output "  [WARNING] Could not find signed version of $($unsignedDriver.Name)"
                }
            }
            
            Write-Output ""
            Write-Output "Fixed $fixedCount out of $unsignedCount unsigned driver(s)"
        }
    }
    else {
        Write-Output "All drivers are properly signed!"
    }
}
else {
    Write-Output "NDISTest65 path not found: $ndisTest65BinProtocolPath"
}

Write-Output ""
Write-Output "=========================================="

# Check NDIS Test drivers (source folders with signed drivers)
Write-Output "Checking NDIS Test source drivers (ntndis* folders)..."

if (Test-Path $ndisTestBinPath) {
    Write-Output "Found NDISTest path: $ndisTestBinPath"
    
    # Get all ntndis* subdirectories
    $ndisFolders = Get-ChildItem -Path $ndisTestBinPath -Directory -Filter "ntndis*" -ErrorAction SilentlyContinue
    
    if ($ndisFolders.Count -eq 0) {
        Write-Output "No ntndis* folders found"
    }
    else {
        Write-Output "Found $($ndisFolders.Count) NDIS version folder(s) (these should contain signed drivers)"
        
        foreach ($folder in $ndisFolders) {
            Write-Output ""
            Write-Output "Checking: $($folder.Name)"
            
            $driverFiles = Get-ChildItem -Path $folder.FullName -Filter "*.sys" -ErrorAction SilentlyContinue
            
            if ($driverFiles.Count -eq 0) {
                Write-Output "  No driver files found"
                continue
            }
            
            foreach ($driver in $driverFiles) {
                $isSigned = Test-DriverSigned -FilePath $driver.FullName
                if ($isSigned) {
                    Write-Output "  [SIGNED] $($driver.Name) "
                }
                else {
                    Write-Output "  [UNSIGNED] $($driver.Name)  (unexpected!)"
                }
            }
        }
    }
}
else {
    Write-Output "NDISTest path not found: $ndisTestBinPath"
}

Write-Output ""
Write-Output "=========================================="
Write-Output "NDIS Driver Fix Script Completed"
Write-Output "=========================================="
