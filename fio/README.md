# fio for AutoHCK

Windows fio for VirtIO-FS functest cases (queue size, stress).

## Arch variants

| Config | Binary source | Version | Arch |
|---|---|---|---|
| `x64-config.json` | [axboe/fio fio-3.42](https://github.com/axboe/fio/releases/tag/fio-3.42) | 3.42 | amd64 |
| `x86-config.json` | [axboe/fio fio-3.42](https://github.com/axboe/fio/releases/tag/fio-3.42) | 3.42 | x86 |

## Layout

```
fio/
  x64-config.json
  x86-config.json
  install.ps1
  fio-3.42-x64.msi     # not in git — AutoHCK downloads on first use (x64)
  fio-3.42-x86.msi     # not in git — AutoHCK downloads on first use (x86)
```

Guest install: `C:\Program Files\fio\fio.exe` (MSI adds it to the machine PATH).

AutoHCK picks `x64-config.json` or `x86-config.json` per guest arch.
`install.ps1` detects the OS architecture at runtime and skips msiexec on
arch mismatch (x64 MSI on 32-bit Windows, x86 MSI on 64-bit Windows).

## Usage

```json
"extra_software": ["fio"]
```
