# iperf3 for AutoHCK

Windows iperf3 v3.17.1 (amd64) for NetKVM functest throughput and RSS cases.

## Layout

```
iperf/
  config.json
  install.ps1
  iperf3-win.zip         # not in git — AutoHCK downloads on first use
```

Guest install: `C:\iperf\iperf3.exe` on machine PATH.

Host setup: Linux `iperf3` is configured in AutoHCK test case pre_test_commands.

## Usage

```json
"extra_software": ["iperf"]
```

Source: https://github.com/ar51an/iperf3-win-builds/releases/tag/3.17.1
