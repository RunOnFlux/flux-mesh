#!/bin/bash
# build.sh [OUT]
#
# Builds dist/flux-mesh_<VERSION>-1_amd64.deb: the pinned Nebula release binaries (sha256
# checked), Tayga built from its pinned commit, the mesh units and AppArmor profiles, and
# the licences. Also writes Tayga's source for that commit (its GPL obligation) and
# SHA256SUMS. Needs curl, git, make, gcc and dpkg-deb.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$here/dist}
version=$(cat "$here/VERSION")
# shellcheck source=pins.env
source "$here/pins.env"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
pkg=$work/pkg

tarball=nebula-linux-amd64.tar.gz
curl -fsSL -o "$work/$tarball" \
  "https://github.com/slackhq/nebula/releases/download/${NEBULA_VERSION}/${tarball}"
echo "${NEBULA_SHA256_AMD64}  $work/$tarball" | sha256sum --check --status
tar -xzf "$work/$tarball" -C "$work" nebula nebula-cert

git clone --quiet "$TAYGA_REPO" "$work/tayga"
git -C "$work/tayga" checkout --quiet "$TAYGA_COMMIT"
make -C "$work/tayga" --quiet tayga

install -D -m 0755 "$work/nebula" "$pkg/usr/bin/nebula"
install -D -m 0755 "$work/nebula-cert" "$pkg/usr/bin/nebula-cert"
install -D -m 0755 "$work/tayga/tayga" "$pkg/usr/bin/tayga"
install -D -m 0644 -t "$pkg/usr/lib/systemd/system" "$here"/systemd/*.service
install -D -m 0644 -t "$pkg/etc/apparmor.d" "$here"/apparmor/nebula "$here"/apparmor/tayga
install -D -m 0644 -t "$pkg/usr/share/doc/flux-mesh" "$here/LICENSE" "$here"/licenses/*
sed -e "s|@NEBULA_VERSION@|$NEBULA_VERSION|g" -e "s|@TAYGA_REPO@|$TAYGA_REPO|g" \
  -e "s|@TAYGA_COMMIT@|$TAYGA_COMMIT|g" "$here/debian/copyright" \
  > "$pkg/usr/share/doc/flux-mesh/copyright"

install -d "$pkg/DEBIAN"
sed "s|@VERSION@|$version|" "$here/debian/control" > "$pkg/DEBIAN/control"
install -m 0644 "$here/debian/conffiles" "$pkg/DEBIAN/conffiles"

mkdir -p "$out"
deb=flux-mesh_${version}-1_amd64.deb
dpkg-deb --root-owner-group --build "$pkg" "$out/$deb" >/dev/null
git -C "$work/tayga" archive --format=tar.gz --prefix="tayga-${TAYGA_COMMIT}/" \
  -o "$out/tayga-${TAYGA_COMMIT}.tar.gz" "$TAYGA_COMMIT"
(cd "$out" && sha256sum "$deb" "tayga-${TAYGA_COMMIT}.tar.gz" > SHA256SUMS && cat SHA256SUMS)
