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

Host Linux `ntttcp-for-linux` is built by `ensure_ntttcp_host.sh` into the run workspace cache.

## Usage

```json
"extra_software": ["ntttcp"]
```

Source: https://github.com/microsoft/ntttcp/releases/tag/v5.40
