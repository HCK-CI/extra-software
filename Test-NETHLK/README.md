# Overview

Test-NetHLK is a module used for testing the advanced properties for Network Adapters and determining if a network switch supports the Azure Stack HCI requirements.

## Test-NETHLK zip archive preparation

This module is available on the PowerShell gallery using the following command:
```Install-Module Test-NetHLK -Force```

For a disconnected system, please use:
```Save-Module Test-NetHLK -Path <SomeFolderPath>```

Compress the saved module with all dependencies. For example:
```Compress-Archive -Path <SomeFolderPath>\* -DestinationPath Test-NetHLK.<version>.zip```
