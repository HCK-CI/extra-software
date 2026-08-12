# OpenSSH (Win32-OpenSSH, x86)

Win32-OpenSSH Server for native 32-bit Windows guests (e.g. Win10 x86) used by
AutoHCK functional tests (virtio-vsock SSH-over-vsock bridge).

## Source

- Upstream: [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- License: BSD (see `LICENSE.txt` / `NOTICE.txt` inside the downloaded zip)
- Artifact: `OpenSSH-Win32.zip` from the pinned GitHub release in `config.json`
- Binary is not committed; AutoHCK downloads it via `download_url`

## Usage

```json
"extra_software": ["openssh_x86"]
```

Use `openssh_x86` for native x86 platforms; use the `openssh` package for amd64.
