# flux-mesh

The runtime FluxOS's app mesh runs on an ArcaneOS node, as one Debian package:

| Path | What |
|---|---|
| `/usr/bin/nebula`, `/usr/bin/nebula-cert` | [Nebula](https://github.com/slackhq/nebula), the overlay: the upstream release binaries, sha256-pinned in `pins.env` |
| `/usr/bin/tayga` | [Tayga](https://github.com/apalrd/tayga), the IPv4 shim, built from the commit pinned in `pins.env` |
| `/usr/lib/systemd/system/flux-mesh@.service`, `flux-mesh-tayga@.service` | one instance of each per mesh app, in the app's network namespace |
| `/etc/apparmor.d/nebula`, `/etc/apparmor.d/tayga` | their confinement |

FluxOS creates each app's network namespace, writes its configuration under
`/dat/var/lib/flux-mesh/<app>/` and starts `flux-mesh@<app>`; nothing starts at boot. The
units run only while `/dat` is mounted (`Requisite=`, `After=` and `PartOf=dat.mount`).

The ArcaneOS image installs a release by version and sha256; FluxOS's integration harness
installs the same release in its containers.

## Build

`./build.sh` writes `dist/flux-mesh_<VERSION>-1_<arch>.deb` for the machine's architecture
(amd64 or arm64), `dist/tayga-<commit>.tar.gz` and `dist/SHA256SUMS`. It needs curl, git, make, gcc and dpkg-deb (Linux). A `v<VERSION>`
tag builds and publishes all three as a release.

## Licences

This repository: [Blue Oak Model License 1.0.0](LICENSE). Nebula: MIT
([licenses/nebula-MIT.txt](licenses/nebula-MIT.txt)). Tayga: GPL-2.0-or-later
([licenses/GPL-2.0.txt](licenses/GPL-2.0.txt)); every release carries the source of the
Tayga commit its deb was built from. The deb lists all three in
`/usr/share/doc/flux-mesh/copyright`.
