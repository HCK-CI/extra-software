# ntttcp for AutoHCK

Windows NTttcp v5.40 (amd64) for NetKVM functest throughput cases.

## Layout

```
ntttcp/
  config.json
  install.ps1
  ntttcp.exe             # not in git — AutoHCK downloads on first use
```

Guest install: `C:\ntttcp\ntttcp.exe` on machine PATH.

Host setup: Linux `ntttcp-for-linux` is configured in AutoHCK test case pre_test_commands.

## Usage

```json
"extra_software": ["ntttcp"]
```

Source: https://github.com/microsoft/ntttcp/releases/tag/v5.40
