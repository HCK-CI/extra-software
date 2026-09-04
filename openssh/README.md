# OpenSSH (Win32-OpenSSH, amd64)

Win32-OpenSSH Server for 64-bit Windows guests used by AutoHCK functional tests
(e.g. virtio-vsock SSH-over-vsock bridge).

## Source

- Upstream: [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- License: BSD (see `LICENSE.txt` / `NOTICE.txt` inside the downloaded zip)
- Artifact: `OpenSSH-Win64.zip` from the pinned GitHub release in `config.json`
- Binary is not committed; AutoHCK downloads it via `download_url`

## Usage

```json
"extra_software": ["openssh"]
```

`install.ps1` extracts the bundled zip under `C:\Program Files\OpenSSH-Win64`,
registers the `sshd` service, enables pubkey auth, opens TCP/22, and starts sshd.
