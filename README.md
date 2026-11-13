# Mac mini M4 SSD upgrade restore from Ubuntu

Linux helpers for a DFU **erase restore** of a 2024 base M4 Mac mini
(`Mac16,10`) after replacing its SSD. A restore using the original kit
completed successfully from Ubuntu 24.04 x86_64 on October 31, 2026, with
macOS 27.0.1 (26A434). That result covers the firmware restore; subsequent
activation, backup migration, and final SSD capacity were not recorded as
verified. This is an independent project using libimobiledevice tools.

**Restoring erases the connected Mac's internal storage.** Make and verify a
Time Machine backup first, keep the original SSD, and have your Apple Account,
two-factor access, and any backup encryption password available privately.
The launcher accepts only `Mac16,10` in DFU mode and requires you to type
`ERASE` followed by its device identifier. M4 Pro (`Mac16,11`) is not supported
by this launcher. Have access to another Mac for Apple's documented restore
workflow if the Linux restore fails.

## Build on Ubuntu

Use Ubuntu 24.04 amd64 with Git, Python 3, a compiler, make, autoconf, automake,
libtool, pkg-config, and dpkg-deb. Install the build prerequisites if needed:

```sh
sudo apt-get update
sudo apt-get install git python3 build-essential autoconf automake libtool pkg-config
mkdir -p /usr/src/MacMini-SSD-upgrade-restore-from-ubuntu
git clone https://github.com/manbehindthemadness/MacMini-SSD-upgrade-restore-from-ubuntu.git /usr/src/MacMini-SSD-upgrade-restore-from-ubuntu
cd /usr/src/MacMini-SSD-upgrade-restore-from-ubuntu
./scripts/prepare-tools.sh
./scripts/build-tools.sh
python3 scripts/download-firmware.py
./scripts/verify-kit.sh
```

The destination parent must be writable by your user. Build without sudo.
`prepare-tools.sh` fetches the eight upstream revisions recorded in
[docs/UPSTREAM-COMMITS.txt](docs/UPSTREAM-COMMITS.txt) and downloads the Ubuntu
packages recorded in [docs/TESTED-PACKAGES.txt](docs/TESTED-PACKAGES.txt).
`build-tools.sh` extracts those packages locally and builds into `tools/`;
it does not install the restore tools over the system copies. Exact package
versions may eventually disappear from Ubuntu mirrors. If they are unavailable,
use a suitable Ubuntu archive or deliberately update and revalidate the package
list. Other architectures and distributions have not been validated.

The firmware download is about 26.6 GB. Allow at least another 60 GB of free
space for restore extraction and cache, and keep reliable internet available.
The downloader resumes HTTP ranges and verifies the full SHA-256 before
renaming the image. The verification script checks that the IPSW manifest
supports `Mac16,10` and matches the selected version and build.

The included firmware selection is the **historically tested image**. Its
metadata does not assert that Apple still signs it. Restore and activation
need Apple's servers even with a local IPSW. If that version is no longer
signed, select an appropriate signed Apple-hosted image, update
`firmware/selected.json`, `firmware/SHA256SUMS`, and the filename/version in
`restore-mac.sh` and `verify-kit.sh` together, then download and verify again.
Do not use an unsigned downgrade or third-party signing-server override.

## Replace the SSD and enter DFU

Follow the SSD manufacturer's instructions and the model-specific replacement
guide linked below. Shut down and unplug the Mac before opening it; finish
reassembly before restoring. Leave the Time Machine disk disconnected during
the firmware restore.

For the tested **2024 M4 mini**, the kit used the **middle of the three rear
USB-C/Thunderbolt ports**. Use a direct USB-C data-and-charging cable and avoid
hubs. The original preparation notes reported a discrepancy between Apple's
generic port wording and the vendor's M4-specific instructions; consult the
current model-specific guidance if unsure.

