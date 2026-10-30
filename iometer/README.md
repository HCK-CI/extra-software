# iometer for AutoHCK

Iometer 1.1.0 disk I/O benchmark (IOmeter.exe controller + Dynamo.exe
worker) for the functest vioscsi iometer cases.

## Arch variants

| Config | Binary source | Version | Arch |
|---|---|---|---|
| `x64-config.json` | [iometer 1.1.0 win64.x86_64](https://sourceforge.net/projects/iometer/files/iometer-stable/1.1.0/) | 1.1.0 | amd64 |
| `x86-config.json` | [iometer 1.1.0 win32.i386](https://sourceforge.net/projects/iometer/files/iometer-stable/1.1.0/) | 1.1.0 | x86 |

The WinXP.i386 build was deliberately not used: it is an 18 MB
debug-symbols variant (ships PDBs) for Windows XP compatibility.

## Layout

```
iometer/
  x64-config.json
  x86-config.json
  install.ps1
  iometer.reg
  iometer-win64.zip     # not in git — AutoHCK downloads on first use (x64)
  iometer-win32.zip     # not in git — AutoHCK downloads on first use (x86)
```

Guest install: `C:\iometer\IOmeter.exe` and `C:\iometer\Dynamo.exe`
(the release archive is flat; the worker script iometer_worker.ps1
expects both executables at that path). Both executables ship in one
archive, so a single package covers the controller and its Dynamo
worker — there is no separate dynamo package.

`iometer.reg` is staged next to the executables. The worker imports it
into HKCU as the interactive user to suppress the first-run EULA dialog,
which would otherwise block `/c` command-line mode. The Version value
must match the IOmeter.exe file version string ("1.1.0").

AutoHCK picks `x64-config.json` or `x86-config.json` per guest arch.
`install.ps1` locates the matching zip by guest architecture at runtime.

## Usage

```json
"extra_software": ["iometer"]
```
