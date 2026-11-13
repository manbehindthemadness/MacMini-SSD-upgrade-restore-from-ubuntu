#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
PREFIX="$ROOT/tools"
SYSROOT="$ROOT/build-deps"
mkdir -p "$SYSROOT" "$PREFIX" "$ROOT/logs"
for deb in "$ROOT"/packages/*.deb; do dpkg-deb -x "$deb" "$SYSROOT"; done
# Redirect only the extracted development packages' pkg-config paths.
for pc in "$SYSROOT"/usr/lib/x86_64-linux-gnu/pkgconfig/*.pc; do
 sed -i "s|^prefix=/usr$|prefix=$SYSROOT/usr|; s|^libdir=/usr/|libdir=$SYSROOT/usr/|; s|^includedir=/usr/|includedir=$SYSROOT/usr/|" "$pc"
done
export PATH="$PREFIX/bin:$SYSROOT/usr/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$SYSROOT/usr/lib/x86_64-linux-gnu/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib:$SYSROOT/usr/lib/x86_64-linux-gnu"
export CPPFLAGS="-I$SYSROOT/usr/include -I$SYSROOT/usr/include/x86_64-linux-gnu"
export LDFLAGS="-L$PREFIX/lib -L$SYSROOT/usr/lib/x86_64-linux-gnu -Wl,-rpath,$PREFIX/lib -Wl,-rpath,$SYSROOT/usr/lib/x86_64-linux-gnu"
for repo in libplist libimobiledevice-glue libusbmuxd libtatsu libimobiledevice libirecovery usbmuxd idevicerestore; do
 echo "Building $repo"
 (
 cd "$ROOT/sources/$repo"
 args=(--prefix="$PREFIX" --disable-static)
 case "$repo" in
 libplist|libimobiledevice) args+=(--without-cython);;
 esac
 case "$repo" in
 libirecovery) args+=(--with-udevrulesdir="$PREFIX/share/udev/rules.d");;
 usbmuxd) args+=(--without-systemd --with-systemdsystemunitdir=no --with-udevrulesdir="$PREFIX/share/udev/rules.d");;
 esac
 ./autogen.sh "${args[@]}"
 make clean
 make -j4
 make install
 ) > "$ROOT/logs/build-$repo.log" 2>&1 || { tail -60 "$ROOT/logs/build-$repo.log"; exit 1; }
done
printf 'Built on %s\n' "$(date --iso-8601=seconds)" > "$ROOT/tools/BUILT.txt"
