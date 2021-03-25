# Extra software repository

Each application has separate directories with the next files:

1. config.json (_required_) - configuration file with full information about software.
   1. {KIT}-config.json (_optional_) - configuration file for specific KIT version, in case of KIT installation, it fills to be used instead of config.json.
2. Any other files are optional. It can be used as installation helpers.

## Install arguments replacement

The `install_args` value can contain the special strings. These strings will be replaced with corresponding values before execution. The following strings are supported:
  - @sw_path@ - the path where extra software stored at the machine
  - @file_name@ - file name option from config.json
  - @temp@ - the path to temp folder


## Directories content examples

### winfsp application:

1. config.json:
```json
{
    "download_url": "https://github.com/billziss-gh/winfsp/releases/download/v1.6/winfsp-1.6.20027.msi",
    "file_name": "winfsp-1.6.20027.msi",
    "install_cmd": "msiexec",
    "install_args": "/i @sw_path@\\@file_name@ /l*v @temp@\\@file_name@.log /qn",
    "install_time": {
        "kit": "after",
        "driver": "before"
    }
 }

```

### HLK_GRFX_FOD application:

1. hlk1903-config.json:
```json
{
    "download_url": "https://go.microsoft.com/fwlink/?linkid=2087319",
    "file_name": "hlk1903_grfx_fod.zip",
    "install_cmd": "powershell",
    "install_args": "-ExecutionPolicy Bypass -File @sw_path@\\fod.ps1",
    "install_time":{
        "kit": "before",
        "driver": "before"
    }
}
```
2. hlk1809-config.json:
```json
{
    "download_url": "https://go.microsoft.com/fwlink/?linkid=2027144&clcid=0x409",
    "file_name": "hlk1809_grfx_fod.zip",
    "install_cmd": "powershell",
    "install_args": "-ExecutionPolicy Bypass -File @sw_path@\\fod.ps1",
    "install_time":{
        "kit": "before",
        "driver": "before"
    }
}
```
3. install_fod.ps1 - perform the next steps:
```
unzip HLK_GRFX_FOD to get cab archive

dism /online /add-package /packagepath:<path to package>\Microsoft-OneCore-Graphics-Tools-Package~31bf3856ad364e35~amd64~~.cab
```