1. Unplug the Mac mini's power cable.
2. Connect the middle rear USB-C port to the Ubuntu host.
3. Hold the Mac mini's power button while reconnecting its power cable.
4. Continue holding for up to about 10 seconds, then release when DFU appears.
   The display remains blank in DFU.
5. Disconnect other Apple devices in DFU and query the target:

```sh
./scripts/probe-mac.sh
```

Expect `PRODUCT: Mac16,10`, an ECID, and a mode containing `DFU`. The probe
uses sudo for USB access and does not restore the device.

## Restore

After installing the new SSD, checking the backup, and confirming the target:

```sh
./scripts/restore-mac.sh
```

Keep both computers powered, the project drive mounted, and the cable connected.
The launcher verifies the image and tools, checks the model and mode, requests
explicit erase confirmation, temporarily stops/masks the system usbmuxd service,
and runs the local daemon and idevicerestore. It uses systemd-inhibit to keep
the host awake and restores the previous service state on normal exit or Ctrl+C.
The Mac may disconnect and reappear several times. Do not interrupt a restore.

After completion, use the Mac's display to finish activation and setup. Restore
accounts and files with Setup Assistant or Migration Assistant from Time Machine.
Unlock encrypted backups locally. Verify the new SSD capacity and important
files before retiring your backup or original SSD.

## Troubleshooting

- **No DFU device:** check the middle rear port, data cable, direct connection,
  power-button sequence, and `lsusb`. Trust irecovery's model/mode query.
- **Signing or TSS failure:** check internet, clock, and current signing
  eligibility. A matching checksum does not establish signing eligibility.
- **Daemon/socket conflict:** inspect `systemctl status usbmuxd.service` and
  `pgrep -a usbmuxd`. Another running daemon causes the launcher to stop.
- **Crash or SIGKILL:** a reboot clears the temporary runtime service mask and
  `/run` socket. If recovering manually, stop the kit daemon first and undo
  only masks created by this launcher; preserve pre-existing administrative masks.
- **Missing libraries after moving the folder:** rebuild the tools at the new
  path. The build embeds local library paths.
- **Linux restore fails repeatedly:** use Apple's Mac-host restore workflow.
  An ext4 project drive is not normally readable by macOS; let the Mac download
  firmware or transfer the image through a supported filesystem/network.

Keep logs locally for diagnosis. Sanitize them before sharing.

## Privacy and publication

This repository contains reviewed helper source, upstream revision/package
lists, public firmware metadata/checksum, and documentation. It excludes the
original logs, runtime/pairing directory, restore cache, IPSW, downloaded source
trees, binary tools, dependency packages, copied web pages, and saved images.
The original local recovery kit is preserved separately.

Restore logs can contain ECIDs, serial numbers, nonces, and personalization
responses. Pairing records can contain private keys and certificates. These
outputs are ignored by Git; **do not force-add them or upload raw diagnostic
bundles**. The launcher creates new restore output with restrictive permissions.
SHA-256 values here are public file-integrity checksums. Upstream software still
uses cryptography and Apple's signing protocols; no user encryption keys or
backup passwords are bundled.

The published helpers retain the repository's Apache-2.0 license. Dependencies
are fetched from upstream and retain their own licenses.

## References

- [Apple: revive or restore Mac firmware](https://support.apple.com/en-us/108900)
- [Apple: identify the DFU port](https://support.apple.com/en-us/120694)
- [Apple: migrate from Time Machine](https://support.apple.com/en-us/102551)
- [SSD vendor DIY guide](https://expandmacmini.com/pages/diy-guide)
- [iFixit: replace the SSD in a 2024 Mac mini](https://www.ifixit.com/Guide/How+to+Replace+the+SSD+in+your+Mac+mini+(2024)/180199)
- [libimobiledevice idevicerestore](https://github.com/libimobiledevice/idevicerestore)
- [Firmware catalog for Mac16,10](https://ipsw.me/Mac16,10)
