# vs_buildtools (Visual Studio 2022 Build Tools)

Used by AutoHCK when a test suite lists `vs_buildtools` in `extra_software`
(e.g. virtio-fs MSBuild-on-share functional tests).

## Why nothing large is in git

The VS Build Tools bootstrapper and especially an offline `--layout` payload are
too large (and Microsoft-redistributable) to commit. Same approach as
`NDIS65_ndprot683_fix`: **only the definition + install helper are in git**;
labs host the data on NFS / the local `extra_software` tree.

## Lab host setup (required)

On each AutoHCK machine, under the configured `extra_software` path:

```text
extra-software/vs_buildtools/
  config.json                 # from this repo
  install-vs-buildtools.ps1   # from this repo
  vs_BuildTools.exe           # place manually (not in git)
  layout/                     # optional but recommended offline layout
```

Obtain the bootstrapper once (any trusted mirror / Microsoft), copy it next to
`config.json`, then preferably create an offline layout so guest installs do
**not** depend on live Microsoft CDN links:

```bash
cd /path/to/extra-software/vs_buildtools
./vs_BuildTools.exe --layout "$PWD/layout" --lang en-US \
  --add Microsoft.VisualStudio.Workload.MSBuildTools \
  --add Microsoft.VisualStudio.Workload.VCTools \
  --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
  --add Microsoft.VisualStudio.Component.Windows11SDK.26100 \
  --includeRecommended
```

`download_url` is intentionally empty: AutoHCK skips download when
`vs_BuildTools.exe` is already present; if it is missing, setup fails loudly
instead of hitting an external URL.

Without `layout/`, the install helper may fall back to Microsoft CDN and needs
guest world networking (`--client_world_net`). Prefer keeping `layout/` on NFS.
