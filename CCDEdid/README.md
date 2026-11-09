# CCDEdid

## Description

The `Test for EDID Requirements (Manual)` fails on Windows Server 2025 with the newer HLK because `CCDEdid.exe` is missing from the HLK test content.

The failure occurs during the **Copy test content** step, before the actual EDID test runs.

The binary is available in older HLK versions. Copying it to the newer HLK STUDIO allows the test to run successfully.

## Setup

The `CCDEdid.zip` package can be obtained from the shared NFS extra-software directory or created using `CCDEdid.exe` from an older HLK installation.

The ZIP must have the following structure:

```text
CCDEdid.zip
├── amd64/
│   └── CCDEdid.exe
└── x86/
    └── CCDEdid.exe
```

Place `CCDEdid.zip` in this directory before building a STUDIO image for HLK11_24H2, HLK11_25H2, or HLK2025.

The binary and ZIP archive are excluded from Git and should not be committed to the repository.
