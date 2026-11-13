#!/bin/bash
# Run only AFTER the new SSD is fitted and the Mac mini is in DFU mode.
set -euo pipefail
source "$(dirname "$0")/tool-env.sh"
if (( $# )); then echo 'Usage: restore-mac.sh'; exit 2; fi
umask 077
if (( EUID != 0 )); then exec sudo -- "$KIT_ROOT/scripts/restore-mac.sh" "$@"; fi
cd "$KIT_ROOT"
"$KIT_ROOT/scripts/verify-kit.sh"
info=$("$KIT_ROOT/tools/bin/irecovery" --query)
printf '\nConnected target:\n%s\n' "$info"
product=$(awk '/^PRODUCT: / {print $2}' <<< "$info")
mode=$(awk '/^MODE: / {sub(/^MODE: /, "");print}' <<< "$info")
ecid=$(awk '/^ECID: / {print $2}' <<< "$info")
if [[ "$product" != 'Mac16,10' || "$mode" != *DFU* || ! "$ecid" =~ ^0x[[:xdigit:]]+$ ]]; then
 echo 'Expected a Mac mini M4 (Mac16,10) in DFU/Port DFU. Stopping before restore.'
 exit 1
fi
printf '\nThis ERASES the connected Mac mini and installs macOS 27.0.1.\n'
printf 'Confirm the new SSD is installed and the Time Machine backup is complete.\n'
printf 'Type ERASE %s to continue: ' "$ecid"
read -r answer
[[ "$answer" == "ERASE $ecid" ]] || { echo 'Cancelled.'; exit 1; }
# Prevent the distribution daemon from competing for a reconnecting USB device.
was_active=0
made_mask=0
mux_pid=''
cleanup() {
 result=$?
 trap - EXIT
 if [[ -n "$mux_pid" ]]; then kill "$mux_pid" 2>/dev/null || true;wait "$mux_pid" 2>/dev/null || true;fi
 if (( made_mask )); then systemctl unmask --runtime usbmuxd.service || true;fi
 if (( was_active )); then systemctl start usbmuxd.service || true;fi
 if (( result )); then echo 'Restore did not complete; keep the logs and consult README.md.';fi
 exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if systemctl is-active --quiet usbmuxd.service; then was_active=1;fi
unit_state=$(systemctl is-enabled usbmuxd.service 2>/dev/null || true)
if [[ "$unit_state" != masked* ]]; then
 systemctl mask --runtime usbmuxd.service
 made_mask=1
fi
systemctl stop usbmuxd.service
if pgrep -x usbmuxd >/dev/null; then
 echo 'Another usbmuxd is still running. Stop it before trying again.';exit 1
fi
mkdir -p runtime/pairing cache logs
chmod 700 runtime/pairing
# Use a short UNIX socket path: Linux sockets have a 108-byte path limit.
export USBMUXD_SOCKET_ADDRESS='UNIX:/run/mac-mini-m4-recovery.sock'
"$KIT_ROOT/tools/sbin/usbmuxd" --foreground --user root \
 --socket /run/mac-mini-m4-recovery.sock --pidfile "$KIT_ROOT/runtime/usbmuxd.pid" \
 --config-dir "$KIT_ROOT/runtime/pairing" > "$KIT_ROOT/logs/usbmuxd-$(date +%Y%m%d-%H%M%S).log" 2>&1 &
mux_pid=$!
for (( i=0; i<50; i++ )); do
 if [[ -S /run/mac-mini-m4-recovery.sock ]]; then break;fi
 kill -0 "$mux_pid" 2>/dev/null || { echo 'usbmuxd failed to start; see logs.';exit 1; }
 sleep 0.1
done
[[ -S /run/mac-mini-m4-recovery.sock ]] || { echo 'usbmuxd socket did not appear.';exit 1; }
echo 'Keep both computers powered, the external drive mounted, and the USB cable connected.'
# Keep the laptop awake throughout the restore. Leave upstream erase prompts enabled.
systemd-inhibit --what=sleep:idle --mode=block --why='Restoring Mac mini firmware' \
 "$KIT_ROOT/tools/bin/idevicerestore" --erase --ecid "$ecid" \
 --cache-path "$KIT_ROOT/cache" --logfile "$KIT_ROOT/logs/restore-$(date +%Y%m%d-%H%M%S).log" \
 "$KIT_ROOT/firmware/UniversalMac_27.0.1_26A434_Restore.ipsw"
