#!/bin/bash
# Fetch the upstream revisions and Ubuntu packages used by the tested kit.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
[[ $(dpkg --print-architecture) == amd64 ]] || { echo 'This build targets Ubuntu 24.04 amd64.'; exit 1; }
mkdir -p "$ROOT/sources" "$ROOT/packages"
while read -r repo revision; do
 directory="$ROOT/sources/$repo"
 if [[ ! -d "$directory/.git" ]]; then
  git init "$directory"
  git -C "$directory" remote add origin "https://github.com/libimobiledevice/$repo.git"
 fi
 if [[ -n $(git -C "$directory" status --porcelain) ]]; then
  echo "Local changes in $repo; refusing to overwrite them."; exit 1
 fi
 git -C "$directory" fetch --depth 1 origin "$revision"
 git -C "$directory" checkout --detach "$revision"
done < "$ROOT/docs/UPSTREAM-COMMITS.txt"
cd "$ROOT/packages"
packages=()
while read -r package version architecture; do
 packages+=("$package:$architecture=$version")
done < "$ROOT/docs/TESTED-PACKAGES.txt"
apt-get download "${packages[@]}"
echo 'Sources and dependency packages ready. Run ./scripts/build-tools.sh next.'
