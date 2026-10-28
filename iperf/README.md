# iperf3 for AutoHCK

Windows iperf3 for NetKVM functest throughput and RSS cases.

## Arch variants

| Config | Binary source | Version | Arch |
|---|---|---|---|
| `x64-config.json` | [ar51an/iperf3-win-builds 3.17.1](https://github.com/ar51an/iperf3-win-builds/releases/tag/3.17.1) | 3.17.1 | amd64 |
| `x86-config.json` | [files.budman.xyz](https://files.budman.xyz/iperf3.5_32.zip) | 3.5 | x86 |

> **Note:** No maintained x86 iperf3 Windows build is publicly available beyond 3.5.
> The x86 variant uses the last known x86 build from the community archive at files.budman.xyz.

## Layout

```
iperf/
  x64-config.json
  x86-config.json
  install.ps1
  iperf-win64.zip      # not in git — AutoHCK downloads on first use (x64)
  iperf-win32.zip      # not in git — AutoHCK downloads on first use (x86)
```

Guest install: `C:\iperf\iperf3.exe` on machine PATH (both arches).

`install.ps1` detects `PROCESSOR_ARCHITECTURE` at runtime and selects
`iperf-win64.zip` (x64) or `iperf-win32.zip` (x86) automatically.

Host setup: Linux `iperf3` is configured in AutoHCK test case `pre_test_commands`.

## Usage

```json
"extra_software": ["iperf"]
```
