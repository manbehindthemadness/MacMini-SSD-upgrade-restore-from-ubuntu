#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tool-env.sh"
cd "$KIT_ROOT"
printf 'Checking the Apple firmware checksum (reads about 26.6 GB)...\n'
(cd firmware && sha256sum --check SHA256SUMS)
printf '\nChecking Linux tools...\n'
for tool in tools/bin/idevicerestore tools/bin/irecovery tools/sbin/usbmuxd; do
 test -x "$tool"
 deps=$(ldd "$tool")
 if [[ "$deps" == *'not found'* ]]; then printf '%s\n' "$deps";exit 1;fi
 "$KIT_ROOT/$tool" --version
done
python3 - <<'CHECK'
import json, pathlib, plistlib, zipfile
root = pathlib.Path.cwd()
f = json.loads((root / 'firmware/selected.json').read_text())['firmware']
with zipfile.ZipFile(root / 'firmware' / f['url'].rsplit('/', 1)[1]) as archive:
    manifest = plistlib.loads(archive.read('BuildManifest.plist'))
if ('Mac16,10' not in manifest['SupportedProductTypes'] or
        manifest['ProductVersion'] != f['version'] or
        manifest['ProductBuildVersion'] != f['buildid']):
    raise SystemExit('IPSW manifest does not match the selected Mac model/version/build')
CHECK
printf '\nReading IPSW metadata without contacting or restoring a device...\n'
"$KIT_ROOT/tools/bin/idevicerestore" --ipsw-info "$KIT_ROOT/firmware/UniversalMac_27.0.1_26A434_Restore.ipsw"
printf '\nKit checks passed. This does not test a physical DFU restore.\n'
