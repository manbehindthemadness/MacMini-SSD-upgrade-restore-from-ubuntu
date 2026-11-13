#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/tool-env.sh"
if (( EUID != 0 )); then exec sudo -- "$KIT_ROOT/scripts/probe-mac.sh"; fi
"$KIT_ROOT/tools/bin/irecovery" --query
